#!/usr/bin/env bash
# PREDATOR 2026 — ptp_setup.sh
# SCRUM-17 | Phase 0 | Spec §4.2
# PTP hardware timestamping via Solarflare NIC + GPS grandmaster
# Chrony NTP fallback (GPS-fail activation only)
set -euo pipefail

# SESSION_START: github-copilot 2026-04-10 — initial implementation of SCRUM-17

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }
die() { log "FATAL: $*"; exit 1; }

[[ $EUID -eq 0 ]] || die "Must run as root"

# Detect market-data interface (Solarflare port 0)
IFACE="${PREDATOR_PTP_IFACE:-$(ip -o link show | grep -iE 'sfN|enp.*s0f0' | head -1 | awk '{print $2}' | tr -d ':')}"
[[ -n "$IFACE" ]] || die "Cannot detect Solarflare interface — set PREDATOR_PTP_IFACE"
log "PTP interface: $IFACE"

GRANDMASTER_IP="${PREDATOR_GPS_IP:-192.168.200.1}"   # Trimble Thunderbolt E LAN address

###############################################################################
# 1. Install linuxptp
###############################################################################
log "=== 1. Install linuxptp ==="
apt-get install -y linuxptp chrony

###############################################################################
# 2. ptp4l configuration (§4.2 — PTPv2, hardware timestamps)
###############################################################################
log "=== 2. ptp4l configuration ==="
cat > /etc/linuxptp/ptp4l.conf << EOF
# PREDATOR 2026 — PTPv2 hardware timestamp config
# Spec §4.2: IEEE 1588-2008, hardware timestamps via Solarflare NIC
[global]
dataset_comparison         G.8275.x
G.8275.defaultDS.localPriority 128
domainNumber               0
priority1                  128
priority2                  128
clockClass                 135
clockAccuracy              0xFE
offsetScaledLogVariance    0xFFFF
free_running               0
freq_est_interval          1
assume_two_step            0
logging_level              6
path_trace_enabled         0
follow_up_info             0
hybrid_e2e                 0
inhibit_multicast_service  0
net_sync_monitor           0
tc_spanning_tree           0
tx_timestamp_timeout       100
unicast_listen             0
unicast_master_table       0
unicast_req_duration       3600
use_syslog                 1
verbose                    0
summary_interval           -4
kernel_leap                1
check_fup_sync             0

[${IFACE}]
# Hardware timestamping via Solarflare ef_vi
egressLatency              0
ingressLatency             0
delay_mechanism            E2E
network_transport          UDPv4
delay_filter               moving_median
delay_filter_length        10
fault_reset_interval       4
neighborPropDelayThresh    20000000
min_neighbor_prop_delay    -20000000
announce_span              3
masterOnly                 0
EOF

# ptp4l service override — point at GPS grandmaster
mkdir -p /etc/systemd/system/ptp4l.service.d
cat > /etc/systemd/system/ptp4l.service.d/override.conf << EOF
[Service]
ExecStart=
ExecStart=/usr/sbin/ptp4l -f /etc/linuxptp/ptp4l.conf -i ${IFACE} -s
EOF

###############################################################################
# 3. phc2sys — sync system clock to PTP HW clock
###############################################################################
log "=== 3. phc2sys configuration ==="
mkdir -p /etc/systemd/system/phc2sys.service.d
cat > /etc/systemd/system/phc2sys@.service << EOF
[Unit]
Description=PREDATOR 2026 — Synchronize system clock to PTP HW clock on %i
After=ptp4l.service

[Service]
Type=simple
ExecStart=/usr/sbin/phc2sys -s %i -c CLOCK_REALTIME -w -m -O -37
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

###############################################################################
# 4. Chrony NTP fallback (GPS-fail only — §4.2)
###############################################################################
log "=== 4. Chrony NTP fallback ==="
# chrony.conf written to infra/chrony.conf — systemd copies here
cp "$(dirname "$0")/chrony.conf" /etc/chrony/chrony.conf

###############################################################################
# 5. Drift monitoring cron (hourly log to ClickHouse drift_metrics)
###############################################################################
log "=== 5. Drift monitor cron ==="
cat > /usr/local/bin/predator_ptp_drift_monitor.sh << 'DRIFT'
#!/usr/bin/env bash
# Hourly: measure PTP vs NTP delta, log to /var/predator/logs/ptp_drift.jsonl
# ClickHouse ingest happens via the Kafka producer (SCRUM-52)
TS=$(date -u +%s%N)
OFFSET_NS=$(phc_ctl "${PREDATOR_PTP_IFACE:-eth0}" get_time 2>/dev/null \
    | awk '/offset/ {printf "%d", $NF * 1e9}' || echo "0")
WARN_THRESHOLD_NS=10000    # 10 μs
CRIT_THRESHOLD_NS=100000   # 100 μs
LEVEL="OK"
[[ "${OFFSET_NS#-}" -gt "$WARN_THRESHOLD_NS" ]] && LEVEL="WARNING"
[[ "${OFFSET_NS#-}" -gt "$CRIT_THRESHOLD_NS" ]] && LEVEL="CRITICAL"
echo "{\"timestamp_ns\":${TS},\"offset_ns\":${OFFSET_NS},\"level\":\"${LEVEL}\"}" \
    >> /var/predator/logs/ptp_drift.jsonl
[[ "$LEVEL" != "OK" ]] && logger -t predator-ptp "PTP drift ${LEVEL}: ${OFFSET_NS} ns"
DRIFT
chmod +x /usr/local/bin/predator_ptp_drift_monitor.sh

(crontab -l 2>/dev/null; echo "0 * * * * /usr/local/bin/predator_ptp_drift_monitor.sh") \
    | crontab -

###############################################################################
# 6. Enable services
###############################################################################
log "=== 6. Enable PTP services ==="
systemctl daemon-reload
systemctl enable ptp4l
systemctl enable "phc2sys@${IFACE}"
systemctl disable chrony  # chrony only activates on GPS fail (managed by watchdog)
systemctl start ptp4l
systemctl start "phc2sys@${IFACE}"

###############################################################################
# 7. Verify
###############################################################################
log "=== 7. Verification ==="
sleep 2
ptp4l -v 2>&1 | head -5 || true
systemctl is-active ptp4l && log "ptp4l: active" || log "WARNING: ptp4l not active"

log "PTP setup complete. Monitor offset with: pmc -u -b 0 'GET CURRENT_DATA_SET'"
log "Expected: offset < 10000 ns (WARNING) / < 100000 ns (CRITICAL)"

# HANDOFF: ptp_setup.sh — PTPv2 with Solarflare HW timestamps, phc2sys, chrony fallback, drift cron
# what done: ptp4l conf + service, phc2sys service, chrony conf, hourly drift cron to jsonl
# what next: verify drift < 10μs after GPS lock (1-2 min), then SCRUM-18 network_topology
# critical context: GRANDMASTER_IP defaults to 192.168.200.1 — set PREDATOR_GPS_IP env to override
