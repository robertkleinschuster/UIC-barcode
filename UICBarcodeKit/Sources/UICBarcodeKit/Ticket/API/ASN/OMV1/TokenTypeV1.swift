import Foundation

struct TokenTypeV1: ASN1Decodable {
    var tokenProviderNum: Int?
    var tokenProviderIA5: String?
    var tokenSpecification: String?
    var token: Data = Data()

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        // No extension marker (Java has @Sequence only, no @HasExtensionMarker)
        // 3 optional fields; token is mandatory
        let presence = try decoder.decodePresenceBitmap(count: 3)

        if presence[0] { tokenProviderNum = Int(try decoder.decodeUnconstrainedInteger()) }
        if presence[1] { tokenProviderIA5 = try decoder.decodeIA5String() }
        if presence[2] { tokenSpecification = try decoder.decodeIA5String() }

        token = try decoder.decodeOctetString()
    }
}

extension TokenTypeV1: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodePresenceBitmap([
            tokenProviderNum != nil,
            tokenProviderIA5 != nil,
            tokenSpecification != nil
        ])
        if let v = tokenProviderNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = tokenProviderIA5 { try encoder.encodeIA5String(v) }
        if let v = tokenSpecification { try encoder.encodeIA5String(v) }
        try encoder.encodeOctetString(token)
    }
}
