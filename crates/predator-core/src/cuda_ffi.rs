// PREDATOR 2026 — CUDA FFI Stub
// SCRUM-16 / SCRUM-20 Scaffolding | Phase 0 | Spec §3.3
//
// Raw unsafe extern "C" bindings to the CUDA runtime library.
// These are the ONLY CUDA entry-points used by the hot path.
//
// Rules (enforced by code review and CI):
//   - cudaMalloc may ONLY be called from GpuMemoryLayout::init() at startup.
//   - cudaFree may ONLY be called from GpuMemoryLayout::drop() at shutdown.
//   - cudaMemcpy / cudaMemcpyAsync may ONLY be called from model_slots.rs.
//   - NO new cudaMalloc calls anywhere else (Spec [Mi4], §15.5 invariant).
//
// Linking:
//   The CUDA runtime is linked via build.rs (see crates/predator-core/build.rs).
//   cargo:rustc-link-lib=cudart (dynamic) — CUDA 12.4 required.

#![allow(non_camel_case_types)]

use std::ffi::c_void;
use std::os::raw::c_int;

// ── CUDA types ────────────────────────────────────────────────────────────

pub type CudaError = c_int;
pub type CudaStream = *mut c_void;

pub const CUDA_SUCCESS: CudaError = 0;

/// cudaMemcpyKind variants used by PREDATOR (only device↔device on hot path)
#[repr(C)]
#[derive(Debug, Clone, Copy)]
pub enum CudaMemcpyKind {
    HostToHost     = 0,
    HostToDevice   = 1,
    DeviceToHost   = 2,
    DeviceToDevice = 3,
}

// ── Raw extern "C" declarations ────────────────────────────────────────────

extern "C" {
    /// Allocate `size` bytes on the default GPU device.
    /// Only called at startup from GpuMemoryLayout::init().
    pub fn cudaMalloc(dev_ptr: *mut *mut c_void, size: usize) -> CudaError;

    /// Free a device allocation.
    /// Only called at shutdown.
    pub fn cudaFree(dev_ptr: *mut c_void) -> CudaError;

    /// Synchronous device-to-device copy (champion ← challenger weight overwrite).
    pub fn cudaMemcpy(
        dst:   *mut c_void,
        src:   *const c_void,
        count: usize,
        kind:  CudaMemcpyKind,
    ) -> CudaError;

    /// Async copy on a stream (used for challenger weight load from host).
    pub fn cudaMemcpyAsync(
        dst:    *mut c_void,
        src:    *const c_void,
        count:  usize,
        kind:   CudaMemcpyKind,
        stream: CudaStream,
    ) -> CudaError;

    /// Create a stream with priority.
    /// priority: -1 = champion (highest), 0 = challenger.
    pub fn cudaStreamCreateWithPriority(
        p_stream:  *mut CudaStream,
        flags:     c_int,
        priority:  c_int,
    ) -> CudaError;

    /// Destroy a CUDA stream.
    pub fn cudaStreamDestroy(stream: CudaStream) -> CudaError;

    /// Return free and total GPU memory in bytes. Used by init() to verify ≥30GB free.
    pub fn cudaMemGetInfo(free: *mut usize, total: *mut usize) -> CudaError;

    /// Synchronize the device (used in test harness only — never on hot path).
    pub fn cudaDeviceSynchronize() -> CudaError;
}

// ── Safe wrappers ─────────────────────────────────────────────────────────

/// Returns `(free_bytes, total_bytes)` from the GPU.
///
/// # Errors
/// Returns `CudaError` if the query fails.
pub fn mem_get_info() -> Result<(usize, usize), CudaError> {
    let mut free  = 0usize;
    let mut total = 0usize;
    // SAFETY: valid out-pointers, called after CUDA init
    let rc = unsafe { cudaMemGetInfo(&mut free as *mut usize, &mut total as *mut usize) };
    if rc == CUDA_SUCCESS {
        Ok((free, total))
    } else {
        Err(rc)
    }
}

/// Allocate `size` bytes on the GPU.
///
/// # Safety
/// Caller must ensure CUDA has been initialised and that `size` > 0.
///
/// # Errors
/// Returns `CudaError` on allocation failure.
pub unsafe fn malloc(size: usize) -> Result<*mut c_void, CudaError> {
    let mut ptr: *mut c_void = std::ptr::null_mut();
    let rc = cudaMalloc(&mut ptr as *mut *mut c_void, size);
    if rc == CUDA_SUCCESS {
        Ok(ptr)
    } else {
        Err(rc)
    }
}

/// Synchronous device-to-device copy of `count` bytes.
///
/// # Safety
/// Both `dst` and `src` must be valid device pointers with at least `count` bytes accessible.
///
/// # Errors
/// Returns `CudaError` on failure.
pub unsafe fn memcpy_device_to_device(
    dst: *mut c_void,
    src: *const c_void,
    count: usize,
) -> Result<(), CudaError> {
    let rc = cudaMemcpy(dst, src, count, CudaMemcpyKind::DeviceToDevice);
    if rc == CUDA_SUCCESS { Ok(()) } else { Err(rc) }
}

/// Create a CUDA stream with the given priority (-1 = champion, 0 = challenger).
///
/// # Errors
/// Returns `CudaError` on failure.
pub fn stream_create_with_priority(priority: c_int) -> Result<CudaStream, CudaError> {
    let mut stream: CudaStream = std::ptr::null_mut();
    // SAFETY: valid out-pointer
    let rc = unsafe {
        cudaStreamCreateWithPriority(&mut stream as *mut CudaStream, 0, priority)
    };
    if rc == CUDA_SUCCESS { Ok(stream) } else { Err(rc) }
}

#[cfg(test)]
mod tests {
    // Note: actual CUDA FFI tests require a GPU runtime and run in CI only
    // (tagged #[ignore] so `cargo test` in CI without GPU skips them).
    //
    // Real coverage happens in the hardware-in-the-loop test suite (SCRUM-35).
    #[test]
    fn cuda_memcpy_kind_values() {
        use super::CudaMemcpyKind;
        assert_eq!(CudaMemcpyKind::DeviceToDevice as i32, 3);
        assert_eq!(CudaMemcpyKind::HostToDevice as i32, 1);
    }
}
