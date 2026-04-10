// PREDATOR 2026 - Phase 1
// SCRUM-22 / Spec Section 5.1
// Ingestion gateway contract: dual feed handling, sequence tracking, and pre-allocated ring buffer.

use crate::ingestion::deserializer::{deserialize_binary_sbe, deserialize_orderbook_json, deserialize_tick_json, MarketOrderbookSnap, MarketTickRaw, WireFormat};
use crate::ingestion::feed_validator::{FeedAction, FeedValidator, MarketPacket};

const RING_CAPACITY: usize = 10_000;

#[derive(Debug, Clone)]
pub struct TickRingBuffer {
    data: Vec<MarketTickRaw>,
    write_idx: usize,
}

impl TickRingBuffer {
    pub fn preallocated() -> Self {
        let mut data = Vec::with_capacity(RING_CAPACITY);
        // Reserve exact logical slots to match the 10k tick ring contract.
        data.resize(
            RING_CAPACITY,
            MarketTickRaw {
                seq_no: 0,
                exchange_ts_ns: 0,
                symbol: String::new(),
                price: 0.0,
                volume: 0.0,
                checksum: 0,
            },
        );
        Self { data, write_idx: 0 }
    }

    pub fn push(&mut self, tick: MarketTickRaw) {
        self.data[self.write_idx] = tick;
        self.write_idx = (self.write_idx + 1) % RING_CAPACITY;
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ActiveFeed {
    Primary,
    Backup,
}

pub struct IngestionGateway {
    pub active_feed: ActiveFeed,
    pub validator: FeedValidator,
    pub tick_ring: TickRingBuffer,
}

impl IngestionGateway {
    pub fn new(initial_seq: u64) -> Self {
        Self {
            active_feed: ActiveFeed::Primary,
            validator: FeedValidator::new(initial_seq),
            tick_ring: TickRingBuffer::preallocated(),
        }
    }

    pub fn on_packet(
        &mut self,
        pkt: MarketPacket,
        wire_format: WireFormat,
        symbol: &str,
    ) -> Result<(Option<MarketTickRaw>, Option<MarketOrderbookSnap>, FeedAction), String> {
        let action = self.validator.validate_packet(&pkt);

        match action {
            FeedAction::DiscardAndAlert(reason) => {
                return Ok((None, None, FeedAction::DiscardAndAlert(reason)));
            }
            FeedAction::SwitchFeedAndReprocess => {
                self.active_feed = ActiveFeed::Backup;
                return Ok((None, None, FeedAction::SwitchFeedAndReprocess));
            }
            FeedAction::InjectGapToken(ts) => {
                return Ok((None, None, FeedAction::InjectGapToken(ts)));
            }
            FeedAction::Process => {}
        }

        match wire_format {
            WireFormat::Json => {
                // Try tick first; if fields do not match, treat as orderbook payload.
                if let Ok(tick) = deserialize_tick_json(&pkt.payload) {
                    self.tick_ring.push(tick.clone());
                    Ok((Some(tick), None, FeedAction::Process))
                } else {
                    let ob = deserialize_orderbook_json(&pkt.payload)
                        .map_err(|e| format!("orderbook json decode failed: {e}"))?;
                    Ok((None, Some(ob), FeedAction::Process))
                }
            }
            WireFormat::BinarySbe => {
                let (tick, ob) = deserialize_binary_sbe(&pkt.payload, symbol)
                    .map_err(|e| format!("binary sbe decode failed: {e}"))?;
                if let Some(t) = tick.clone() {
                    self.tick_ring.push(t);
                }
                Ok((tick, ob, FeedAction::Process))
            }
        }
    }

    // Called after primary feed has been stable for the configured recovery hold window.
    pub fn recover_primary(&mut self) {
        self.validator.on_primary_recovered();
        self.active_feed = ActiveFeed::Primary;
    }
}
