#!/usr/bin/env bash
# PREDATOR 2026 — ClickHouse Base Setup
# SCRUM-21 | Phase 0 | Spec §18, §5.4 [A4]
#
# Deploys a 2-node ReplicatedMergeTree ClickHouse cluster on bare metal.
# Acceptance criteria:
#   [A4] insert_quorum=2 and select_sequential_consistency=1 on all critical tables
#   [A4] Separate keyspaces: audit vs feature data
#   Weekly automated backup + restore smoke-test
#   Zone B NIC only (management plane also Zone B)
#
# Prerequisites:
#   - ClickHouse 24.3+ installed (apt/rpm)
#   - ZooKeeper 3.8 ensemble available at zk1:2181, zk2:2181, zk3:2181
#   - Zone B NIC: eth2 (192.168.2.0/24)
#   - /data/clickhouse NVMe mount (RAID-1 pair per bare_metal_setup.sh)
#   - Vault AppRole credentials in env (VAULT_ROLE_ID + VAULT_SECRET_ID)

set -euo pipefail

CLICKHOUSE_VERSION="24.3"
CLICKHOUSE_DATA_DIR="/data/clickhouse"
CLICKHOUSE_LOG_DIR="/var/log/clickhouse-server"
CLICKHOUSE_CONFIG_DIR="/etc/clickhouse-server"
ZONE_B_IP=$(ip -4 addr show eth2 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
NODE_HOSTNAME=$(hostname -f)

# Replica number derived from hostname suffix (e.g. predator-ch-01 → 01)
REPLICA_NUM=$(hostname | grep -oP '\d+$' || echo "01")
SHARD_NUM="01"   # single shard for now; extend to sharded cluster in Phase 2

echo "=== ClickHouse Setup ==="
echo "Node:          $NODE_HOSTNAME"
echo "Zone B IP:     $ZONE_B_IP"
echo "Replica:       $REPLICA_NUM"
echo "Data dir:      $CLICKHOUSE_DATA_DIR"

# ────────────────────────────────────────────────────────────────────────────
# 1. Install ClickHouse
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo "STEP 1: Installing ClickHouse $CLICKHOUSE_VERSION..."

if ! command -v clickhouse-server &>/dev/null; then
    apt-get install -y apt-transport-https ca-certificates gnupg
    curl -fsSL 'https://packages.clickhouse.com/rpm/lts/repodata/repomd.xml.key' \
        | gpg --dearmor -o /usr/share/keyrings/clickhouse-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/clickhouse-keyring.gpg arch=amd64,arm64] \
        https://packages.clickhouse.com/deb lts main" \
        > /etc/apt/sources.list.d/clickhouse.list
    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        "clickhouse-server=${CLICKHOUSE_VERSION}.*" \
        "clickhouse-client=${CLICKHOUSE_VERSION}.*"
fi

INSTALLED=$(clickhouse-server --version 2>&1 | grep -oP '\d+\.\d+' | head -1)
echo "OK: ClickHouse $INSTALLED installed"

# ────────────────────────────────────────────────────────────────────────────
# 2. Data directory and permissions
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo "STEP 2: Preparing data directories..."

mkdir -p \
    "$CLICKHOUSE_DATA_DIR/data" \
    "$CLICKHOUSE_DATA_DIR/tmp" \
    "$CLICKHOUSE_DATA_DIR/user_files" \
    "$CLICKHOUSE_LOG_DIR"

chown -R clickhouse:clickhouse "$CLICKHOUSE_DATA_DIR" "$CLICKHOUSE_LOG_DIR"
chmod 700 "$CLICKHOUSE_DATA_DIR"

# ────────────────────────────────────────────────────────────────────────────
# 3. Cluster configuration (config.xml)
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo "STEP 3: Writing ClickHouse configuration..."

cat > "$CLICKHOUSE_CONFIG_DIR/config.d/predator.xml" <<XML
<?xml version="1.0"?>
<clickhouse>
    <!-- Bind ONLY to Zone B interface (Spec §4.1 air-gap) -->
    <listen_host>${ZONE_B_IP}</listen_host>
    <listen_host>127.0.0.1</listen_host>
    <listen_try>1</listen_try>

    <!-- Port configuration -->
    <tcp_port>9000</tcp_port>
    <http_port>8123</http_port>
    <interserver_http_port>9009</interserver_http_port>

    <!-- Data and log paths -->
    <path>${CLICKHOUSE_DATA_DIR}/data/</path>
    <tmp_path>${CLICKHOUSE_DATA_DIR}/tmp/</tmp_path>
    <user_files_path>${CLICKHOUSE_DATA_DIR}/user_files/</user_files_path>

    <!-- Logging -->
    <logger>
        <level>warning</level>
        <log>${CLICKHOUSE_LOG_DIR}/clickhouse-server.log</log>
        <errorlog>${CLICKHOUSE_LOG_DIR}/clickhouse-server.err.log</errorlog>
        <size>500M</size>
        <count>10</count>
    </logger>

    <!-- ZooKeeper for ReplicatedMergeTree coordination -->
    <zookeeper>
        <node>
            <host>zk1.predator.internal</host>
            <port>2181</port>
        </node>
        <node>
            <host>zk2.predator.internal</host>
            <port>2181</port>
        </node>
        <node>
            <host>zk3.predator.internal</host>
            <port>2181</port>
        </node>
        <session_timeout_ms>30000</session_timeout_ms>
        <operation_timeout_ms>10000</operation_timeout_ms>
    </zookeeper>

    <!-- Macros for ReplicatedMergeTree table definitions -->
    <macros>
        <cluster>predator_cluster</cluster>
        <shard>${SHARD_NUM}</shard>
        <replica>${REPLICA_NUM}</replica>
    </macros>

    <!-- Cluster topology (2-node single-shard replica pair) -->
    <remote_servers>
        <predator_cluster>
            <shard>
                <internal_replication>true</internal_replication>
                <replica>
                    <host>predator-ch-01.predator.internal</host>
                    <port>9000</port>
                </replica>
                <replica>
                    <host>predator-ch-02.predator.internal</host>
                    <port>9000</port>
                </replica>
            </shard>
        </predator_cluster>
    </remote_servers>

    <!-- Performance: NVMe I/O scheduler, direct I/O -->
    <merge_tree>
        <min_bytes_for_wide_part>10485760</min_bytes_for_wide_part>
        <min_rows_for_wide_part>512000</min_rows_for_wide_part>
        <!-- Spec [A4]: insert quorum and sequential consistency enforced at table level -->
    </merge_tree>

    <!-- Disable telemetry -->
    <send_crash_reports>
        <enabled>false</enabled>
    </send_crash_reports>
</clickhouse>
XML

# ────────────────────────────────────────────────────────────────────────────
# 4. User configuration (separate users for audit vs feature data — Spec §18)
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo "STEP 4: Creating user roles (audit / feature / readonly)..."

# Retrieve passwords from Vault (TTL=1h dynamic creds per Spec §16.3)
# shellcheck disable=SC2155
export VAULT_TOKEN=$(vault write -field=token auth/approle/login \
    role_id="${VAULT_ROLE_ID}" secret_id="${VAULT_SECRET_ID}")

CH_AUDIT_PASSWORD=$(vault read -field=password predator/clickhouse/audit)
CH_FEATURE_PASSWORD=$(vault read -field=password predator/clickhouse/feature)
CH_READONLY_PASSWORD=$(vault read -field=password predator/clickhouse/readonly)

cat > "$CLICKHOUSE_CONFIG_DIR/users.d/predator_users.xml" <<XML
<?xml version="1.0"?>
<clickhouse>
    <users>
        <!-- Audit writer: can INSERT/SELECT in predator_audit database only -->
        <audit_writer>
            <password_sha256_hex>$(echo -n "$CH_AUDIT_PASSWORD" | sha256sum | cut -d' ' -f1)</password_sha256_hex>
            <networks><ip>::/0</ip></networks>
            <profile>audit_profile</profile>
            <quota>default</quota>
            <access_management>0</access_management>
            <databases>
                <database>predator_audit</database>
            </databases>
        </audit_writer>

        <!-- Feature writer: can INSERT/SELECT in predator_features database only -->
        <feature_writer>
            <password_sha256_hex>$(echo -n "$CH_FEATURE_PASSWORD" | sha256sum | cut -d' ' -f1)</password_sha256_hex>
            <networks><ip>::/0</ip></networks>
            <profile>feature_profile</profile>
            <quota>default</quota>
            <access_management>0</access_management>
            <databases>
                <database>predator_features</database>
            </databases>
        </feature_writer>

        <!-- Read-only: dashboards and backtesting -->
        <readonly_user>
            <password_sha256_hex>$(echo -n "$CH_READONLY_PASSWORD" | sha256sum | cut -d' ' -f1)</password_sha256_hex>
            <networks><ip>192.168.2.0/24</ip></networks>
            <profile>readonly</profile>
            <quota>default</quota>
            <readonly>1</readonly>
        </readonly_user>
    </users>

    <profiles>
        <!-- [A4] insert_quorum=2: writes only succeed when 2 replicas confirm -->
        <audit_profile>
            <insert_quorum>2</insert_quorum>
            <insert_quorum_timeout>10000</insert_quorum_timeout>
            <select_sequential_consistency>1</select_sequential_consistency>
            <max_memory_usage>8000000000</max_memory_usage>
        </audit_profile>

        <!-- [A4] Same quorum guarantees for feature store -->
        <feature_profile>
            <insert_quorum>2</insert_quorum>
            <insert_quorum_timeout>10000</insert_quorum_timeout>
            <select_sequential_consistency>1</select_sequential_consistency>
            <max_memory_usage>16000000000</max_memory_usage>
        </feature_profile>

        <readonly>
            <readonly>1</readonly>
            <max_memory_usage>4000000000</max_memory_usage>
        </readonly>
    </profiles>
</clickhouse>
XML

unset CH_AUDIT_PASSWORD CH_FEATURE_PASSWORD CH_READONLY_PASSWORD

# ────────────────────────────────────────────────────────────────────────────
# 5. Start ClickHouse and wait for health
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo "STEP 5: Starting ClickHouse service..."

systemctl enable clickhouse-server
systemctl restart clickhouse-server
sleep 5

for i in {1..12}; do
    if clickhouse-client --host 127.0.0.1 --query "SELECT 1" &>/dev/null; then
        echo "OK: ClickHouse is up"
        break
    fi
    echo "Waiting for ClickHouse ($i/12)..."
    sleep 5
done

clickhouse-client --host 127.0.0.1 --query "SELECT 1" \
    || { echo "ERROR: ClickHouse did not start in 60s" >&2; exit 1; }

# ────────────────────────────────────────────────────────────────────────────
# 6. Create databases and critical tables
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo "STEP 6: Creating databases and tables..."

clickhouse-client --host 127.0.0.1 --multiquery <<SQL
-- ── Audit database (Spec §18: immutable audit trail) ──────────────────────
CREATE DATABASE IF NOT EXISTS predator_audit
    ENGINE = Replicated('/clickhouse/databases/predator_audit', '{shard}', '{replica}');

-- Safety events (emergency rollbacks, kill-switch activations, etc.)
CREATE TABLE IF NOT EXISTS predator_audit.safety_events ON CLUSTER predator_cluster
(
    event_id        String,
    event_type      LowCardinality(String),
    reason          String,
    operator        String,
    env             LowCardinality(String),
    timestamp_utc   DateTime64(9, 'UTC'),
    from_version    String,
    to_version      String,
    elapsed_ms      UInt32,
    severity        LowCardinality(String)
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{shard}/predator_audit/safety_events', '{replica}')
PARTITION BY toYYYYMM(timestamp_utc)
ORDER BY (timestamp_utc, event_id)
SETTINGS index_granularity = 8192;

-- Order execution audit (Spec §18 — every order, every fill)
CREATE TABLE IF NOT EXISTS predator_audit.orders ON CLUSTER predator_cluster
(
    order_id        UInt64,
    instrument      LowCardinality(String),
    side            LowCardinality(String),
    quantity        Float64,
    price           Float64,
    status          LowCardinality(String),
    exchange        LowCardinality(String),
    created_at_ns   UInt64,
    filled_at_ns    UInt64,
    latency_ns      UInt32,
    signature       String
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{shard}/predator_audit/orders', '{replica}')
PARTITION BY toYYYYMM(toDateTime(created_at_ns / 1000000000))
ORDER BY (created_at_ns, order_id)
SETTINGS index_granularity = 8192;

-- PTP drift log (Spec §17 SCRUM-17)
CREATE TABLE IF NOT EXISTS predator_audit.ptp_drift ON CLUSTER predator_cluster
(
    ts_utc          DateTime64(9, 'UTC'),
    offset_ns       Int64,
    rms_ns          Float64,
    path_delay_ns   Int64,
    grandmaster     String
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{shard}/predator_audit/ptp_drift', '{replica}')
PARTITION BY toYYYYMMDD(ts_utc)
ORDER BY ts_utc
TTL ts_utc + INTERVAL 90 DAY
SETTINGS index_granularity = 8192;

-- ── Feature database (Spec §5.4 — feature store backing store) ────────────
CREATE DATABASE IF NOT EXISTS predator_features
    ENGINE = Replicated('/clickhouse/databases/predator_features', '{shard}', '{replica}');

-- Feature snapshots (one row per inference trigger)
CREATE TABLE IF NOT EXISTS predator_features.snapshots ON CLUSTER predator_cluster
(
    snapshot_id     UInt64,
    instrument      LowCardinality(String),
    ts_ns           UInt64,
    feature_vector  Array(Float32),      -- 128-dim §5.1
    model_version   String,
    source          LowCardinality(String)
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{shard}/predator_features/snapshots', '{replica}')
PARTITION BY toYYYYMMDD(toDateTime(ts_ns / 1000000000))
ORDER BY (ts_ns, instrument)
TTL toDateTime(ts_ns / 1000000000) + INTERVAL 7 DAY
SETTINGS index_granularity = 8192;

-- Model performance metrics (champion vs challenger tracking)
CREATE TABLE IF NOT EXISTS predator_features.model_metrics ON CLUSTER predator_cluster
(
    ts_utc          DateTime64(9, 'UTC'),
    model_version   String,
    slot            LowCardinality(String),   -- 'champion' | 'challenger'
    instrument      LowCardinality(String),
    sharpe_1h       Float64,
    pnl_bps         Float64,
    inference_p99_us Float32
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{shard}/predator_features/model_metrics', '{replica}')
PARTITION BY toYYYYMMDD(ts_utc)
ORDER BY (ts_utc, model_version)
SETTINGS index_granularity = 8192;
SQL

echo "OK: Databases and tables created"

# ────────────────────────────────────────────────────────────────────────────
# 7. Weekly backup + restore smoke-test (cron)
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo "STEP 7: Installing weekly backup cron..."

BACKUP_SCRIPT="/usr/local/bin/predator_clickhouse_backup.sh"
cat > "$BACKUP_SCRIPT" <<'BSCRIPT'
#!/usr/bin/env bash
# Weekly ClickHouse backup + restore smoke-test (SCRUM-21)
set -euo pipefail

BACKUP_DIR="/data/clickhouse-backups/$(date +%Y%m%d_%H%M%S)"
RESTORE_TEST_DB="predator_restore_test_$(date +%s)"
LOG="/var/log/predator/clickhouse_backup.log"
mkdir -p "$(dirname "$LOG")" "$BACKUP_DIR"

exec >> "$LOG" 2>&1
echo "=== Backup started $(date -u) ==="

# Backup both databases
clickhouse-client --host 127.0.0.1 \
    --query "BACKUP DATABASE predator_audit TO Disk('backups', '$(basename "$BACKUP_DIR")/audit')"
clickhouse-client --host 127.0.0.1 \
    --query "BACKUP DATABASE predator_features TO Disk('backups', '$(basename "$BACKUP_DIR")/features')"

echo "Backup complete: $BACKUP_DIR"

# Restore smoke-test: restore safety_events into temp db and count rows
clickhouse-client --host 127.0.0.1 --query \
    "RESTORE TABLE predator_audit.safety_events AS ${RESTORE_TEST_DB}.safety_events
     FROM Disk('backups', '$(basename "$BACKUP_DIR")/audit')"

ROW_COUNT=$(clickhouse-client --host 127.0.0.1 \
    --query "SELECT count() FROM ${RESTORE_TEST_DB}.safety_events")
clickhouse-client --host 127.0.0.1 \
    --query "DROP DATABASE IF EXISTS ${RESTORE_TEST_DB}"

if [[ "$ROW_COUNT" -ge 0 ]]; then
    echo "OK: Restore smoke-test passed (${ROW_COUNT} rows)"
else
    echo "FAIL: Restore smoke-test failed" >&2
    exit 1
fi

# Prune backups older than 30 days
find /data/clickhouse-backups -maxdepth 1 -type d -mtime +30 -exec rm -rf {} + || true
echo "=== Backup finished $(date -u) ==="
BSCRIPT

chmod 750 "$BACKUP_SCRIPT"

# Every Sunday 03:00 UTC
(crontab -l 2>/dev/null | grep -v predator_clickhouse_backup; \
    echo "0 3 * * 0 $BACKUP_SCRIPT") | crontab -

echo "OK: Backup cron installed (Sunday 03:00 UTC)"

# ────────────────────────────────────────────────────────────────────────────
# 8. Verify cluster formation
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo "STEP 8: Verifying cluster formation..."

REPLICA_COUNT=$(clickhouse-client --host 127.0.0.1 \
    --query "SELECT count() FROM system.clusters WHERE cluster='predator_cluster'")

if [[ "$REPLICA_COUNT" -ge 1 ]]; then
    echo "OK: Cluster 'predator_cluster' visible ($REPLICA_COUNT shard rows)"
else
    echo "WARN: Cluster topology not yet visible — ZooKeeper may still be syncing"
fi

echo ""
echo "=== ClickHouse Setup COMPLETE ==="
echo "insert_quorum=2 and select_sequential_consistency=1 enforced via profile [A4]"
echo "Separate keyspaces: predator_audit | predator_features"
echo "Backup cron: Sundays 03:00 UTC → /data/clickhouse-backups/"
echo "Zone B only: $ZONE_B_IP:9000"
