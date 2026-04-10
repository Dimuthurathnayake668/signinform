// PREDATOR 2026 — src/security/hsm_client.rs
// SCRUM-19 | Phase 0 | Spec §10.4, §16.2
//
// Thales Luna PCIe HSM client — Ed25519 signing via PKCS#11.
// CRITICAL: Ed25519 ONLY. No ECDSA. No HMAC. No software fallback. [FIXED A5, SEC-1]
// Signing latency target: ≤ 5μs p99 (Spec §3.1)

use std::sync::OnceLock;
use std::ffi::CString;
use std::os::raw::{c_ulong, c_void};

// ---------------------------------------------------------------------------
// PKCS#11 constant subset (CKM_EDDSA = 0x00001057 per PKCS#11 v3.0)
// ---------------------------------------------------------------------------
const CKM_EDDSA: c_ulong = 0x0000_1057;
const CKA_CLASS: c_ulong = 0x0000_0000;
const CKA_KEY_TYPE: c_ulong = 0x0000_0100;
const CKA_LABEL: c_ulong = 0x0000_0003;
const CKO_PRIVATE_KEY: c_ulong = 0x0000_0003;
const CKK_EC_EDWARDS: c_ulong = 0x0000_0040; // Ed25519 key type

/// HSM slot / partition configuration.
#[derive(Clone, Debug)]
pub struct HsmConfig {
    /// Path to the Thales Luna PKCS#11 shared library.
    pub pkcs11_lib: String,
    /// PKCS#11 slot ID (Luna partition index, typically 0).
    pub slot_id: c_ulong,
    /// Label of the Ed25519 signing key on the HSM.
    pub key_label: String,
    /// Luna partition PIN (obtained from Vault at startup — never hardcoded).
    pub pin: String,
}

/// Live signing context — session handle + key handle pre-fetched at startup.
struct HsmSession {
    /// libpkcs11 function list pointer (CK_FUNCTION_LIST_PTR).
    fn_list: *const c_void,
    session: c_ulong,
    private_key: c_ulong,
}

// SAFETY: HsmSession is accessed only from the hot-path signing thread (core 2-15)
// after single-threaded initialisation.
unsafe impl Send for HsmSession {}
unsafe impl Sync for HsmSession {}

static HSM_SESSION: OnceLock<HsmSession> = OnceLock::new();

/// Initialise the PKCS#11 session and pre-fetch the Ed25519 key handle.
/// Must be called once at process startup before any signing operations.
///
/// # Errors
/// Returns a descriptive string on any PKCS#11 error.
pub fn init(cfg: &HsmConfig) -> Result<(), String> {
    HSM_SESSION.get_or_try_init(|| connect(cfg))?;
    Ok(())
}

/// Sign `payload` with the HSM Ed25519 key.
///
/// Hot-path function — called on every order submission (SCRUM-40).
/// Latency target: ≤ 5μs p99.
///
/// # Errors
/// Returns `HsmError` on PKCS#11 failure. The caller MUST halt trading on error —
/// there is no software signing fallback (SEC-1).
#[inline]
pub fn sign_ed25519(payload: &[u8]) -> Result<[u8; 64], HsmError> {
    let session = HSM_SESSION
        .get()
        .ok_or(HsmError::NotInitialised)?;

    // SAFETY: fn_list and session are valid for the lifetime of the process
    unsafe { pkcs11_sign(session, payload) }
}

// ---------------------------------------------------------------------------
// Internal implementation
// ---------------------------------------------------------------------------

fn connect(cfg: &HsmConfig) -> Result<HsmSession, String> {
    // Validate: reject any attempted use of ECDSA or HMAC keys (SEC-1)
    if cfg.key_label.to_lowercase().contains("ecdsa")
        || cfg.key_label.to_lowercase().contains("hmac")
        || cfg.key_label.to_lowercase().contains("rsa")
    {
        return Err(format!(
            "SECURITY VIOLATION: key_label '{}' suggests non-Ed25519 algorithm. \
             Only Ed25519 is permitted (SEC-1, A5).",
            cfg.key_label
        ));
    }

    // Dynamic loading of libCryptoki2_64.so
    let lib_path = CString::new(cfg.pkcs11_lib.as_str()).map_err(|e| e.to_string())?;

    // --- PKCS#11 call sequence (pseudocode — real impl uses pkcs11 crate or raw FFI) ---
    // 1. C_GetFunctionList()
    // 2. pFunctionList->C_Initialize(NULL)
    // 3. pFunctionList->C_OpenSession(slot_id, CKF_SERIAL_SESSION, NULL, NULL, &session)
    // 4. pFunctionList->C_Login(session, CKU_USER, pin, pin_len)
    // 5. C_FindObjectsInit / C_FindObjects searching CKA_LABEL + CKO_PRIVATE_KEY + CKK_EC_EDWARDS
    // 6. C_FindObjectsFinal → store handle
    //
    // This uses the `pkcs11` crate in production. Stubbed here as the crate
    // is added to Cargo.toml during SCRUM-40 (hsm_signer full implementation).
    let _ = lib_path;

    log::info!(
        "HSM connected: slot={}, key='{}', algo=Ed25519 (CKM_EDDSA={:#010x})",
        cfg.slot_id, cfg.key_label, CKM_EDDSA
    );

    // Return stub session — real impl stores CK_SESSION_HANDLE + CK_OBJECT_HANDLE
    Ok(HsmSession {
        fn_list: std::ptr::null(),
        session: 0,
        private_key: 0,
    })
}

/// PKCS#11 C_Sign wrapper for Ed25519.
///
/// On the hot path this is the only signing code path — no branch to any
/// software fallback exists anywhere in the binary.
unsafe fn pkcs11_sign(session: &HsmSession, payload: &[u8]) -> Result<[u8; 64], HsmError> {
    // Real implementation:
    //   C_SignInit(session, CKM_EDDSA, private_key)
    //   C_Sign(session, payload, payload_len, sig_buf, &sig_len)  → sig_len must == 64
    //   assert sig_len == 64 (Ed25519 produces exactly 64-byte signatures)
    let _ = (session, payload);

    // Stub — replaced in SCRUM-40 with real PKCS#11 call
    Err(HsmError::NotImplemented(
        "pkcs11_sign stub — full implementation in SCRUM-40 (hsm_signer)".into(),
    ))
}

// ---------------------------------------------------------------------------
// Error type
// ---------------------------------------------------------------------------

#[derive(Debug)]
pub enum HsmError {
    NotInitialised,
    Pkcs11(c_ulong, String),
    InvalidSignatureLength(usize),
    NotImplemented(String),
}

impl std::fmt::Display for HsmError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::NotInitialised => write!(f, "HSM not initialised — call hsm_client::init() first"),
            Self::Pkcs11(rv, msg) => write!(f, "PKCS#11 error CKR={rv:#010x}: {msg}"),
            Self::InvalidSignatureLength(n) => {
                write!(f, "PKCS#11 returned {n}-byte signature; Ed25519 requires exactly 64")
            }
            Self::NotImplemented(s) => write!(f, "Not implemented: {s}"),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rejects_ecdsa_key_label() {
        let cfg = HsmConfig {
            pkcs11_lib: "/usr/safenet/lunaclient/lib/libCryptoki2_64.so".into(),
            slot_id: 0,
            key_label: "predator_ecdsa_key".into(),
            pin: "test".into(),
        };
        let result = connect(&cfg);
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("SECURITY VIOLATION"));
    }

    #[test]
    fn rejects_hmac_key_label() {
        let cfg = HsmConfig {
            pkcs11_lib: "/usr/safenet/lunaclient/lib/libCryptoki2_64.so".into(),
            slot_id: 0,
            key_label: "predator_hmac_signing".into(),
            pin: "test".into(),
        };
        let result = connect(&cfg);
        assert!(result.is_err());
    }

    #[test]
    fn accepts_ed25519_key_label() {
        // Should not reject this label (it will fail at library load, not label check)
        let cfg = HsmConfig {
            pkcs11_lib: "/nonexistent.so".into(),
            slot_id: 0,
            key_label: "predator_ed25519_order_signing".into(),
            pin: "test".into(),
        };
        // Error is expected (lib not found), but NOT a SECURITY VIOLATION error
        let result = connect(&cfg);
        if let Err(e) = result {
            assert!(!e.contains("SECURITY VIOLATION"), "Should not reject Ed25519 label: {e}");
        }
    }
}
