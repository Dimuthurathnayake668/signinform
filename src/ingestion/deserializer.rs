// PREDATOR 2026 - Phase 1
// SCRUM-22: JSON + Binary SBE deserializer for market ticks and orderbook snapshots.

use std::fmt;

#[derive(Debug, Clone, PartialEq)]
pub struct MarketTickRaw {
    pub seq_no: u64,
    pub exchange_ts_ns: u64,
    pub symbol: String,
    pub price: f64,
    pub volume: f64,
    pub checksum: u32,
}

#[derive(Debug, Clone, PartialEq)]
pub struct MarketOrderbookSnap {
    pub seq_no: u64,
    pub exchange_ts_ns: u64,
    pub symbol: String,
    pub best_bid: f64,
    pub best_ask: f64,
    pub bid_size: f64,
    pub ask_size: f64,
    pub checksum: u32,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum WireFormat {
    Json,
    BinarySbe,
}

#[derive(Debug)]
pub enum DeserializeError {
    Utf8,
    JsonMissingField(&'static str),
    JsonParse(&'static str),
    BinaryTooShort,
    UnsupportedMessageType,
}

impl fmt::Display for DeserializeError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Utf8 => write!(f, "invalid UTF-8 payload"),
            Self::JsonMissingField(name) => write!(f, "missing JSON field: {name}"),
            Self::JsonParse(name) => write!(f, "invalid JSON field value: {name}"),
            Self::BinaryTooShort => write!(f, "binary payload too short"),
            Self::UnsupportedMessageType => write!(f, "unsupported message type"),
        }
    }
}

fn parse_json_number<'a>(doc: &'a str, key: &'static str) -> Result<f64, DeserializeError> {
    let needle = format!("\"{key}\":");
    let idx = doc.find(&needle).ok_or(DeserializeError::JsonMissingField(key))? + needle.len();
    let tail = &doc[idx..];
    let end = tail.find([',', '}']).unwrap_or(tail.len());
    let raw = tail[..end].trim();
    raw.parse::<f64>().map_err(|_| DeserializeError::JsonParse(key))
}

fn parse_json_u64(doc: &str, key: &'static str) -> Result<u64, DeserializeError> {
    let v = parse_json_number(doc, key)?;
    if v < 0.0 {
        return Err(DeserializeError::JsonParse(key));
    }
    Ok(v as u64)
}

fn parse_json_string(doc: &str, key: &'static str) -> Result<String, DeserializeError> {
    let needle = format!("\"{key}\":\"");
    let idx = doc.find(&needle).ok_or(DeserializeError::JsonMissingField(key))? + needle.len();
    let tail = &doc[idx..];
    let end = tail.find('"').ok_or(DeserializeError::JsonParse(key))?;
    Ok(tail[..end].to_string())
}

pub fn deserialize_tick_json(payload: &[u8]) -> Result<MarketTickRaw, DeserializeError> {
    let doc = std::str::from_utf8(payload).map_err(|_| DeserializeError::Utf8)?;
    Ok(MarketTickRaw {
        seq_no: parse_json_u64(doc, "seq_no")?,
        exchange_ts_ns: parse_json_u64(doc, "exchange_ts_ns")?,
        symbol: parse_json_string(doc, "symbol")?,
        price: parse_json_number(doc, "price")?,
        volume: parse_json_number(doc, "volume")?,
        checksum: parse_json_u64(doc, "checksum")? as u32,
    })
}

pub fn deserialize_orderbook_json(payload: &[u8]) -> Result<MarketOrderbookSnap, DeserializeError> {
    let doc = std::str::from_utf8(payload).map_err(|_| DeserializeError::Utf8)?;
    Ok(MarketOrderbookSnap {
        seq_no: parse_json_u64(doc, "seq_no")?,
        exchange_ts_ns: parse_json_u64(doc, "exchange_ts_ns")?,
        symbol: parse_json_string(doc, "symbol")?,
        best_bid: parse_json_number(doc, "best_bid")?,
        best_ask: parse_json_number(doc, "best_ask")?,
        bid_size: parse_json_number(doc, "bid_size")?,
        ask_size: parse_json_number(doc, "ask_size")?,
        checksum: parse_json_u64(doc, "checksum")? as u32,
    })
}

// Minimal SBE-like layout used by this implementation:
// [u8 msg_type][u64 seq_no][u64 ts][f64 p1][f64 p2][f64 p3][f64 p4][u32 checksum]
// msg_type=1 tick => p1=price, p2=volume
// msg_type=2 orderbook => p1=best_bid, p2=best_ask, p3=bid_size, p4=ask_size
pub fn deserialize_binary_sbe(payload: &[u8], symbol: &str) -> Result<(Option<MarketTickRaw>, Option<MarketOrderbookSnap>), DeserializeError> {
    const MIN_LEN: usize = 1 + 8 + 8 + 8 + 8 + 8 + 8 + 4;
    if payload.len() < MIN_LEN {
        return Err(DeserializeError::BinaryTooShort);
    }

    let msg_type = payload[0];
    let mut o = 1usize;
    let rd_u64 = |buf: &[u8], off: &mut usize| {
        let mut arr = [0u8; 8];
        arr.copy_from_slice(&buf[*off..*off + 8]);
        *off += 8;
        u64::from_le_bytes(arr)
    };
    let rd_f64 = |buf: &[u8], off: &mut usize| {
        let mut arr = [0u8; 8];
        arr.copy_from_slice(&buf[*off..*off + 8]);
        *off += 8;
        f64::from_le_bytes(arr)
    };

    let seq_no = rd_u64(payload, &mut o);
    let ts_ns = rd_u64(payload, &mut o);
    let p1 = rd_f64(payload, &mut o);
    let p2 = rd_f64(payload, &mut o);
    let p3 = rd_f64(payload, &mut o);
    let p4 = rd_f64(payload, &mut o);
    let mut csum = [0u8; 4];
    csum.copy_from_slice(&payload[o..o + 4]);
    let checksum = u32::from_le_bytes(csum);

    match msg_type {
        1 => Ok((Some(MarketTickRaw {
            seq_no,
            exchange_ts_ns: ts_ns,
            symbol: symbol.to_string(),
            price: p1,
            volume: p2,
            checksum,
        }), None)),
        2 => Ok((None, Some(MarketOrderbookSnap {
            seq_no,
            exchange_ts_ns: ts_ns,
            symbol: symbol.to_string(),
            best_bid: p1,
            best_ask: p2,
            bid_size: p3,
            ask_size: p4,
            checksum,
        }))),
        _ => Err(DeserializeError::UnsupportedMessageType),
    }
}
