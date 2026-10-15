import Foundation

/// Transport document container
/// In Java: token is OPTIONAL, ticket is MANDATORY
public struct DocumentData: ASN1Decodable {
    public var token: TokenType?
    public var ticket: TicketDetailData  // MANDATORY in Java

    public init() {
        self.ticket = TicketDetailData()
    }

    public init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // Only 1 presence bit - for token (ticket is mandatory)
        let presence = try decoder.decodePresenceBitmap(count: 1)

        if presence[0] {
            token = try TokenType(from: &decoder)
        }

        // ticket is MANDATORY - always decode it
        ticket = try TicketDetailData(from: &decoder)

        if hasExtensions {
            let numExt = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt where extPresence[i] {
                try decoder.skipOpenType()
            }
        }
    }
}

extension DocumentData: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        try encoder.encodePresenceBitmap([token != nil])
        if let token { try token.encode(to: &encoder) }
        try ticket.encode(to: &encoder)
    }
}
