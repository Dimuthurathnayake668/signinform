# PREDATOR 2026 — Risk Invariants Policy
# SCRUM-20 | Phase 0 | Spec §15.5, §8, §11
# OPA/Rego policy-as-code — run via `opa eval` in CI policy-gates job
# Constraints: all invariants MUST hold before any promotion is permitted.

package predator.risk

import future.keywords.if
import future.keywords.in

# =============================================================================
# Top-level gate: ALL invariants must pass
# =============================================================================
invariants_pass if {
    max_position_invariant
    kill_switch_liveness_invariant
    order_id_monotonicity_invariant
    rate_limiter_safety_invariant
    drawdown_invariant
    latency_slo_invariant
    hsm_key_invariant
    dual_feed_invariant
    no_dpdk_invariant
}

# =============================================================================
# INV-1: Maximum position per instrument (Spec §8.2)
# ---------------------------------------------------------------------------
# Rejects any config where max_position_usd > 100_000 for any instrument.
# =============================================================================
max_position_invariant if {
    every instrument in input.risk.instruments {
        instrument.max_position_usd <= 100000
    }
}

violation[msg] if {
    instrument := input.risk.instruments[i]
    instrument.max_position_usd > 100000
    msg := sprintf(
        "INV-1 FAIL: instrument %v max_position_usd %v exceeds 100000",
        [instrument.symbol, instrument.max_position_usd]
    )
}

# =============================================================================
# INV-2: Kill-switch liveness (Spec §8.1, TLA+ spec: specs/formal/kill_switch.tla)
# ---------------------------------------------------------------------------
# Kill-switch must be reachable from EVERY state in the state-machine config.
# Config must declare an explicit kill_switch.enabled = true and heartbeat_interval_ms.
# =============================================================================
kill_switch_liveness_invariant if {
    input.safety.kill_switch.enabled == true
    input.safety.kill_switch.heartbeat_interval_ms <= 1000
    input.safety.kill_switch.cancel_on_timeout == true
}

violation[msg] if {
    not input.safety.kill_switch.enabled
    msg := "INV-2 FAIL: kill_switch.enabled must be true"
}

violation[msg] if {
    input.safety.kill_switch.heartbeat_interval_ms > 1000
    msg := sprintf(
        "INV-2 FAIL: kill_switch heartbeat %v ms exceeds 1000 ms maximum",
        [input.safety.kill_switch.heartbeat_interval_ms]
    )
}

# =============================================================================
# INV-3: Order ID monotonicity (Spec §15.5, TLA+ spec already verified)
# ---------------------------------------------------------------------------
# Config must declare order_id_strategy = "monotonic_snowflake"
# and must NOT allow reuse_after_restart = true.
# =============================================================================
order_id_monotonicity_invariant if {
    input.order_management.order_id_strategy == "monotonic_snowflake"
    input.order_management.reuse_after_restart == false
}

violation[msg] if {
    input.order_management.order_id_strategy != "monotonic_snowflake"
    msg := sprintf(
        "INV-3 FAIL: order_id_strategy must be monotonic_snowflake, got %v",
        [input.order_management.order_id_strategy]
    )
}

violation[msg] if {
    input.order_management.reuse_after_restart == true
    msg := "INV-3 FAIL: order ID reuse_after_restart must be false — monotonicity not guaranteed across restarts"
}

# =============================================================================
# INV-4: Rate limiter safety (Spec §8.3, TLA+ spec verified)
# ---------------------------------------------------------------------------
# Rate limiter token bucket must be bounded:
#   - max_tokens <= 1000 (orders/sec burst)
#   - refill_rate_per_sec <= 500 (sustained order rate)
# =============================================================================
rate_limiter_safety_invariant if {
    input.rate_limiter.max_tokens <= 1000
    input.rate_limiter.refill_rate_per_sec <= 500
}

violation[msg] if {
    input.rate_limiter.max_tokens > 1000
    msg := sprintf(
        "INV-4 FAIL: rate_limiter.max_tokens %v exceeds burst cap of 1000",
        [input.rate_limiter.max_tokens]
    )
}

violation[msg] if {
    input.rate_limiter.refill_rate_per_sec > 500
    msg := sprintf(
        "INV-4 FAIL: rate_limiter.refill_rate_per_sec %v exceeds sustained cap of 500",
        [input.rate_limiter.refill_rate_per_sec]
    )
}

# =============================================================================
# INV-5: Drawdown circuit-breaker (Spec §8.4)
# ---------------------------------------------------------------------------
# max_daily_drawdown_bps must be declared and <= 150 bps (1.5%)
# Circuit breaker must halt ALL new orders when triggered.
# =============================================================================
drawdown_invariant if {
    input.risk.max_daily_drawdown_bps <= 150
    input.risk.circuit_breaker.halt_on_drawdown == true
}

violation[msg] if {
    input.risk.max_daily_drawdown_bps > 150
    msg := sprintf(
        "INV-5 FAIL: max_daily_drawdown_bps %v exceeds 150 bps maximum",
        [input.risk.max_daily_drawdown_bps]
    )
}

violation[msg] if {
    input.risk.circuit_breaker.halt_on_drawdown != true
    msg := "INV-5 FAIL: circuit_breaker.halt_on_drawdown must be true"
}

# =============================================================================
# INV-6: Latency SLO attestation (Spec §15.2)
# ---------------------------------------------------------------------------
# Config must attest p99 latency budget <= 20 μs for tick-to-order.
# =============================================================================
latency_slo_invariant if {
    input.performance.tick_to_order_p99_budget_us <= 20
}

violation[msg] if {
    input.performance.tick_to_order_p99_budget_us > 20
    msg := sprintf(
        "INV-6 FAIL: tick_to_order_p99_budget_us %v exceeds 20 μs SLO",
        [input.performance.tick_to_order_p99_budget_us]
    )
}

# =============================================================================
# INV-7: HSM key constraints (Spec §16, SEC-1)
# ---------------------------------------------------------------------------
# - Only Ed25519 keys permitted (no RSA, ECDSA, HMAC)
# - key_rotation_days must be <= 90
# - shadow_period_hours must be >= 1
# =============================================================================
hsm_key_invariant if {
    input.security.hsm.allowed_algorithms == ["Ed25519"]
    input.security.hsm.key_rotation_days <= 90
    input.security.hsm.shadow_period_hours >= 1
}

violation[msg] if {
    alg := input.security.hsm.allowed_algorithms[_]
    alg != "Ed25519"
    msg := sprintf(
        "INV-7 FAIL: HSM algorithm %v not permitted — only Ed25519 allowed (SEC-1)",
        [alg]
    )
}

violation[msg] if {
    input.security.hsm.key_rotation_days > 90
    msg := sprintf(
        "INV-7 FAIL: key_rotation_days %v exceeds 90-day maximum",
        [input.security.hsm.key_rotation_days]
    )
}

# =============================================================================
# INV-8: Dual-feed integrity (Spec §4.1)
# ---------------------------------------------------------------------------
# Both Zone A and Zone B feeds must be declared;
# single-feed mode must NOT be enabled in production.
# =============================================================================
dual_feed_invariant if {
    input.ingestion.zone_a.enabled == true
    input.ingestion.zone_b.enabled == true
    input.ingestion.single_feed_mode == false
}

violation[msg] if {
    input.ingestion.single_feed_mode == true
    msg := "INV-8 FAIL: single_feed_mode must be false — dual-feed mandatory (Spec §4.1)"
}

# =============================================================================
# INV-9: No DPDK (Spec §4.2 — OpenOnload ef_vi ONLY)
# ---------------------------------------------------------------------------
# dpdk_enabled must explicitly be false; openonload_enabled must be true.
# =============================================================================
no_dpdk_invariant if {
    input.network.dpdk_enabled == false
    input.network.openonload_enabled == true
}

violation[msg] if {
    input.network.dpdk_enabled == true
    msg := "INV-9 FAIL: DPDK must not be enabled — OpenOnload ef_vi ONLY (Spec §4.2)"
}

violation[msg] if {
    input.network.openonload_enabled != true
    msg := "INV-9 FAIL: openonload_enabled must be true"
}
