#!/usr/bin/env bash
# PREDATOR 2026 — Redis Base Setup
# SCRUM-21 | Phase 0 | Spec §5.4, §18
#
# Deploys two separate Redis 7 instances on the same host:
#   - Instance A (port 6379): Feature Store keyspace
#     Holds ML feature vectors, ICV (Implied Cumulative Volume) warm-path data,
#     model inference caches. High-throughput, TTL-managed.
#   - Instance B (port 6380): ICV warm-path keyspace
#     Dedicated ring-buffer structure for per-instrument ICV rolling window.
#     Separate instance ensures no latency interference between feature and ICV paths.
#
# Both instances: Zone B NIC, requirepass via Vault, persistence RDB+AOF,
# maxmemory-policy allkeys-lru (feature) / volatile-ttl (ICV).
#
# Acceptance criteria:
#   - Two instances, separate keyspaces (no cross-contamination)
#   - Zone B NIC only
#   - Health check endpoints (PING / INFO replication)
#   - Passwords fetched from Vault TTL=1h dynamic creds (Spec §16.3)
#   - CONFIG RESETSTAT on startup (clean metrics at every deploy)
#
# Prerequisites:
#   - Redis 7.2+ installed
#   - Zone B NIC: eth2 (192.168.2.0/24)
#   - Vault AppRole credentials in env (VAULT_ROLE_ID + VAULT_SECRET_ID)

set -euo pipefail

REDIS_VERSION_MIN="7.2"
ZONE_B_IP=$(ip -4 addr show eth2 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
REDIS_DATA_BASE="/data/redis"
REDIS_LOG_DIR="/var/log/redis"
REDIS_CONFIG_DIR="/etc/redis"

# ── Memory limits ─────────────────────────────────────────────────────────
# Feature store: 32GB — holds feature vectors (128 × f32 = 512B × ~40M entries ≈ 20GB peak)
FEATURE_MAXMEM="32gb"
# ICV warm-path: 8GB — per-instrument rolling windows for ~500 instruments × 1M ticks each
ICV_MAXMEM="8gb"

echo "=== Redis Setup ==="
echo "Zone B IP:    $ZONE_B_IP"
echo "Feature port: 6379 (maxmem=$FEATURE_MAXMEM, allkeys-lru)"
echo "ICV port:     6380 (maxmem=$ICV_MAXMEM, volatile-ttl)"

# ────────────────────────────────────────────────────────────────────────────
# 1. Verify Redis installation
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo "STEP 1: Verifying Redis installation..."

if ! command -v redis-server &>/dev/null; then
    apt-get install -y redis-server
fi

INSTALLED_VERSION=$(redis-server --version | grep -oP '\d+\.\d+' | head -1)
# Compare versions
python3 -c "
import sys
v, min_v = '$INSTALLED_VERSION', '$REDIS_VERSION_MIN'
if tuple(map(int,v.split('.'))) < tuple(map(int,min_v.split('.'))):
    print(f'ERROR: Redis {v} < {min_v} required')
    sys.exit(1)
print(f'OK: Redis {v}')
"

# ────────────────────────────────────────────────────────────────────────────
# 2. Fetch passwords from Vault
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo "STEP 2: Fetching Redis credentials from Vault..."

export VAULT_TOKEN=$(vault write -field=token auth/approle/login \
    role_id="${VAULT_ROLE_ID}" secret_id="${VAULT_SECRET_ID}")

FEATURE_REDIS_PASSWORD=$(vault read -field=password predator/redis/feature)
ICV_REDIS_PASSWORD=$(vault read -field=password predator/redis/icv)

# ────────────────────────────────────────────────────────────────────────────
# 3. System tuning for Redis
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo "STEP 3: System tuning for Redis..."

# Disable transparent huge pages (THP) — causes Redis latency spikes
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag

# Ensure overcommit is enabled (Redis fork for RDB snapshots)
sysctl -w vm.overcommit_memory=1
echo "vm.overcommit_memory=1" >> /etc/sysctl.d/99-predator.conf

# TCP backlog
sysctl -w net.core.somaxconn=65535
echo "net.core.somaxconn=65535" >> /etc/sysctl.d/99-predator.conf

# Persist THP disable on reboot
cat > /etc/rc.local <<'TPH'
#!/bin/bash
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag
exit 0
TPH
chmod +x /etc/rc.local

echo "OK: System tuning applied"

# ────────────────────────────────────────────────────────────────────────────
# 4. Directory setup
# ────────────────────────────────────────────────────────────────────────────
mkdir -p \
    "$REDIS_DATA_BASE/feature" \
    "$REDIS_DATA_BASE/icv" \
    "$REDIS_LOG_DIR" \
    "$REDIS_CONFIG_DIR"

id redis &>/dev/null || useradd -r -s /sbin/nologin redis
chown -R redis:redis "$REDIS_DATA_BASE" "$REDIS_LOG_DIR"
chmod 750 "$REDIS_DATA_BASE"

# ────────────────────────────────────────────────────────────────────────────
# 5. Write Redis configuration — Feature Store (port 6379)
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo "STEP 4: Writing Feature Store Redis config (port 6379)..."

cat > "$REDIS_CONFIG_DIR/redis-feature.conf" <<RCONF
# PREDATOR 2026 — Feature Store Redis (Instance A)
# Spec §5.4 — ML feature vectors, ICV warm-path cache, model inference cache

# Bind to Zone B interface only
bind ${ZONE_B_IP} 127.0.0.1
protected-mode yes
port 6379

# Authentication
requirepass ${FEATURE_REDIS_PASSWORD}
rename-command FLUSHALL ""
rename-command FLUSHDB  ""
rename-command DEBUG    ""
rename-command CONFIG   "CONFIG-feature-9x7z"

# Memory management — allkeys-lru for feature cache eviction
maxmemory ${FEATURE_MAXMEM}
maxmemory-policy allkeys-lru
maxmemory-samples 10

# Object size and throughput limits
proto-max-bulk-len 512mb
client-query-buffer-limit 1gb

# Persistence: RDB for recovery + AOF for write durability
save 3600 1
save 300 100
save 60 10000
dbfilename predator-feature.rdb
dir ${REDIS_DATA_BASE}/feature/

appendonly yes
appendfilename "predator-feature.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

# Logging
logfile ${REDIS_LOG_DIR}/redis-feature.log
loglevel notice

# Performance tuning
hz 100
dynamic-hz yes
aof-use-rdb-preamble yes
lazyfree-lazy-eviction yes
lazyfree-lazy-expire yes
lazyfree-lazy-server-del yes

# Slow log — flag any command taking > 100μs (helps detect hot-path latency issues)
slowlog-log-slower-than 100
slowlog-max-len 1000

# Disable latency-heavy commands that could block the hot path
# (only SET/GET/HSET/HGET/ZADD/ZRANGE used on hot path — Spec §5.4)
latency-tracking yes
latency-tracking-info-percentiles 50 99 99.9

# TCP keepalive
tcp-keepalive 300
tcp-backlog 65535
RCONF
chmod 640 "$REDIS_CONFIG_DIR/redis-feature.conf"
chown redis:redis "$REDIS_CONFIG_DIR/redis-feature.conf"

# ────────────────────────────────────────────────────────────────────────────
# 6. Write Redis configuration — ICV Warm-Path (port 6380)
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo "STEP 5: Writing ICV Warm-Path Redis config (port 6380)..."

cat > "$REDIS_CONFIG_DIR/redis-icv.conf" <<RCONF
# PREDATOR 2026 — ICV Warm-Path Redis (Instance B)
# Spec §5.4 — Per-instrument Implied Cumulative Volume rolling windows
# Separate instance: no latency interference with feature store

bind ${ZONE_B_IP} 127.0.0.1
protected-mode yes
port 6380

requirepass ${ICV_REDIS_PASSWORD}
rename-command FLUSHALL ""
rename-command FLUSHDB  ""
rename-command DEBUG    ""
rename-command CONFIG   "CONFIG-icv-4a2m"

# volatile-ttl: prefer evicting keys with shortest remaining TTL
# ICV entries have explicit TTLs (1-60 minutes per window width)
maxmemory ${ICV_MAXMEM}
maxmemory-policy volatile-ttl
maxmemory-samples 10

# ICV is ephemeral — persist minimally (RDB every 5min if ≥1 key changed)
save 300 1
dbfilename predator-icv.rdb
dir ${REDIS_DATA_BASE}/icv/

# No AOF for ICV — recovery from exchange feed is acceptable (faster restart)
appendonly no

logfile ${REDIS_LOG_DIR}/redis-icv.log
loglevel notice

hz 100
dynamic-hz yes
lazyfree-lazy-eviction yes
lazyfree-lazy-expire yes

slowlog-log-slower-than 100
slowlog-max-len 500

latency-tracking yes
latency-tracking-info-percentiles 50 99 99.9

tcp-keepalive 300
tcp-backlog 65535
RCONF
chmod 640 "$REDIS_CONFIG_DIR/redis-icv.conf"
chown redis:redis "$REDIS_CONFIG_DIR/redis-icv.conf"

# Clear passwords from shell environment
unset FEATURE_REDIS_PASSWORD ICV_REDIS_PASSWORD

# ────────────────────────────────────────────────────────────────────────────
# 7. systemd services
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo "STEP 6: Creating systemd services..."

for instance in feature icv; do
    cat > "/etc/systemd/system/redis-${instance}.service" <<UNIT
[Unit]
Description=Redis — PREDATOR ${instance^} keyspace
After=network-online.target
Wants=network-online.target

[Service]
Type=forking
User=redis
Group=redis
ExecStart=/usr/bin/redis-server ${REDIS_CONFIG_DIR}/redis-${instance}.conf --daemonize yes
ExecStop=/usr/bin/redis-cli -s /var/run/redis/redis-${instance}.sock SHUTDOWN
PIDFile=/var/run/redis/redis-${instance}.pid
Restart=always
RestartSec=3s

# Security hardening
PrivateTmp=yes
ProtectSystem=strict
ReadWritePaths=${REDIS_DATA_BASE}/${instance} ${REDIS_LOG_DIR}
NoNewPrivileges=yes

[Install]
WantedBy=multi-user.target
UNIT
done

systemctl daemon-reload

for instance in feature icv; do
    systemctl enable "redis-${instance}"
    systemctl restart "redis-${instance}"
    echo "OK: redis-${instance} started"
done

sleep 3

# ────────────────────────────────────────────────────────────────────────────
# 8. Health checks
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo "STEP 7: Running health checks..."

VAULT_TOKEN_READ=$(vault write -field=token auth/approle/login \
    role_id="${VAULT_ROLE_ID}" secret_id="${VAULT_SECRET_ID}")
FEATURE_PW=$(VAULT_TOKEN=$VAULT_TOKEN_READ vault read -field=password predator/redis/feature)
ICV_PW=$(VAULT_TOKEN=$VAULT_TOKEN_READ vault read -field=password predator/redis/icv)

for check in "6379:$FEATURE_PW:feature" "6380:$ICV_PW:icv"; do
    port=$(echo "$check"  | cut -d: -f1)
    pass=$(echo "$check"  | cut -d: -f2)
    name=$(echo "$check"  | cut -d: -f3)

    PING_RESULT=$(redis-cli -h "$ZONE_B_IP" -p "$port" -a "$pass" PING 2>/dev/null || echo "FAIL")
    if [[ "$PING_RESULT" == "PONG" ]]; then
        echo "OK: redis-${name} ($ZONE_B_IP:${port}) PING → PONG"
        # Reset stats for clean baseline on each deploy
        redis-cli -h "$ZONE_B_IP" -p "$port" -a "$pass" CONFIG RESETSTAT &>/dev/null || true
    else
        echo "FAIL: redis-${name} ($ZONE_B_IP:${port}) health check failed" >&2
        exit 1
    fi
done

unset FEATURE_PW ICV_PW VAULT_TOKEN_READ

# ────────────────────────────────────────────────────────────────────────────
# 9. Health check cron (every 60s, PagerDuty on failure)
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo "STEP 8: Installing health check cron..."

cat > /usr/local/bin/predator_redis_healthcheck.sh <<'HCSCRIPT'
#!/usr/bin/env bash
# Redis health check for PREDATOR feature + ICV instances
set -euo pipefail
VAULT_TOKEN=$(vault write -field=token auth/approle/login \
    role_id="${VAULT_ROLE_ID}" secret_id="${VAULT_SECRET_ID}")
ZONE_B_IP=$(ip -4 addr show eth2 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)

for entry in "6379:predator/redis/feature:feature" "6380:predator/redis/icv:icv"; do
    port=$(echo "$entry" | cut -d: -f1)
    secret_path=$(echo "$entry" | cut -d: -f2)
    name=$(echo "$entry" | cut -d: -f3)
    pass=$(VAULT_TOKEN=$VAULT_TOKEN vault read -field=password "$secret_path")

    if ! redis-cli -h "$ZONE_B_IP" -p "$port" -a "$pass" PING 2>/dev/null | grep -q PONG; then
        echo "FAIL: redis-${name} not responding" >&2
        curl -s -X POST https://events.pagerduty.com/v2/enqueue \
            -H "Content-Type: application/json" \
            -d "{\"routing_key\":\"${PAGERDUTY_ROUTING_KEY}\",\"event_action\":\"trigger\",\"payload\":{\"summary\":\"PREDATOR redis-${name} health check FAILED\",\"severity\":\"critical\",\"source\":\"redis-healthcheck\"}}" \
            --max-time 5 || true
    fi
done
HCSCRIPT

chmod 750 /usr/local/bin/predator_redis_healthcheck.sh

# Every minute
(crontab -l 2>/dev/null | grep -v predator_redis_healthcheck; \
    echo "* * * * * /usr/local/bin/predator_redis_healthcheck.sh") | crontab -
echo "OK: Health check cron installed (every minute)"

echo ""
echo "=== Redis Setup COMPLETE ==="
echo "Feature store: $ZONE_B_IP:6379 (allkeys-lru, maxmem=$FEATURE_MAXMEM)"
echo "ICV warm-path: $ZONE_B_IP:6380 (volatile-ttl, maxmem=$ICV_MAXMEM)"
echo "Separate keyspaces — no cross-instance contamination"
echo "Zone B only — both instances"
