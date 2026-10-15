import Foundation

struct VatDetailTypeV2: ASN1Decodable {
    var country: Int = 0
    var percentage: Int = 0
    var amount: Int?
    var vatId: String?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        // No extension marker
        let presence = try decoder.decodePresenceBitmap(count: 2)

        // country is MANDATORY
        country = try decoder.decodeConstrainedInt(min: 1, max: 999)
        // percentage is MANDATORY
        percentage = try decoder.decodeConstrainedInt(min: 0, max: 999)

        if presence[0] { amount = Int(try decoder.decodeUnconstrainedInteger()) }
        if presence[1] { vatId = try decoder.decodeIA5String() }
    }
}

extension VatDetailTypeV2: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodePresenceBitmap([
            amount != nil,
            vatId != nil
        ])
        // country is MANDATORY
        try encoder.encodeConstrainedInt(country, min: 1, max: 999)
        // percentage is MANDATORY
        try encoder.encodeConstrainedInt(percentage, min: 0, max: 999)
        if let v = amount { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = vatId { try encoder.encodeIA5String(v) }
    }
}
