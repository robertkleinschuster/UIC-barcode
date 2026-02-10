import Foundation

/// SSB Header (27 bits)
/// Java ref: SsbHeader.java
public struct SSBHeader {
    /// SSB version (4 bits, 0-15)
    public var version: Int = 3

    /// Issuer code (14 bits, 0-9999)
    public var issuer: Int = 0

    /// Key ID (4 bits, 0-15)
    public var keyId: Int = 0

    /// Ticket type code (5 bits)
    public var ticketType: SSBTicketType = .nonUic

    public init() {}

    public init(bitBuffer: BitBuffer) throws {
        version = try bitBuffer.getInteger(at: 0, length: 4)
        issuer = try bitBuffer.getInteger(at: 4, length: 14)
        keyId = try bitBuffer.getInteger(at: 18, length: 4)

        let typeCode = try bitBuffer.getInteger(at: 22, length: 5)
        ticketType = SSBTicketType(rawValue: typeCode) ?? .nonUic
    }
}

// MARK: - SSBHeader Encoding

extension SSBHeader {

    /// Encode header fields into the bit buffer (27 bits at offset 0).
    /// Layout: version(4) + issuer(14) + keyId(4) + ticketType(5)
    func encode(to bitBuffer: inout BitBuffer) throws {
        try bitBuffer.putInteger(version, at: 0, length: 4)
        try bitBuffer.putInteger(issuer, at: 4, length: 14)
        try bitBuffer.putInteger(keyId, at: 18, length: 4)
        try bitBuffer.putInteger(ticketType.rawValue, at: 22, length: 5)
    }
}
