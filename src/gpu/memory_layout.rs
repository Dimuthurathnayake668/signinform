// PREDATOR 2026 — src/gpu/memory_layout.rs
// SCRUM-16 | Phase 0 | Spec §3.3
//
// Pre-allocates ALL GPU buffers at startup. Zero cudaMalloc on hot path.
// Fixed address slots — never freed, never fragmented. [FIXED Mi4]

use std::sync::OnceLock;

/// Byte offsets matching §3.3 GPU Memory Pre-Allocation Layout table.
/// These are logical offset constants used for documentation; actual CUDA
/// allocations are performed by GpuMemoryLayout::new() at startup.
pub mod offsets {
    pub const BUF_TICKS_RAW: usize = 0x0000_0000;
    pub const BUF_FEATURES_NORM: usize = 0x0008_0000;
    pub const BUF_LATENT: usize = 0x0010_0000;
    pub const BUF_QP: usize = 0x0020_0000;
    pub const BUF_TRAJECTORY: usize = 0x0030_0000;
    pub const BUF_ACTOR_ACTION: usize = 0x0040_0000;
    pub const BUF_RISK_METRICS: usize = 0x0041_0000;
    pub const BUF_GAP_TOKEN: usize = 0x0042_0000;
    pub const BUF_KELLY_FRACTIONS: usize = 0x0043_0000;
    pub const MODEL_SLOT_A: usize = 0x0100_0000; // Champion  ~1.7 GB
    pub const MODEL_SLOT_B: usize = 0x0800_0000; // Challenger ~1.7 GB
}

/// Sizes in bytes for each pre-allocated buffer (§3.3).
pub mod sizes {
    pub const TICKS_RAW: usize = 1024 * 128 * 4; // (1024,128) f32 = 512 KB
    pub const FEATURES_NORM: usize = 1024 * 128 * 4; // 512 KB
    pub const LATENT: usize = 1024 * 256 * 4; //   1 MB
    pub const QP: usize = 1024 * 256 * 4; //   1 MB
    pub const TRAJECTORY: usize = 1000 * 256 * 4; //   1 MB
    pub const ACTOR_ACTION: usize = 64 * 8 * 4; //   2 KB
    pub const RISK_METRICS: usize = 64 * 5 * 4; //   1.25 KB
    pub const GAP_TOKEN: usize = 128 * 4; // 512 B
    pub const KELLY_FRACTIONS: usize = 64 * 4; // 256 B
    pub const MODEL_SLOT: usize = 1_825_000_000; // ~1.7 GB per slot
    pub const TOTAL_DATA_BUFFERS: usize = TICKS_RAW
        + FEATURES_NORM
        + LATENT
        + QP
        + TRAJECTORY
        + ACTOR_ACTION
        + RISK_METRICS
        + GAP_TOKEN
        + KELLY_FRACTIONS;
    /// Total including both model slots (~3.403 GB)
    pub const TOTAL_ALL: usize = TOTAL_DATA_BUFFERS + 2 * MODEL_SLOT;
    /// Minimum free GPU memory required after allocation (30 GB)
    pub const MIN_FREE_AFTER_ALLOC: u64 = 30 * 1024 * 1024 * 1024;
}

/// Handle to a CUDA device buffer. Wraps a raw pointer obtained at startup.
/// SAFETY: pointer is valid for the lifetime of the process.
#[derive(Debug)]
pub struct CudaBuffer {
    pub ptr: *mut u8,
    pub bytes: usize,
    pub name: &'static str,
}

// SAFETY: GpuMemoryLayout is initialised once and only accessed from the
// designated hot-path cores (0-15) via shared-memory reads.
unsafe impl Send for CudaBuffer {}
unsafe impl Sync for CudaBuffer {}

/// All pre-allocated GPU buffers. Holds exactly one instance for the
/// lifetime of the process (stored in a OnceLock).
pub struct GpuMemoryLayout {
    pub ticks_raw: CudaBuffer,
    pub features_norm: CudaBuffer,
    pub latent: CudaBuffer,
    pub qp: CudaBuffer,
    pub trajectory: CudaBuffer,
    pub actor_action: CudaBuffer,
    pub risk_metrics: CudaBuffer,
    pub gap_token: CudaBuffer,
    pub kelly_fractions: CudaBuffer,
    /// Slot A — champion model weights (fixed address, never freed)
    pub model_slot_a: CudaBuffer,
    /// Slot B — challenger model weights (fixed address, never freed)
    pub model_slot_b: CudaBuffer,
}

static GPU_LAYOUT: OnceLock<GpuMemoryLayout> = OnceLock::new();

impl GpuMemoryLayout {
    /// Allocate all buffers at process startup.
    ///
    /// Must be called exactly once from the main thread before any hot-path
    /// processing begins. Panics if CUDA allocation fails or free memory
    /// after allocation is below 30 GB.
    ///
    /// This is the ONLY place `cudaMalloc` may be called in the binary.
    pub fn init() -> &'static GpuMemoryLayout {
        GPU_LAYOUT.get_or_init(|| {
            // In production this calls into the CUDA FFI layer.
            // The allocator is provided by `crate::cuda_ffi`.
            Self::allocate_all()
        })
    }

    /// Returns the global layout. Panics if `init()` has not been called.
    #[inline]
    pub fn get() -> &'static GpuMemoryLayout {
        GPU_LAYOUT.get().expect("GpuMemoryLayout::init() must be called before get()")
    }

    fn allocate_all() -> GpuMemoryLayout {
        use crate::cuda_ffi::{cuda_malloc, cuda_free_memory};

        macro_rules! alloc {
            ($name:expr, $bytes:expr) => {{
                let ptr = cuda_malloc($bytes)
                    .unwrap_or_else(|e| panic!("cudaMalloc({}, {} bytes) failed: {}", $name, $bytes, e));
                CudaBuffer { ptr, bytes: $bytes, name: $name }
            }};
        }

        let layout = GpuMemoryLayout {
            ticks_raw:        alloc!("buf_ticks_raw",       sizes::TICKS_RAW),
            features_norm:    alloc!("buf_features_norm",   sizes::FEATURES_NORM),
            latent:           alloc!("buf_latent",          sizes::LATENT),
            qp:               alloc!("buf_qp",              sizes::QP),
            trajectory:       alloc!("buf_trajectory",      sizes::TRAJECTORY),
            actor_action:     alloc!("buf_actor_action",    sizes::ACTOR_ACTION),
            risk_metrics:     alloc!("buf_risk_metrics",    sizes::RISK_METRICS),
            gap_token:        alloc!("buf_gap_token",       sizes::GAP_TOKEN),
            kelly_fractions:  alloc!("buf_kelly_fractions", sizes::KELLY_FRACTIONS),
            model_slot_a:     alloc!("model_slot_a",        sizes::MODEL_SLOT),
            model_slot_b:     alloc!("model_slot_b",        sizes::MODEL_SLOT),
        };

        // Verify >= 30 GB free after allocation (§3.3 challenger activation condition)
        let free = cuda_free_memory().expect("cudaMemGetInfo failed");
        assert!(
            free >= sizes::MIN_FREE_AFTER_ALLOC,
            "cudaMemGetInfo: only {free} bytes free after allocation; need >= {}",
            sizes::MIN_FREE_AFTER_ALLOC
        );

        log::info!(
            "GpuMemoryLayout: allocated {:.1} GB total; {:.1} GB free remaining",
            sizes::TOTAL_ALL as f64 / 1e9,
            free as f64 / 1e9
        );

        layout
    }
}

#[cfg(test)]
mod tests {
    use super::sizes;

    #[test]
    fn total_data_buffers_size() {
        // Data buffers should total ~3.5 MB
        assert!(sizes::TOTAL_DATA_BUFFERS < 10 * 1024 * 1024);
    }

    #[test]
    fn model_slots_are_large() {
        // Each model slot must be at least 1.5 GB
        assert!(sizes::MODEL_SLOT >= 1_500_000_000);
    }

    #[test]
    fn total_all_fits_in_80gb() {
        // Total reserved must be less than 80 GB H100 HBM3
        assert!(sizes::TOTAL_ALL < 80u64.pow(1) as usize * 1024 * 1024 * 1024);
    }
}
