import Foundation

/// VAT detail type
public struct VatDetailType: ASN1Decodable {
    public var country: Int = 0          // MANDATORY
    public var percentage: Int = 0       // MANDATORY
    public var amount: Int?
    public var vatId: String?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let presence = try decoder.decodePresenceBitmap(count: 2)

        country = try decoder.decodeConstrainedInt(min: 1, max: 999)
        percentage = try decoder.decodeConstrainedInt(min: 0, max: 999)
        if presence[0] { amount = Int(try decoder.decodeUnconstrainedInteger()) }
        if presence[1] { vatId = try decoder.decodeIA5String() }
    }
}

extension VatDetailType: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodePresenceBitmap([
            amount != nil,
            vatId != nil
        ])

        try encoder.encodeConstrainedInt(country, min: 1, max: 999)
        try encoder.encodeConstrainedInt(percentage, min: 0, max: 999)
        if let v = amount { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = vatId { try encoder.encodeIA5String(v) }
    }
}
