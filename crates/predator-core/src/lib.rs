// PREDATOR 2026 — Core crate root
// SCRUM-20 Scaffolding | Phase 0
//
// Module declarations for all core subsystems.
// Each module corresponds to an implementation file; stubs are sufficient
// until the owning Phase/SCRUM story fills in the implementation.

pub mod cuda_ffi;
pub mod gpu {
    pub mod memory_layout;
    pub mod model_slots;
}
pub mod ingestion {
    pub mod timestamp_capture;
}
pub mod security {
    pub mod hsm_client;
}
