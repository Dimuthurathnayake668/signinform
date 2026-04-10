// PREDATOR 2026 - Phase 1
// SCRUM-24 / Spec Sections 5.2, 5.3 (FIXED C1, C2)
// Time-based EWMA and realized volatility in seconds.

#[derive(Debug, Clone, Copy)]
pub struct EwmaState {
    pub mean: f32,
    pub var: f32,
}

impl EwmaState {
    pub fn new(mean: f32, var: f32) -> Self {
        Self { mean, var }
    }
}

// FIXED C1: alpha is time-based, recomputed per tick from wall-clock elapsed seconds.
pub fn ewma_update(state: &mut EwmaState, new_value: f32, dt_seconds: f32, tau_seconds: f32) {
    let alpha = 1.0f32 - (-dt_seconds / tau_seconds).exp();
    let delta = new_value - state.mean;
    state.mean += alpha * delta;
    state.var = (1.0 - alpha) * (state.var + alpha * delta * delta);
}

pub fn ewma_std(state: &EwmaState) -> f32 {
    state.var.max(0.0).sqrt()
}

pub fn normalize_price(price_raw: f32, state: &EwmaState) -> f32 {
    let std = ewma_std(state).max(1e-6);
    ((price_raw - state.mean) / std).clamp(-5.0, 5.0)
}

// FIXED C2: realized volatility windows are in seconds, not ticks.
pub fn realized_vol_seconds(samples: &[(u64, f32)], now_ns: u64, window_sec: u64) -> f32 {
    let min_ns = now_ns.saturating_sub(window_sec.saturating_mul(1_000_000_000));
    let mut vals: Vec<f32> = samples
        .iter()
        .filter(|(ts, _)| *ts >= min_ns && *ts <= now_ns)
        .map(|(_, v)| *v)
        .collect();

    if vals.len() < 2 {
        return 0.0;
    }

    let mean = vals.iter().sum::<f32>() / vals.len() as f32;
    let mut var = 0.0f32;
    for v in vals.drain(..) {
        let d = v - mean;
        var += d * d;
    }
    (var / (samples.len().max(1) as f32)).sqrt()
}
