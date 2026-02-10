import Foundation

/// Dispatches encoding/decoding between version-specific ASN.1 models and the
/// version-independent API representation.
public enum UicRailTicketCoder {

    /// Decode a V3 UicRailTicketData to the version-independent API
    public static func decode(_ ticket: UicRailTicketData) -> SimpleUicRailTicket {
        ASNToAPIDecoderV3.decode(ticket)
    }

    /// Decode a V1 UicRailTicketDataV1 to the version-independent API
    static func decode(_ ticket: UicRailTicketDataV1) -> SimpleUicRailTicket {
        ASNToAPIDecoderV1.decode(ticket)
    }

    /// Decode a V2 UicRailTicketDataV2 to the version-independent API
    static func decode(_ ticket: UicRailTicketDataV2) -> SimpleUicRailTicket {
        ASNToAPIDecoderV2.decode(ticket)
    }

    // MARK: - Encoding (API → ASN.1)

    /// Encode a version-independent API ticket to V3 UicRailTicketData
    public static func encodeV3(_ ticket: UicRailTicket) -> UicRailTicketData {
        APIToASNEncoderV3.encode(ticket)
    }

    /// Encode a version-independent API ticket to V1 UicRailTicketDataV1
    static func encodeV1(_ ticket: UicRailTicket) -> UicRailTicketDataV1 {
        APIToASNEncoderV1.encode(ticket)
    }

    /// Encode a version-independent API ticket to V2 UicRailTicketDataV2
    static func encodeV2(_ ticket: UicRailTicket) -> UicRailTicketDataV2 {
        APIToASNEncoderV2.encode(ticket)
    }
}
