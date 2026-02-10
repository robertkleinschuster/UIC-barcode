import Foundation

struct CardReferenceTypeV2: ASN1Decodable {
    static let hasExtensionMarker = true
    static let optionalFieldCount = 10

    var cardIssuerNum: Int?
    var cardIssuerIA5: String?
    var cardIdNum: Int?
    var cardIdIA5: String?
    var cardName: String?
    var cardType: Int?
    var leadingCardIdNum: Int?
    var leadingCardIdIA5: String?
    var trailingCardIdNum: Int?
    var trailingCardIdIA5: String?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        let presence = try decoder.decodePresenceBitmap(count: Self.optionalFieldCount)

        // V2: cardIssuerNum is unconstrained (no @IntRange in Java omv2)
        if presence[0] { cardIssuerNum = Int(try decoder.decodeUnconstrainedInteger()) }
        if presence[1] { cardIssuerIA5 = try decoder.decodeIA5String() }
        if presence[2] { cardIdNum = Int(try decoder.decodeUnconstrainedInteger()) }
        if presence[3] { cardIdIA5 = try decoder.decodeIA5String() }
        if presence[4] { cardName = try decoder.decodeUTF8String() }
        if presence[5] { cardType = Int(try decoder.decodeUnconstrainedInteger()) }
        if presence[6] { leadingCardIdNum = Int(try decoder.decodeUnconstrainedInteger()) }
        if presence[7] { leadingCardIdIA5 = try decoder.decodeIA5String() }
        if presence[8] { trailingCardIdNum = Int(try decoder.decodeUnconstrainedInteger()) }
        if presence[9] { trailingCardIdIA5 = try decoder.decodeIA5String() }

        if hasExtensions {
            let numExt = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt where extPresence[i] {
                try decoder.skipOpenType()
            }
        }
    }
}

extension CardReferenceTypeV2: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        try encoder.encodePresenceBitmap([
            cardIssuerNum != nil,
            cardIssuerIA5 != nil,
            cardIdNum != nil,
            cardIdIA5 != nil,
            cardName != nil,
            cardType != nil,
            leadingCardIdNum != nil,
            leadingCardIdIA5 != nil,
            trailingCardIdNum != nil,
            trailingCardIdIA5 != nil
        ])
        // V2: cardIssuerNum is unconstrained (no @IntRange)
        if let v = cardIssuerNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = cardIssuerIA5 { try encoder.encodeIA5String(v) }
        if let v = cardIdNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = cardIdIA5 { try encoder.encodeIA5String(v) }
        if let v = cardName { try encoder.encodeUTF8String(v) }
        if let v = cardType { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = leadingCardIdNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = leadingCardIdIA5 { try encoder.encodeIA5String(v) }
        if let v = trailingCardIdNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = trailingCardIdIA5 { try encoder.encodeIA5String(v) }
    }
}
