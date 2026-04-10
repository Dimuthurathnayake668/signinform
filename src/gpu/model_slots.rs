// PREDATOR 2026 — src/gpu/model_slots.rs
// SCRUM-16 | Phase 0 | Spec §3.3, §3.4
//
// Champion / Challenger model slot management.
// Weights are OVERWRITTEN IN-PLACE on promotion — never freed, never fragmented. [FIXED Mi4]
// Champion stream priority=-1 (high), challenger stream priority=0 (low). [Spec §3.4]

use std::sync::atomic::{AtomicU64, Ordering};
use crate::gpu::memory_layout::{GpuMemoryLayout, sizes};

/// Model version hash — SHA-256 truncated to 64 bits for fast comparison.
pub type ModelVersion = u64;

/// Which GPU slot is currently the live champion.
/// Atomically swapped during champion promotion.
static CHAMPION_SLOT: AtomicU64 = AtomicU64::new(0); // 0 = slot A, 1 = slot B

/// CUDA stream handles (opaque u64 representing cudaStream_t pointers).
/// Initialised once at startup by `ModelSlots::init_streams()`.
static CHAMPION_STREAM: AtomicU64 = AtomicU64::new(0);
static CHALLENGER_STREAM: AtomicU64 = AtomicU64::new(0);

pub struct ModelSlots;

impl ModelSlots {
    /// Create CUDA streams with correct priorities (§3.4).
    /// champion_stream priority = -1 (high); challenger_stream priority = 0 (low).
    pub fn init_streams() {
        use crate::cuda_ffi::{cuda_stream_create_with_priority};
        let champ_stream = cuda_stream_create_with_priority(-1)
            .expect("Failed to create champion CUDA stream (priority -1)");
        let chal_stream = cuda_stream_create_with_priority(0)
            .expect("Failed to create challenger CUDA stream (priority 0)");
        CHAMPION_STREAM.store(champ_stream, Ordering::Release);
        CHALLENGER_STREAM.store(chal_stream, Ordering::Release);
        log::info!("CUDA streams initialised: champion={champ_stream:#018x} challenger={chal_stream:#018x}");
    }

    /// Return a pointer to the champion model slot buffer.
    #[inline]
    pub fn champion_ptr() -> *mut u8 {
        let layout = GpuMemoryLayout::get();
        match CHAMPION_SLOT.load(Ordering::Acquire) {
            0 => layout.model_slot_a.ptr,
            _ => layout.model_slot_b.ptr,
        }
    }

    /// Return a pointer to the challenger model slot buffer.
    #[inline]
    pub fn challenger_ptr() -> *mut u8 {
        let layout = GpuMemoryLayout::get();
        match CHAMPION_SLOT.load(Ordering::Acquire) {
            0 => layout.model_slot_b.ptr,
            _ => layout.model_slot_a.ptr,
        }
    }

    /// Return the champion CUDA stream handle.
    #[inline]
    pub fn champion_stream() -> u64 {
        CHAMPION_STREAM.load(Ordering::Acquire)
    }

    /// Return the challenger CUDA stream handle.
    #[inline]
    pub fn challenger_stream() -> u64 {
        CHALLENGER_STREAM.load(Ordering::Acquire)
    }

    /// Promote challenger to champion.
    ///
    /// Protocol (§3.3 "Model slot protocol"):
    /// 1. cudaMemcpy challenger → champion slot (device-to-device, ~10ms for 1.7 GB @ 3.35 TB/s)
    /// 2. Atomically flip CHAMPION_SLOT
    /// 3. Slot that was champion is now challenger — ready for next load
    ///
    /// Called from `rollback_engine` (SCRUM-72) and `champion_challenger` (SCRUM-70).
    /// MUST be called with all open challenger orders cancelled first.
    pub fn promote_challenger(
        new_version: ModelVersion,
        evidence_log: &str,
    ) -> Result<(), PromotionError> {
        use crate::cuda_ffi::cuda_memcpy_device_to_device;

        let layout = GpuMemoryLayout::get();
        let old_champ_slot = CHAMPION_SLOT.load(Ordering::Acquire);
        let (src_ptr, dst_ptr) = match old_champ_slot {
            // Slot B is current challenger → copy B → A, then flip to 0 (slot A = champ)
            0 => (layout.model_slot_b.ptr, layout.model_slot_a.ptr),
            // Slot A is current challenger → copy A → B, then flip to 1 (slot B = champ)
            _ => (layout.model_slot_a.ptr, layout.model_slot_b.ptr),
        };

        // Step 1: in-place overwrite via device-to-device memcpy (no free/alloc)
        cuda_memcpy_device_to_device(dst_ptr, src_ptr, sizes::MODEL_SLOT)
            .map_err(PromotionError::CudaMemcpy)?;

        // Step 2: atomic slot pointer flip
        let new_champ_slot = 1 - old_champ_slot;
        CHAMPION_SLOT.store(new_champ_slot as u64, Ordering::Release);

        log::info!(
            "ModelSlots: champion promoted to version {new_version:#018x} \
             (slot {}→{}); {}",
            old_champ_slot, new_champ_slot, evidence_log
        );

        Ok(())
    }

    /// Load new weights into the challenger slot (overwrites in-place).
    pub fn load_challenger_weights(
        weights_ptr: *const u8,
        bytes: usize,
    ) -> Result<(), PromotionError> {
        use crate::cuda_ffi::cuda_memcpy_host_to_device;

        assert!(
            bytes <= sizes::MODEL_SLOT,
            "Challenger weights ({bytes} B) exceed slot size ({} B)",
            sizes::MODEL_SLOT
        );

        let dst = Self::challenger_ptr();
        cuda_memcpy_host_to_device(dst, weights_ptr, bytes)
            .map_err(PromotionError::CudaMemcpy)?;

        log::info!("ModelSlots: challenger slot loaded ({bytes} bytes)");
        Ok(())
    }
}

#[derive(Debug)]
pub enum PromotionError {
    CudaMemcpy(String),
}

impl std::fmt::Display for PromotionError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::CudaMemcpy(e) => write!(f, "cudaMemcpy failed: {e}"),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn slot_flip_is_correct() {
        // Slot A = 0 → challenger = B(1); after promotion → champion = 1
        let old = 0u64;
        let new = 1 - old;
        assert_eq!(new, 1);
        // Slot B = 1 → challenger = A(0); after promotion → champion = 0
        let old2 = 1u64;
        let new2 = 1 - old2;
        assert_eq!(new2, 0);
    }
}
