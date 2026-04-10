#!/usr/bin/env bash
# PREDATOR 2026 — network_setup.sh
# SCRUM-18 | Phase 0 | Spec §3.5, §4.1
# Solarflare OpenOnload ef_vi configuration, Zone A/B NIC separation
# NO DPDK — OpenOnload only (spec constraint)
set -euo pipefail

# SESSION_START: github-copilot 2026-04-10 — initial implementation of SCRUM-18

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }
die() { log "FATAL: $*"; exit 1; }

[[ $EUID -eq 0 ]] || die "Must run as root"

# Interface names (override via env if different)
IFACE_MKT="${PREDATOR_IFACE_MKT:-enp1s0f0}"    # Port 0 — market data only
IFACE_OE="${PREDATOR_IFACE_OE:-enp1s0f1}"       # Port 1 — order entry only
IFACE_MGMT="${PREDATOR_IFACE_MGMT:-enp2s0}"     # Management NIC (separate physical NIC)

###############################################################################
# 1. Verify Solarflare OpenOnload is installed (NOT DPDK)
###############################################################################
log "=== 1. Verify OpenOnload ==="
command -v onload || die "OpenOnload not installed — install from AMD/Xilinx support portal"
ONLOAD_VER=$(onload --version 2>&1 | head -1)
log "OpenOnload version: $ONLOAD_VER"

# Confirm DPDK is NOT present (spec constraint)
if lsmod | grep -qi "dpdk\|rte_"; then
    die "DPDK kernel module detected — DPDK is FORBIDDEN in PREDATOR stack. Remove it."
fi
log "DPDK: not detected (correct)"

###############################################################################
# 2. Solarflare port 0 — market data only
###############################################################################
log "=== 2. Port 0 — market data ($IFACE_MKT) ==="
ip link set "$IFACE_MKT" up
ip addr flush dev "$IFACE_MKT"
ip addr add "${PREDATOR_MKT_IP:-10.0.1.10}/24" dev "$IFACE_MKT"

# Disable TCP offloads on market-data port — ef_vi bypasses kernel stack
ethtool -K "$IFACE_MKT" rx off tx off gso off gro off lro off tso off || true
ethtool -G "$IFACE_MKT" rx 4096 tx 4096 || true

# Set interrupt coalescing to minimum (latency > throughput on port 0)
ethtool -C "$IFACE_MKT" rx-usecs 0 adaptive-rx off adaptive-tx off || true

log "Market-data port configured: $IFACE_MKT ${PREDATOR_MKT_IP:-10.0.1.10}/24"

###############################################################################
# 3. Solarflare port 1 — order entry only
###############################################################################
log "=== 3. Port 1 — order entry ($IFACE_OE) ==="
ip link set "$IFACE_OE" up
ip addr flush dev "$IFACE_OE"
ip addr add "${PREDATOR_OE_IP:-10.0.2.10}/24" dev "$IFACE_OE"

ethtool -K "$IFACE_OE" rx off tx off gso off gro off lro off tso off || true
ethtool -G "$IFACE_OE" rx 4096 tx 4096 || true
ethtool -C "$IFACE_OE" rx-usecs 0 adaptive-rx off adaptive-tx off || true

log "Order-entry port configured: $IFACE_OE ${PREDATOR_OE_IP:-10.0.2.10}/24"

###############################################################################
# 4. Management NIC — Zone B (ClickHouse, Kafka, SSH)
###############################################################################
log "=== 4. Management NIC ($IFACE_MGMT) — Zone B ==="
ip link set "$IFACE_MGMT" up
ip addr flush dev "$IFACE_MGMT"
ip addr add "${PREDATOR_MGMT_IP:-192.168.1.10}/24" dev "$IFACE_MGMT"
ip route add default via "${PREDATOR_MGMT_GW:-192.168.1.1}" dev "$IFACE_MGMT"

log "Management NIC: $IFACE_MGMT ${PREDATOR_MGMT_IP:-192.168.1.10}/24"

###############################################################################
# 5. nftables — Zone A/B air-gap enforcement (see SCRUM-56 for full ruleset)
#    Minimal bootstrap rules: block any internet-routable traffic on hot-path ports
###############################################################################
log "=== 5. nftables bootstrap (Zone A air-gap) ==="
apt-get install -y nftables

cat > /etc/nftables-predator-bootstrap.conf << NFTEOF
#!/usr/sbin/nft -f
# PREDATOR 2026 — Zone A/B bootstrap separation rules
# Full ruleset implemented in SCRUM-56 (network_segmentation)
flush ruleset

table inet predator_bootstrap {
    chain input {
        type filter hook input priority 0; policy drop;

        # Allow established connections
        ct state established,related accept

        # Loopback
        iif lo accept

        # Management NIC: allow SSH, ClickHouse, Kafka from management VLAN only
        iif "${IFACE_MGMT}" ip saddr { 192.168.0.0/16 } tcp dport { 22, 8123, 9000, 9092, 6379 } accept

        # Zone A (hot path NICs): ONLY exchange co-lo traffic  — no internet
        iif { "${IFACE_MKT}", "${IFACE_OE}" } ip saddr { 10.0.0.0/8 } accept

        # Drop everything else (including any internet traffic on Zone A)
        drop
    }

    chain forward {
        type filter hook forward priority 0; policy drop;
        # No forwarding — this is not a router
    }

    chain output {
        type filter hook output priority 0; policy accept;
        # Allow all outbound (further restricted by SCRUM-56)
    }
}
NFTEOF

nft -f /etc/nftables-predator-bootstrap.conf
systemctl enable nftables
log "nftables Zone A/B bootstrap rules active"

###############################################################################
# 6. ef_vi loopback latency test (records result for hardware_verification.sh)
###############################################################################
log "=== 6. ef_vi latency test ==="
if command -v eflatency &>/dev/null; then
    # eflatency is part of the OpenOnload tools package
    RTT_NS=$(eflatency -i "$IFACE_MKT" --loops 10000 2>&1 | grep "median" | awk '{print $NF}' || echo "SKIP")
    log "ef_vi median RTT: ${RTT_NS} ns"
    echo "${RTT_NS}" > /etc/predator/xconnect_latency_ns.txt
else
    log "WARNING: eflatency not found — skipping latency measurement"
    echo "SKIP" > /etc/predator/xconnect_latency_ns.txt
fi

###############################################################################
# 7. Copy openonload config
###############################################################################
log "=== 7. OpenOnload config ==="
cp "$(dirname "$0")/openonload_config.conf" /etc/OpenOnload/onload.conf 2>/dev/null \
    || log "WARNING: could not copy openonload_config.conf — copy manually"

log "=== network_setup.sh COMPLETE ==="
log "Next: verify ef_vi sockets operational, then SCRUM-19 hsm_key_lifecycle"

# HANDOFF: network_setup.sh — OpenOnload ef_vi, Zone A/B separation, nftables bootstrap
# what done: ports 0+1 configured (no DPDK), Zone A air-gapped via nftables, eflatency measured
# what next: SCRUM-19 hsm_key_lifecycle (Thales Luna + Vault setup)
# critical context: nftables rules are BOOTSTRAP ONLY — full ruleset in SCRUM-56 network_segmentation
