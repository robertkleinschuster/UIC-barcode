import Foundation

struct TicketLinkTypeV2: ASN1Decodable {
    static let hasExtensionMarker = true
    static let optionalFieldCount = 8

    var referenceIA5: String?
    var referenceNum: Int?
    var issuerName: String?
    var issuerPNR: String?
    var productOwnerNum: Int?
    var productOwnerIA5: String?
    var ticketType: TicketTypeV2?
    var linkMode: LinkModeV2?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        let presence = try decoder.decodePresenceBitmap(count: Self.optionalFieldCount)

        if presence[0] { referenceIA5 = try decoder.decodeIA5String() }
        if presence[1] { referenceNum = Int(try decoder.decodeUnconstrainedInteger()) }
        if presence[2] { issuerName = try decoder.decodeUTF8String() }
        if presence[3] { issuerPNR = try decoder.decodeIA5String() }
        if presence[4] { productOwnerNum = try decoder.decodeConstrainedInt(min: 1, max: 32000) }
        if presence[5] { productOwnerIA5 = try decoder.decodeIA5String() }
        if presence[6] {
            ticketType = try TicketTypeV2(from: &decoder)
        } else {
            ticketType = .openTicket
        }
        if presence[7] {
            linkMode = try LinkModeV2(from: &decoder)
        } else {
            linkMode = .issuedTogether
        }

        if hasExtensions {
            let numExt = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt where extPresence[i] {
                try decoder.skipOpenType()
            }
        }
    }
}

extension TicketLinkTypeV2: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        let ticketTypePresent = ticketType != nil && ticketType != .openTicket
        let linkModePresent = linkMode != nil && linkMode != .issuedTogether
        try encoder.encodePresenceBitmap([
            referenceIA5 != nil,
            referenceNum != nil,
            issuerName != nil,
            issuerPNR != nil,
            productOwnerNum != nil,
            productOwnerIA5 != nil,
            ticketTypePresent,
            linkModePresent
        ])
        if let v = referenceIA5 { try encoder.encodeIA5String(v) }
        if let v = referenceNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = issuerName { try encoder.encodeUTF8String(v) }
        if let v = issuerPNR { try encoder.encodeIA5String(v) }
        if let v = productOwnerNum { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        if let v = productOwnerIA5 { try encoder.encodeIA5String(v) }
        if ticketTypePresent { try encoder.encodeEnumerated(ticketType!.rawValue, rootCount: TicketTypeV2.rootValueCount, hasExtensionMarker: TicketTypeV2.hasExtensionMarker) }
        if linkModePresent { try encoder.encodeEnumerated(linkMode!.rawValue, rootCount: LinkModeV2.rootValueCount, hasExtensionMarker: LinkModeV2.hasExtensionMarker) }
    }
}
