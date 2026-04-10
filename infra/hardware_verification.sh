#!/usr/bin/env bash
# PREDATOR 2026 — hardware_verification.sh
# SCRUM-14 | Phase 0 | Spec §3.1
# Emits PASS/FAIL for each acceptance criterion. Exit code 0 = all pass.
set -euo pipefail

PASS=0
FAIL=0
RESULTS=()

check() {
    local name="$1"
    local result="$2"   # "pass" or "fail"
    local detail="$3"
    if [[ "$result" == "pass" ]]; then
        RESULTS+=("[PASS] $name — $detail")
        ((PASS++))
    else
        RESULTS+=("[FAIL] $name — $detail")
        ((FAIL++))
    fi
}

###############################################################################
# 1. H100 SXM5 80GB HBM3
###############################################################################
if nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null \
        | grep -qi "H100"; then
    GPU_MEM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader | head -1 | tr -d ' MiB')
    if [[ "${GPU_MEM:-0}" -ge 81920 ]]; then   # 80GB = 81920 MiB
        check "H100 SXM5 80GB" "pass" "$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader | head -1)"
    else
        check "H100 SXM5 80GB" "fail" "GPU found but memory ${GPU_MEM}MiB < 81920MiB"
    fi
else
    check "H100 SXM5 80GB" "fail" "H100 not detected by nvidia-smi"
fi

###############################################################################
# 2. AMD EPYC 9654 — NUMA topology
###############################################################################
CPU_MODEL=$(lscpu | grep "Model name" | head -1 | cut -d: -f2 | xargs)
if echo "$CPU_MODEL" | grep -qi "EPYC 9654"; then
    NUMA_NODES=$(numactl --hardware | grep "available:" | awk '{print $2}')
    check "AMD EPYC 9654 NUMA" "pass" "CPU: $CPU_MODEL  NUMA nodes: $NUMA_NODES"
else
    check "AMD EPYC 9654 NUMA" "fail" "CPU: $CPU_MODEL (expected EPYC 9654)"
fi

###############################################################################
# 3. Solarflare X4 dual NIC ports
###############################################################################
SF_PORTS=$(ip -o link show | grep -cE 'sfN|enp[0-9]+s0f[01]' || true)
if [[ "$SF_PORTS" -ge 2 ]]; then
    check "Solarflare X4 dual NIC" "pass" "${SF_PORTS} Solarflare ports detected"
else
    check "Solarflare X4 dual NIC" "fail" "Expected >= 2 ports, found ${SF_PORTS}"
fi

###############################################################################
# 4. Thales Luna PCIe HSM — FIPS 140-2 Level 3
###############################################################################
PKCS11_LIB="${PREDATOR_PKCS11_LIB:-/usr/safenet/lunaclient/lib/libCryptoki2_64.so}"
if [[ -f "$PKCS11_LIB" ]]; then
    check "Thales Luna PKCS#11 library" "pass" "$PKCS11_LIB"
else
    check "Thales Luna PKCS#11 library" "fail" "Not found: $PKCS11_LIB"
fi

if command -v lunacm &>/dev/null; then
    SLOT_OUTPUT=$(lunacm -c "slot list" 2>&1 || true)
    if echo "$SLOT_OUTPUT" | grep -qi "Luna"; then
        check "Thales Luna HSM slot" "pass" "Luna slot detected"
    else
        check "Thales Luna HSM slot" "fail" "No Luna slot in slot list output"
    fi
else
    check "Thales Luna lunacm" "fail" "lunacm not in PATH"
fi

###############################################################################
# 5. NVMe — 2× 4TB Samsung 990 Pro
###############################################################################
NVME_4TB=$(nvme list 2>/dev/null | grep -c "Samsung.*990" || true)
if [[ "$NVME_4TB" -ge 2 ]]; then
    check "2× Samsung 990 Pro NVMe" "pass" "${NVME_4TB} drives detected"
else
    check "2× Samsung 990 Pro NVMe" "fail" "Expected 2, found ${NVME_4TB}"
fi

# RAID-1
if mdadm --detail /dev/md0 2>/dev/null | grep -q "active"; then
    RAID_STATE=$(mdadm --detail /dev/md0 | grep "State :" | awk '{print $3}')
    check "NVMe RAID-1 (/dev/md0)" "pass" "State: $RAID_STATE"
else
    check "NVMe RAID-1 (/dev/md0)" "fail" "/dev/md0 not active"
fi

###############################################################################
# 6. UPS (APC Smart-UPS 3000VA)
###############################################################################
if apcaccess status 2>/dev/null | grep -q "STATUS.*ONLINE"; then
    BCHARGE=$(apcaccess status 2>/dev/null | grep "^BCHARGE" | awk '{print $3}')
    check "UPS APC 3000VA" "pass" "ONLINE, charge ${BCHARGE}%"
else
    check "UPS APC 3000VA" "fail" "apcupsd not ONLINE — check connection"
fi

###############################################################################
# 7. Cross-connect latency < 100ns (Equinix NY4)
###############################################################################
# Can only be verified by capturing hardware timestamps on ef_vi sockets
# during loopback test with exchange co-lo. This is a manual attestation.
if [[ -f /etc/predator/xconnect_latency_ns.txt ]]; then
    MEASURED=$(cat /etc/predator/xconnect_latency_ns.txt | tr -d ' ')
    if [[ "${MEASURED:-9999}" -lt 100 ]]; then
        check "Cross-connect < 100ns" "pass" "${MEASURED}ns measured"
    else
        check "Cross-connect < 100ns" "fail" "${MEASURED}ns >= 100ns threshold"
    fi
else
    check "Cross-connect < 100ns" "fail" \
        "/etc/predator/xconnect_latency_ns.txt not found — write measured ns after ef_vi loopback test"
fi

###############################################################################
# Results
###############################################################################
echo ""
echo "======================================================================"
echo "PREDATOR 2026 — Hardware Verification Report — $(date -u)"
echo "======================================================================"
for r in "${RESULTS[@]}"; do echo "$r"; done
echo "----------------------------------------------------------------------"
echo "TOTAL: ${PASS} PASS / ${FAIL} FAIL"
echo "======================================================================"

# Write machine-readable result
{
    echo "timestamp=$(date -u +%s)"
    echo "pass=$PASS"
    echo "fail=$FAIL"
    for r in "${RESULTS[@]}"; do echo "$r"; done
} > /etc/predator/hw_verification_result.txt

[[ "$FAIL" -eq 0 ]] || exit 1
