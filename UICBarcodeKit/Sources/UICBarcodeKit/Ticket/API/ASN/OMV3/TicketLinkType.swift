import Foundation

/// Ticket link type
public struct TicketLinkType: ASN1Decodable {
    public var referenceIA5: String?      // Field 0 in Java
    public var referenceNum: Int?         // Field 1 in Java
    public var issuerName: String?
    public var issuerPNR: String?
    public var productOwnerNum: Int?
    public var productOwnerIA5: String?
    public var ticketType: TicketType?
    public var linkMode: LinkMode?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        let presence = try decoder.decodePresenceBitmap(count: 8)

        if presence[0] { referenceIA5 = try decoder.decodeIA5String() }
        if presence[1] { referenceNum = Int(try decoder.decodeUnconstrainedInteger()) }
        if presence[2] { issuerName = try decoder.decodeUTF8String() }
        if presence[3] { issuerPNR = try decoder.decodeIA5String() }
        if presence[4] { productOwnerNum = try decoder.decodeConstrainedInt(min: 1, max: 32000) }
        if presence[5] { productOwnerIA5 = try decoder.decodeIA5String() }
        if presence[6] {
            let value = try decoder.decodeEnumerated(rootCount: 4, hasExtensionMarker: true)
            ticketType = TicketType(rawValue: value)
        } else {
            ticketType = .openTicket
        }
        if presence[7] {
            let value = try decoder.decodeEnumerated(rootCount: 2, hasExtensionMarker: true)
            linkMode = LinkMode(rawValue: value)
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

extension TicketLinkType: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
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
        if ticketTypePresent { try encoder.encodeEnumerated(ticketType!.rawValue, rootCount: 4, hasExtensionMarker: true) }
        if linkModePresent { try encoder.encodeEnumerated(linkMode!.rawValue, rootCount: 2, hasExtensionMarker: true) }
    }
}
