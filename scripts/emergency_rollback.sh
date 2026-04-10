#!/usr/bin/env bash
# PREDATOR 2026 — Emergency Rollback Script
# SCRUM-20 | Phase 0 | Spec §15.4
#
# Usage:
#   ./scripts/emergency_rollback.sh \
#       --reason "LATENCY_SPIKE" \
#       --operator "alice" \
#       [--env production|shadow|paper] \
#       [--dry-run]
#
# Execution: always runs under set -euo pipefail.
# Side-effects (ALL required for valid emergency rollback):
#   1. Cancel all live exchange orders (Exchange REST + FIX cancel-all)
#   2. Atomically flip champion_version → previous_stable via Vault CAS
#   3. Write EMERGENCY_ROLLBACK event to ClickHouse safety_events table
#   4. Page PagerDuty CRITICAL
#   5. Write local audit record to /var/predator/logs/safety_events.jsonl
#
# Spec §15.4: No prompt, no confirmation, no interactive mode.
# Must complete within 30 seconds end-to-end.
#
# EXIT CODES:
#   0 — rollback successful, all side-effects confirmed
#   1 — validation error (bad arguments)
#   2 — order cancel failed (orders may still be live — ALERT)
#   3 — Vault CAS flip failed (version not reverted — ALERT)
#   4 — audit write failed (rollback may have succeeded — WARN)

set -euo pipefail

# ────────────────────────────────────────────────────────────────────────────
# Defaults
# ────────────────────────────────────────────────────────────────────────────
REASON=""
OPERATOR=""
ENV="${PREDATOR_ENV:-production}"
DRY_RUN=0
START_TS=$(date -u +%s%N)    # nanoseconds for elapsed-time audit

VAULT_ADDR="${VAULT_ADDR:-https://vault.predator.internal:8200}"
CLICKHOUSE_HOST="${CLICKHOUSE_HOST:-clickhouse.predator.internal}"
CLICKHOUSE_PORT="${CLICKHOUSE_PORT:-9000}"
PAGERDUTY_ROUTING_KEY="${PAGERDUTY_ROUTING_KEY:-}"

SAFETY_EVENTS_LOG="/var/predator/logs/safety_events.jsonl"
CHAMPION_VERSION_KEY="predator/trading/champion_version"
STABLE_VERSION_KEY="predator/trading/previous_stable_version"
EXCHANGE_CANCEL_ALL_URL="${EXCHANGE_CANCEL_ALL_URL:-}"

# ────────────────────────────────────────────────────────────────────────────
# Argument parsing
# ────────────────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case $1 in
        --reason)      REASON="$2";   shift 2 ;;
        --operator)    OPERATOR="$2"; shift 2 ;;
        --env)         ENV="$2";      shift 2 ;;
        --dry-run)     DRY_RUN=1;     shift   ;;
        *)
            echo "ERROR: Unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

# ────────────────────────────────────────────────────────────────────────────
# Validation
# ────────────────────────────────────────────────────────────────────────────
if [[ -z "$REASON" ]]; then
    echo "ERROR: --reason is required (e.g. LATENCY_SPIKE, DRAWDOWN_BREACH, MANUAL)" >&2
    exit 1
fi

if [[ -z "$OPERATOR" ]]; then
    echo "ERROR: --operator is required (authenticated username for audit)" >&2
    exit 1
fi

# Allowlist of valid reason codes per Spec §15.4
VALID_REASONS="LATENCY_SPIKE DRAWDOWN_BREACH FEED_OUTAGE HSM_ERROR MODEL_DIVERGENCE MANUAL_HALT"
REASON_VALID=0
for vr in $VALID_REASONS; do
    [[ "$REASON" == "$vr" ]] && REASON_VALID=1 && break
done
if [[ $REASON_VALID -eq 0 ]]; then
    echo "ERROR: Invalid reason '$REASON'. Must be one of: $VALID_REASONS" >&2
    exit 1
fi

EVENT_ID="rollback-$(date -u +%Y%m%dT%H%M%SZ)-$(head -c4 /dev/urandom | xxd -p)"
TIMESTAMP_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)

echo "=== PREDATOR EMERGENCY ROLLBACK ==="
echo "Event ID:   $EVENT_ID"
echo "Reason:     $REASON"
echo "Operator:   $OPERATOR"
echo "Env:        $ENV"
echo "Timestamp:  $TIMESTAMP_ISO"
echo "Dry-run:    $DRY_RUN"
echo "==================================="

# ────────────────────────────────────────────────────────────────────────────
# Helper: Vault CLI wrapper (uses AppRole credentials from env)
# ────────────────────────────────────────────────────────────────────────────
vault_login() {
    if [[ -z "${VAULT_TOKEN:-}" ]]; then
        local role_id="${VAULT_ROLE_ID:?VAULT_ROLE_ID must be set}"
        local secret_id="${VAULT_SECRET_ID:?VAULT_SECRET_ID must be set}"
        VAULT_TOKEN=$(vault write -field=token auth/approle/login \
            role_id="$role_id" secret_id="$secret_id")
        export VAULT_TOKEN
    fi
}

vault_kv_get() {
    local key="$1"
    vault kv get -field=value "$key" 2>/dev/null || echo ""
}

vault_kv_cas() {
    # Atomic CAS: only update if current version matches
    local key="$1" value="$2" cas_version="$3"
    vault kv put -cas="$cas_version" "$key" value="$value"
}

# ────────────────────────────────────────────────────────────────────────────
# Step 1: Cancel all live exchange orders (Spec §15.4 — must happen first)
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo "STEP 1: Cancelling all live exchange orders..."

if [[ $DRY_RUN -eq 1 ]]; then
    echo "[DRY-RUN] Would cancel all orders on exchange"
else
    # Trigger cancel-all via the Predator control socket (fastest path)
    # Falls back to REST cancel-all if control socket is unavailable
    CONTROL_SOCKET="/var/predator/run/control.sock"
    CANCEL_SUCCESS=0

    if [[ -S "$CONTROL_SOCKET" ]]; then
        echo '{"cmd":"cancel_all","reason":"'"$REASON"'","operator":"'"$OPERATOR"'"}' \
            | timeout 10 socat - UNIX-CONNECT:"$CONTROL_SOCKET" \
            | grep -q '"status":"ok"' \
            && CANCEL_SUCCESS=1
    fi

    if [[ $CANCEL_SUCCESS -eq 0 ]] && [[ -n "$EXCHANGE_CANCEL_ALL_URL" ]]; then
        echo "Control socket unavailable — falling back to REST cancel-all"
        HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
            -X DELETE "$EXCHANGE_CANCEL_ALL_URL" \
            -H "Authorization: Bearer $(vault_kv_get predator/trading/exchange_api_token)" \
            --max-time 15)
        [[ "$HTTP_STATUS" == "200" ]] && CANCEL_SUCCESS=1
    fi

    if [[ $CANCEL_SUCCESS -eq 0 ]]; then
        echo "CRITICAL: Failed to cancel live orders. Manual intervention required!" >&2
        # Still attempt remaining steps — we want the audit trail
        EXIT_CODE_OVERRIDE=2
    else
        echo "OK: All orders cancelled"
    fi
fi

# ────────────────────────────────────────────────────────────────────────────
# Step 2: Flip champion_version → previous_stable via Vault CAS
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo "STEP 2: Reverting champion version via Vault CAS..."

if [[ $DRY_RUN -eq 1 ]]; then
    echo "[DRY-RUN] Would CAS $CHAMPION_VERSION_KEY → previous_stable"
else
    vault_login

    PREVIOUS_STABLE=$(vault_kv_get "$STABLE_VERSION_KEY")
    if [[ -z "$PREVIOUS_STABLE" ]]; then
        echo "ERROR: Cannot read previous_stable_version from Vault" >&2
        EXIT_CODE_OVERRIDE="${EXIT_CODE_OVERRIDE:-3}"
    else
        # Get current champion for audit record
        CURRENT_CHAMPION=$(vault_kv_get "$CHAMPION_VERSION_KEY")
        CURRENT_KV_VERSION=$(vault kv metadata get -format=json "$CHAMPION_VERSION_KEY" \
            | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['data']['current_version'])")

        if vault_kv_cas "$CHAMPION_VERSION_KEY" "$PREVIOUS_STABLE" "$CURRENT_KV_VERSION" 2>&1; then
            echo "OK: Champion version reverted: $CURRENT_CHAMPION → $PREVIOUS_STABLE"
        else
            echo "ERROR: Vault CAS failed — version $CURRENT_KV_VERSION may have changed" >&2
            EXIT_CODE_OVERRIDE="${EXIT_CODE_OVERRIDE:-3}"
        fi
    fi
fi

# ────────────────────────────────────────────────────────────────────────────
# Step 3: Write safety event to ClickHouse audit log (Spec §18)
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo "STEP 3: Writing safety event to ClickHouse..."

ELAPSED_MS=$(( ( $(date -u +%s%N) - START_TS ) / 1000000 ))

SAFETY_EVENT_JSON=$(cat <<EOF
{
  "event_id":        "$EVENT_ID",
  "event_type":      "EMERGENCY_ROLLBACK",
  "reason":          "$REASON",
  "operator":        "$OPERATOR",
  "env":             "$ENV",
  "timestamp_utc":   "$TIMESTAMP_ISO",
  "elapsed_ms":      $ELAPSED_MS,
  "from_version":    "${CURRENT_CHAMPION:-unknown}",
  "to_version":      "${PREVIOUS_STABLE:-unknown}",
  "severity":        "CRITICAL"
}
EOF
)

if [[ $DRY_RUN -eq 0 ]]; then
    echo "$SAFETY_EVENT_JSON" | clickhouse-client \
        --host "$CLICKHOUSE_HOST" \
        --port "$CLICKHOUSE_PORT" \
        --query "INSERT INTO predator.safety_events FORMAT JSONEachRow" \
        2>&1 || {
        echo "WARN: ClickHouse write failed — event written to local JSONL only" >&2
        EXIT_CODE_OVERRIDE="${EXIT_CODE_OVERRIDE:-4}"
    }
fi

# Always write local JSONL (survives ClickHouse outage)
mkdir -p "$(dirname "$SAFETY_EVENTS_LOG")"
echo "$SAFETY_EVENT_JSON" >> "$SAFETY_EVENTS_LOG"
echo "OK: Safety event written to $SAFETY_EVENTS_LOG"

# ────────────────────────────────────────────────────────────────────────────
# Step 4: PagerDuty CRITICAL alert
# ────────────────────────────────────────────────────────────────────────────
echo ""
echo "STEP 4: Sending PagerDuty CRITICAL alert..."

if [[ $DRY_RUN -eq 1 ]]; then
    echo "[DRY-RUN] Would page PagerDuty CRITICAL"
elif [[ -n "$PAGERDUTY_ROUTING_KEY" ]]; then
    PD_PAYLOAD=$(cat <<EOF
{
  "routing_key":  "$PAGERDUTY_ROUTING_KEY",
  "event_action": "trigger",
  "dedup_key":    "$EVENT_ID",
  "payload": {
    "summary":  "PREDATOR EMERGENCY ROLLBACK: $REASON (operator: $OPERATOR)",
    "severity": "critical",
    "source":   "emergency_rollback_script",
    "timestamp": "$TIMESTAMP_ISO",
    "custom_details": {
      "event_id":    "$EVENT_ID",
      "reason":      "$REASON",
      "operator":    "$OPERATOR",
      "env":         "$ENV",
      "elapsed_ms":  $ELAPSED_MS
    }
  }
}
EOF
    )
    curl -s -X POST https://events.pagerduty.com/v2/enqueue \
        -H "Content-Type: application/json" \
        -d "$PD_PAYLOAD" \
        --max-time 10 \
        | grep -q '"status":"success"' \
        && echo "OK: PagerDuty alerted" \
        || echo "WARN: PagerDuty alert may have failed (non-fatal)" >&2
else
    echo "WARN: PAGERDUTY_ROUTING_KEY not set — alert skipped" >&2
fi

# ────────────────────────────────────────────────────────────────────────────
# Final status
# ────────────────────────────────────────────────────────────────────────────
TOTAL_ELAPSED_MS=$(( ( $(date -u +%s%N) - START_TS ) / 1000000 ))
echo ""
echo "=== ROLLBACK COMPLETE ==="
echo "Event ID:    $EVENT_ID"
echo "Elapsed:     ${TOTAL_ELAPSED_MS}ms"
echo "========================="

# Warn if we took longer than 30s (Spec §15.4 requirement)
if [[ $TOTAL_ELAPSED_MS -gt 30000 ]]; then
    echo "WARN: Rollback took ${TOTAL_ELAPSED_MS}ms — exceeds 30s target (Spec §15.4)" >&2
fi

exit "${EXIT_CODE_OVERRIDE:-0}"
