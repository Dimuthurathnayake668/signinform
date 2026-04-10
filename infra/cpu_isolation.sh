#!/usr/bin/env bash
# PREDATOR 2026 — cpu_isolation.sh
# SCRUM-15 | Phase 0 | Spec §3.2
# Configures CPU core isolation, IRQ affinity, SCHED_FIFO priorities
# Run as root after bare_metal_setup.sh. Requires reboot to take full effect.
set -euo pipefail

# SESSION_START: github-copilot 2026-04-10 — initial implementation of SCRUM-15

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }
die() { log "FATAL: $*"; exit 1; }

[[ $EUID -eq 0 ]] || die "Must run as root"

###############################################################################
# 1. sysctl — kernel RT runtime + NUMA + network tuning (Spec §3.2)
###############################################################################
log "=== 1. sysctl parameters ==="
cat > /etc/sysctl.d/99-predator.conf << 'EOF'
# PREDATOR 2026 — §3.2 hot-path kernel parameters
kernel.sched_rt_runtime_us = -1
net.core.busy_read = 50
net.core.busy_poll = 50
vm.swappiness = 0
vm.hugetlb_shm_group = 27
kernel.numa_balancing = 0

# Huge pages for GPU/Solarflare DMA
vm.nr_hugepages = 1024

# Reduce kernel scheduling jitter
kernel.perf_cpu_time_max_percent = 0
kernel.watchdog = 0
EOF

sysctl --system | grep -E "sched_rt|swappiness|numa_balancing|busy_poll" || true
log "sysctl applied"

###############################################################################
# 2. GRUB — isolcpus, nohz_full, rcu_nocbs for cores 0-15
###############################################################################
log "=== 2. GRUB isolcpus ==="
GRUB_PARAM="isolcpus=0-15 nohz_full=0-15 rcu_nocbs=0-15 intel_pstate=disable mitigations=off"

if grep -q "GRUB_CMDLINE_LINUX" /etc/default/grub; then
    # Append to existing cmdline (idempotent)
    sed -i "s|GRUB_CMDLINE_LINUX=\"\(.*\)\"|GRUB_CMDLINE_LINUX=\"\1 ${GRUB_PARAM}\"|" \
        /etc/default/grub
    # Remove duplicates if applied multiple times
    sed -i 's| \(isolcpus=[^ "]*\) \(.*\)\1|\1 \2|g' /etc/default/grub 2>/dev/null || true
fi
update-grub
log "GRUB updated — REBOOT REQUIRED to activate isolcpus=0-15"
cp /etc/default/grub /etc/predator/grub_active.txt

###############################################################################
# 3. IRQ affinity — move all IRQs off cores 0-15
###############################################################################
log "=== 3. IRQ affinity ==="
# Cores 0-15 bitmask in hex (16 bits set = 0xFFFF, invert for cores 16+)
# CPU mask for cores 16-95 (EPYC 9654 has 96 cores): bit mask 0xFFFFFFFFFFFF0000
IRQ_AFFINITY_MASK="ffff0000"

for irq_dir in /proc/irq/*/smp_affinity; do
    echo "$IRQ_AFFINITY_MASK" > "$irq_dir" 2>/dev/null || true
done
log "IRQ affinity set to mask ${IRQ_AFFINITY_MASK} (cores 16+ only)"

# Persist via irqaffinity service
cat > /etc/systemd/system/predator-irqaffinity.service << 'EOF'
[Unit]
Description=PREDATOR 2026 — Set IRQ affinity away from isolated cores
After=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/predator_set_irqaffinity.sh

[Install]
WantedBy=multi-user.target
EOF

cat > /usr/local/bin/predator_set_irqaffinity.sh << 'IRQSCRIPT'
#!/usr/bin/env bash
MASK="ffff0000"
for f in /proc/irq/*/smp_affinity; do echo "$MASK" > "$f" 2>/dev/null || true; done
IRQSCRIPT
chmod +x /usr/local/bin/predator_set_irqaffinity.sh
systemctl enable --now predator-irqaffinity.service

###############################################################################
# 4. cgroup for training workloads (cores 48-63)
###############################################################################
log "=== 4. cgroups for training (cores 48-63) ==="
apt-get install -y cgroup-tools

# Create training cgroup with SCHED_BATCH and CPU pin to 48-63
cat > /etc/systemd/system/predator-training.slice << 'EOF'
[Unit]
Description=PREDATOR 2026 — Training workload slice

[Slice]
CPUSchedulingPolicy=batch
AllowedCPUs=48-63
EOF
systemctl daemon-reload

###############################################################################
# 5. SCHED_FIFO helper for hot-path processes
#    (actual processes set priority in Rust via libc::sched_setscheduler)
###############################################################################
log "=== 5. RT limits for predator user ==="
cat > /etc/security/limits.d/predator-rt.conf << 'EOF'
# PREDATOR 2026 — RT scheduling limits for hot-path processes
predator  hard  rtprio  99
predator  soft  rtprio  99
predator  hard  memlock  unlimited
predator  soft  memlock  unlimited
EOF

###############################################################################
# 6. Verification (runtime — post-boot)
###############################################################################
log "=== 6. Pre-reboot verification ==="
echo "sysctl checks:"
sysctl kernel.sched_rt_runtime_us vm.swappiness kernel.numa_balancing

echo ""
log "SUCCESS — CPU isolation configured."
log "REQUIRED: Reboot the node, then run verify_cpu_isolation.sh to confirm"
log "Expected after reboot: 'isolcpus=0-15' visible in /proc/cmdline"
log "Expected: no IRQ migrates to cores 0-15 under stress test"

# HANDOFF: cpu_isolation.sh — sysctl, GRUB isolcpus=0-15 nohz_full rcu_nocbs, IRQ affinity
# what done: sysctl applied immediately; GRUB updated; irqaffinity service enabled; cgroup slice for training
# what next: REBOOT node, verify /proc/cmdline shows isolcpus=0-15, then SCRUM-16 gpu_memory_layout
# critical context: REBOOT REQUIRED before hot-path processes can rely on core isolation
