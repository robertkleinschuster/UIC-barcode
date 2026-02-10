import Foundation

/// Card reference type - matches Java CardReferenceType.java (10 optional fields)
public struct CardReferenceType: ASN1Decodable {
    public var cardIssuerNum: Int?       // 0: optional
    public var cardIssuerIA5: String?    // 1: optional, IA5String
    public var cardIdNum: Int?           // 2: optional
    public var cardIdIA5: String?        // 3: optional, IA5String
    public var cardName: String?         // 4: optional, UTF8String
    public var cardType: Int?            // 5: optional
    public var leadingCardIdNum: Int?    // 6: optional
    public var leadingCardIdIA5: String? // 7: optional, IA5String
    public var trailingCardIdNum: Int?   // 8: optional
    public var trailingCardIdIA5: String? // 9: optional, IA5String

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        let presence = try decoder.decodePresenceBitmap(count: 10)

        if presence[0] { cardIssuerNum = try decoder.decodeConstrainedInt(min: 1, max: 32000) }
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

extension CardReferenceType: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
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

        if let v = cardIssuerNum { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
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
