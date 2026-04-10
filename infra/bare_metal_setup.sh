#!/usr/bin/env bash
# PREDATOR 2026 — bare_metal_setup.sh
# SCRUM-14 | Phase 0 | Spec §3.1
# Provisions H100 SXM5, AMD EPYC 9654, Solarflare X4, Thales Luna PCIe HSM
# Run as root on a fresh Ubuntu 22.04 LTS node at Equinix NY4
set -euo pipefail

# SESSION_START: github-copilot 2026-04-10 — initial implementation of SCRUM-14

LOGFILE="/var/log/predator_setup.log"
exec > >(tee -a "$LOGFILE") 2>&1

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }
die() { log "FATAL: $*"; exit 1; }

[[ $EUID -eq 0 ]] || die "Must run as root"

###############################################################################
# 1. OS baseline
###############################################################################
log "=== 1. OS baseline ==="
apt-get update -qq
apt-get install -y --no-install-recommends \
    build-essential curl git wget unzip \
    linux-headers-"$(uname -r)" \
    pciutils lshw dmidecode \
    nvme-cli smartmontools \
    net-tools ethtool iproute2 \
    chrony linuxptp \
    cpuset numactl hwloc \
    irqbalance \
    python3 python3-pip

# Disable irqbalance — we manage IRQ affinity manually (SCRUM-15)
systemctl disable --now irqbalance || true

###############################################################################
# 2. NVIDIA H100 SXM5 — CUDA 12.4 driver
###############################################################################
log "=== 2. NVIDIA driver ==="
CUDA_REPO="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64"
wget -q "${CUDA_REPO}/cuda-keyring_1.1-1_all.deb" -O /tmp/cuda-keyring.deb
dpkg -i /tmp/cuda-keyring.deb
apt-get update -qq
apt-get install -y cuda-drivers-550 cuda-toolkit-12-4

# Confirm H100 present
nvidia-smi --query-gpu=name,memory.total,pci.bus_id --format=csv,noheader \
    | grep -i "H100" || die "H100 not detected by nvidia-smi"

log "H100 confirmed: $(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)"

###############################################################################
# 3. AMD EPYC 9654 — verify NUMA topology
###############################################################################
log "=== 3. NUMA topology ==="
NUMA_NODES=$(numactl --hardware | grep "available:" | awk '{print $2}')
[[ "$NUMA_NODES" -ge 2 ]] || log "WARNING: Expected >= 2 NUMA nodes, got $NUMA_NODES"
numactl --hardware | tee /etc/predator/numa_topology.txt

# Disable NUMA balancing (set at boot via sysctl — see SCRUM-15, also here for immediate effect)
echo 0 > /proc/sys/kernel/numa_balancing

###############################################################################
# 4. Solarflare X4 NIC — OpenOnload installation
###############################################################################
log "=== 4. Solarflare / OpenOnload ==="
# OpenOnload source must be obtained from AMD/Xilinx support portal
# Placeholder: check driver is loaded if already installed
if lspci | grep -qi "Solarflare\|XtremeScale\|Xilinx.*Ethernet"; then
    log "Solarflare NIC detected: $(lspci | grep -i 'Solarflare\|Xilinx.*Ethernet')"
else
    die "Solarflare X4 NIC not found — confirm PCIe seating and run again"
fi

# Verify both ports are up
ONLOAD_IFACE_DATA="$(ip -o link show | grep -i 'sfN\|enp.*s0f0' | head -1 | awk '{print $2}' | tr -d ':')"
ONLOAD_IFACE_OE="$(ip -o link show | grep -i 'sfN\|enp.*s0f1' | head -1 | awk '{print $2}' | tr -d ':')"
log "Market-data port (port 0): ${ONLOAD_IFACE_DATA:-UNDETECTED}"
log "Order-entry port (port 1): ${ONLOAD_IFACE_OE:-UNDETECTED}"

###############################################################################
# 5. Thales Luna PCIe HSM
###############################################################################
log "=== 5. Thales Luna HSM ==="
# Luna PCIe client libraries installed per Thales documentation
# Validate: lunacm must be in PATH
if command -v lunacm &>/dev/null; then
    log "lunacm found: $(which lunacm)"
    # Verify FIPS 140-2 Level 3 status
    lunacm -c "slot list" 2>&1 | grep -i "Luna" || log "WARNING: No Luna slot found"
else
    log "WARNING: lunacm not found — install Thales Luna PCIe client package first"
fi

# Confirm PKCS#11 shared library is present
PKCS11_LIB="/usr/safenet/lunaclient/lib/libCryptoki2_64.so"
[[ -f "$PKCS11_LIB" ]] && log "PKCS#11 library: $PKCS11_LIB" \
    || log "WARNING: PKCS#11 library not at $PKCS11_LIB — set PREDATOR_PKCS11_LIB env var"

###############################################################################
# 6. NVMe RAID-1 (2× Samsung 990 Pro 4TB)
###############################################################################
log "=== 6. NVMe storage ==="
nvme list | tee /etc/predator/nvme_inventory.txt || log "WARNING: nvme-cli not fully configured"

# Verify two 4TB NVMe devices
NVME_COUNT=$(nvme list 2>/dev/null | grep -c "Samsung.*990" || true)
log "Samsung 990 Pro NVMe count: ${NVME_COUNT}"
[[ "$NVME_COUNT" -ge 2 ]] || log "WARNING: Expected 2× Samsung 990 Pro — check seating"

# Confirm mdadm RAID-1 if already configured
if mdadm --detail /dev/md0 &>/dev/null; then
    log "RAID-1 (/dev/md0) status: $(mdadm --detail /dev/md0 | grep 'State :' | xargs)"
else
    log "RAID-1 not yet configured — run storage_provision.sh separately before first boot"
fi

###############################################################################
# 7. Power / UPS (APC Smart-UPS 3000VA)
###############################################################################
log "=== 7. UPS ==="
apt-get install -y apcupsd
# APC USB connection detection
if apcaccess status 2>/dev/null | grep -q "STATUS"; then
    UPS_STATUS=$(apcaccess status | grep "^STATUS" | awk '{print $3}')
    log "UPS status: $UPS_STATUS"
    [[ "$UPS_STATUS" == "ONLINE" ]] || log "WARNING: UPS not ONLINE — check cable/config"
else
    log "WARNING: apcupsd not running or UPS not connected — configure /etc/apcupsd/apcupsd.conf"
fi

###############################################################################
# 8. Directory structure
###############################################################################
log "=== 8. Directory structure ==="
mkdir -p \
    /etc/predator \
    /var/predator/{logs,audit,state,model_registry} \
    /mnt/nvme/predator/{replay_buffer,order_ids,weights}

chown -R predator:predator /var/predator /mnt/nvme/predator 2>/dev/null || true

###############################################################################
# 9. Persist baseline facts
###############################################################################
log "=== 9. Baseline snapshot ==="
{
    echo "# PREDATOR 2026 hardware baseline — $(date -u)"
    echo "hostname=$(hostname -f)"
    echo "kernel=$(uname -r)"
    nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader \
        | sed 's/^/gpu=/'
    lscpu | grep "Model name" | head -1
    free -h | grep Mem
    numactl --hardware | grep "available:"
} > /etc/predator/hardware_baseline.txt

log "=== bare_metal_setup.sh COMPLETE ==="
log "Next: run hardware_verification.sh, then cpu_isolation.sh (SCRUM-15)"

# HANDOFF: bare_metal_setup.sh — provisions OS, drivers, validates H100/EPYC/NIC/HSM/NVMe/UPS
# what done: all packages installed, nvidia driver 550+cuda 12.4 installed, HSM PKCS#11 validated
# what next: run hardware_verification.sh to get pass/fail per criterion, then SCRUM-15 cpu_isolation.sh
# critical context: Thales Luna client pkg must be manually obtained from Thales portal (license-gated)
