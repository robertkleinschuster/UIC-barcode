// FCBVersionEncoder.swift
// Encodes UicRailTicketData (v1/v2/v3) to UPER bytes.

import Foundation

// MARK: - Version Encoder

enum FCBVersionEncoder {

    /// Encode v3 UicRailTicketData to UPER bytes.
    /// - Parameter ticket: The ticket data to encode
    /// - Returns: UPER-encoded bytes
    static func encode(ticket: UicRailTicketData) throws -> Data {
        var encoder = UPEREncoder()
        try ticket.encode(to: &encoder)
        return encoder.toData()
    }

    /// Encode v1 UicRailTicketDataV1 to UPER bytes.
    /// - Parameter ticket: The v1 ticket data to encode
    /// - Returns: UPER-encoded bytes
    static func encode(ticketV1: UicRailTicketDataV1) throws -> Data {
        var encoder = UPEREncoder()
        try ticketV1.encode(to: &encoder)
        return encoder.toData()
    }

    /// Encode v2 UicRailTicketDataV2 to UPER bytes.
    /// - Parameter ticket: The v2 ticket data to encode
    /// - Returns: UPER-encoded bytes
    static func encode(ticketV2: UicRailTicketDataV2) throws -> Data {
        var encoder = UPEREncoder()
        try ticketV2.encode(to: &encoder)
        return encoder.toData()
    }
}
