import Foundation

struct DocumentDataV2: ASN1Decodable {
    static let hasExtensionMarker = true
    static let optionalFieldCount = 1

    var token: TokenTypeV2?
    var ticket: TicketDetailDataV2

    init() {
        self.ticket = TicketDetailDataV2()
    }

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        let presence = try decoder.decodePresenceBitmap(count: Self.optionalFieldCount)

        if presence[0] { token = try TokenTypeV2(from: &decoder) }

        ticket = try TicketDetailDataV2(from: &decoder)

        if hasExtensions {
            let numExt = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt where extPresence[i] {
                try decoder.skipOpenType()
            }
        }
    }
}

extension DocumentDataV2: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        try encoder.encodePresenceBitmap([token != nil])
        if let token { try token.encode(to: &encoder) }
        try ticket.encode(to: &encoder)
    }
}
