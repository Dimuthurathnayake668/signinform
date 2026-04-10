#!/usr/bin/env bash
# PREDATOR 2026 — key_rotation.sh
# SCRUM-19 | Phase 0 | Spec §16.2
#
# 90-day Ed25519 key rotation on Thales Luna PCIe HSM
# Schedule: every Sunday 02:00-04:00 UTC (cron — see bottom)
# Dual-key shadow period: both keys active for 1 hour, then old key deleted
#
# Requires: lunacm in PATH, Vault CLI, predator trading process to be pausable
set -euo pipefail

# SESSION_START: github-copilot 2026-04-10 — initial implementation of SCRUM-19

log()  { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] KEY_ROTATION: $*" | tee -a /var/predator/logs/key_rotation.log; }
die()  { log "FATAL: $*"; exit 1; }
audit(){ echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" >> /var/predator/audit/key_rotation_audit.jsonl; }

[[ $EUID -eq 0 ]] || die "Must run as root"
command -v lunacm   || die "lunacm not found"
command -v vault    || die "vault not found"

PARTITION="${HSM_PARTITION:-predator}"
OLD_KEY_LABEL="${HSM_KEY_LABEL:-predator_ed25519_order_signing}"
NEW_KEY_LABEL="${OLD_KEY_LABEL}_new_$(date +%Y%m%d)"
ACTIVE_KEY_FILE="/etc/predator/active_key_label.txt"
SHADOW_DURATION_SECONDS=3600  # 1 hour dual-key shadow period

log "=== Key rotation starting ==="
log "Old key: $OLD_KEY_LABEL → New key: $NEW_KEY_LABEL"

###############################################################################
# Step 1: Generate new Ed25519 key pair INSIDE HSM (never exported)
###############################################################################
log "Step 1: Generate new Ed25519 key pair inside HSM"
lunacm -c "slot set slot 0" -c \
    "generatekeypair -kt ed25519 -label ${NEW_KEY_LABEL} -nonextractable" \
    || die "Failed to generate Ed25519 key in HSM"

audit "{\"event\":\"key_generated\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"label\":\"${NEW_KEY_LABEL}\"}"

###############################################################################
# Step 2: Register new public key with exchange (testnet first)
###############################################################################
log "Step 2: Register new public key on exchange (testnet)"
NEW_PUBKEY=$(lunacm -c "slot set slot 0" -c "keyattributes -handle ${NEW_KEY_LABEL} -attr public_key" \
    2>&1 | grep -oE '[0-9A-Fa-f]{64}' | head -1)
[[ -n "$NEW_PUBKEY" ]] || die "Could not extract public key for $NEW_KEY_LABEL"

# Register on Binance testnet (validate before mainnet)
python3 /usr/local/lib/predator/register_exchange_key.py \
    --env testnet \
    --key-label "$NEW_KEY_LABEL" \
    --pubkey "$NEW_PUBKEY" \
    || die "Testnet key registration failed"
log "Testnet registration: SUCCESS (pubkey: ${NEW_PUBKEY:0:16}...)"

###############################################################################
# Step 3: Shadow key period — both old and new keys active
###############################################################################
log "Step 3: Shadow key period (${SHADOW_DURATION_SECONDS}s)"
# Tell the trading process to accept both keys; implemented via shared memory flag
echo "SHADOW:${NEW_KEY_LABEL}" > /run/predator/key_shadow
log "Shadow period started — both keys valid for ${SHADOW_DURATION_SECONDS}s"
sleep "$SHADOW_DURATION_SECONDS"

###############################################################################
# Step 4: Verify new key on testnet (sign + verify round-trip)
###############################################################################
log "Step 4: Verify new key on testnet"
python3 /usr/local/lib/predator/verify_exchange_key.py \
    --env testnet \
    --key-label "$NEW_KEY_LABEL" \
    || die "Testnet key verification failed — aborting rotation"

###############################################################################
# Step 5: Atomic CAS switch of active key in shared memory
###############################################################################
log "Step 5: Atomic switch to new key"
# predator_key_switch performs CAS on /run/predator/active_key SHM segment
predator_key_switch --old "$OLD_KEY_LABEL" --new "$NEW_KEY_LABEL" \
    || die "CAS switch failed — old key still active"

echo "$NEW_KEY_LABEL" > "$ACTIVE_KEY_FILE"
audit "{\"event\":\"key_switched\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"old\":\"${OLD_KEY_LABEL}\",\"new\":\"${NEW_KEY_LABEL}\"}"

log "Active key switched to: $NEW_KEY_LABEL"
rm -f /run/predator/key_shadow

###############################################################################
# Step 6: Register new key on mainnet exchange
###############################################################################
log "Step 6: Register new key on mainnet"
python3 /usr/local/lib/predator/register_exchange_key.py \
    --env mainnet \
    --key-label "$NEW_KEY_LABEL" \
    --pubkey "$NEW_PUBKEY" \
    || die "Mainnet key registration failed"

###############################################################################
# Step 7: Delete old key after 24h (scheduled via at)
###############################################################################
log "Step 7: Schedule old key deletion in 24h"
cat > /tmp/delete_old_key.sh << DELSCRIPT
#!/bin/bash
lunacm -c "slot set slot 0" -c "deleteobject -label ${OLD_KEY_LABEL}" \
    && echo '{"event":"key_deleted","timestamp":"'"\$(date -u +%Y-%m-%dT%H:%M:%SZ)"'","label":"${OLD_KEY_LABEL}"}' \
        >> /var/predator/audit/key_rotation_audit.jsonl
DELSCRIPT
chmod +x /tmp/delete_old_key.sh
echo "/tmp/delete_old_key.sh" | at "now + 24 hours" 2>/dev/null \
    || log "WARNING: 'at' not available — schedule key deletion manually in 24h"

audit "{\"event\":\"rotation_complete\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"new_key\":\"${NEW_KEY_LABEL}\"}"

log "=== Key rotation COMPLETE ==="
log "New active key: $NEW_KEY_LABEL"
log "Old key ($OLD_KEY_LABEL) will be deleted in 24h"

# ---------------------------------------------------------------------------
# Crontab entry (add via: crontab -e)
# Runs every Sunday 02:00 UTC (key rotation window 02:00-04:00 UTC)
# ---------------------------------------------------------------------------
# 0 2 * * 0 HSM_KEY_LABEL=predator_ed25519_order_signing /opt/predator/infra/key_rotation.sh
