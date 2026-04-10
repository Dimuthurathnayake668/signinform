// PREDATOR 2026 - Phase 1
// SCRUM-23 / Spec Section 5.1 (FIXED M4)
// Sequence gap detection with immediate primary->backup failover and gap token injection.

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FeedAction {
    Process,
    DiscardAndAlert(&'static str),
    SwitchFeedAndReprocess,
    InjectGapToken(u64),
}

#[derive(Debug, Clone)]
pub struct MarketPacket {
    pub seq_no: u64,
    pub exchange_ts_ns: u64,
    pub payload: Vec<u8>,
    pub checksum: u32,
}

pub struct FeedValidator {
    pub expected_seq_no: u64,
    pub primary_active: bool,
}

impl FeedValidator {
    pub fn new(start_seq: u64) -> Self {
        Self {
            expected_seq_no: start_seq,
            primary_active: true,
        }
    }

    pub fn validate_packet(&mut self, pkt: &MarketPacket) -> FeedAction {
        if pkt.checksum != compute_checksum(&pkt.payload) {
            return FeedAction::DiscardAndAlert("CHECKSUM_FAIL");
        }

        if pkt.seq_no != self.expected_seq_no {
            if self.primary_active {
                self.primary_active = false;
                return FeedAction::SwitchFeedAndReprocess;
            }
            return FeedAction::InjectGapToken(pkt.exchange_ts_ns);
        }

        // Critical protocol rule: expected_seq_no only increments after successful Process.
        self.expected_seq_no = pkt.seq_no + 1;
        FeedAction::Process
    }

    pub fn on_primary_recovered(&mut self) {
        self.primary_active = true;
    }
}

pub fn compute_checksum(payload: &[u8]) -> u32 {
    // Fast non-cryptographic checksum for feed corruption detection.
    // This is a placeholder checksum contract for protocol validation.
    let mut x: u32 = 0;
    for &b in payload {
        x = x.wrapping_mul(16777619) ^ (b as u32);
    }
    x
}
