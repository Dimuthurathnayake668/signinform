// PREDATOR 2026 — src/ingestion/timestamp_capture.rs
// SCRUM-17 | Phase 0 | Spec §4.2
//
// Hardware nanosecond timestamp capture via SO_TIMESTAMPNS kernel socket option.
// All tick timestamps use CLOCK_MONOTONIC_RAW (PERF-2 global constraint).

use std::time::{Duration, SystemTime, UNIX_EPOCH};
use std::io;

/// A nanosecond-resolution timestamp as ns since UNIX epoch.
/// Captured via SO_TIMESTAMPNS kernel socket option on the Solarflare ef_vi socket.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub struct TimestampNs(pub u64);

impl TimestampNs {
    /// Read the current clock (CLOCK_MONOTONIC_RAW) without going through libc time.
    /// Used for latency profiling on the hot path (SCRUM-45).
    #[inline(always)]
    pub fn now_monotonic_raw() -> Self {
        let mut ts = libc::timespec { tv_sec: 0, tv_nsec: 0 };
        // SAFETY: CLOCK_MONOTONIC_RAW is always available on Linux >= 2.6.28
        unsafe {
            libc::clock_gettime(libc::CLOCK_MONOTONIC_RAW, &mut ts);
        }
        TimestampNs((ts.tv_sec as u64) * 1_000_000_000 + ts.tv_nsec as u64)
    }

    /// Wall-clock ns since epoch — for audit timestamps only (not hot path latency).
    #[inline]
    pub fn now_wall() -> Self {
        let ns = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or(Duration::ZERO)
            .as_nanos() as u64;
        TimestampNs(ns)
    }

    /// Elapsed nanoseconds since `earlier`.
    #[inline(always)]
    pub fn elapsed_since(self, earlier: TimestampNs) -> u64 {
        self.0.saturating_sub(earlier.0)
    }
}

/// Set `SO_TIMESTAMPNS` on a socket fd so the kernel attaches a hardware
/// nanosecond timestamp to each received packet.
///
/// Called once during `IngestionGateway::bind()` (SCRUM-22).
///
/// # Errors
/// Returns an IO error if the setsockopt call fails.
pub fn enable_hw_timestamps(fd: i32) -> io::Result<()> {
    let val: libc::c_int = 1;
    let ret = unsafe {
        libc::setsockopt(
            fd,
            libc::SOL_SOCKET,
            libc::SO_TIMESTAMPNS,
            &val as *const _ as *const libc::c_void,
            std::mem::size_of::<libc::c_int>() as libc::socklen_t,
        )
    };
    if ret != 0 {
        return Err(io::Error::last_os_error());
    }
    Ok(())
}

/// Extract the SO_TIMESTAMPNS value from a recvmsg ancillary data block.
///
/// Returns `None` if no timestamp control message is present (fallback to
/// software clock — should never happen on a correctly configured ef_vi socket).
pub fn extract_hw_timestamp(cmsg_buf: &[u8]) -> Option<TimestampNs> {
    // Walk the cmsg chain looking for SOL_SOCKET / SCM_TIMESTAMPNS
    let mut offset = 0usize;
    while offset + std::mem::size_of::<libc::cmsghdr>() <= cmsg_buf.len() {
        // SAFETY: we bounds-check above
        let hdr = unsafe { &*(cmsg_buf.as_ptr().add(offset) as *const libc::cmsghdr) };
        if hdr.cmsg_level == libc::SOL_SOCKET && hdr.cmsg_type == libc::SCM_TIMESTAMPNS {
            let data_offset = offset + std::mem::size_of::<libc::cmsghdr>();
            if data_offset + std::mem::size_of::<libc::timespec>() <= cmsg_buf.len() {
                let ts = unsafe {
                    &*(cmsg_buf.as_ptr().add(data_offset) as *const libc::timespec)
                };
                let ns = (ts.tv_sec as u64) * 1_000_000_000 + ts.tv_nsec as u64;
                return Some(TimestampNs(ns));
            }
        }
        // Advance to next cmsg (CMSG_NXTHDR equivalent)
        let aligned_len = (hdr.cmsg_len as usize + 7) & !7;
        if aligned_len == 0 { break; }
        offset += aligned_len;
    }
    None
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn monotonic_raw_increases() {
        let t1 = TimestampNs::now_monotonic_raw();
        std::hint::black_box((0..1000).sum::<u64>()); // tiny spin
        let t2 = TimestampNs::now_monotonic_raw();
        assert!(t2 > t1, "CLOCK_MONOTONIC_RAW must be monotonically increasing");
    }

    #[test]
    fn elapsed_since_no_underflow() {
        let t1 = TimestampNs(1_000_000);
        let t2 = TimestampNs(999_000); // earlier
        assert_eq!(t1.elapsed_since(t2), 1_000);
        // saturating_sub — no panic on reversed order
        assert_eq!(t2.elapsed_since(t1), 0);
    }
}
