import Foundation

struct CustomerStatusTypeV1: ASN1Decodable {
    var statusProviderNum: Int?
    var statusProviderIA5: String?
    var customerStatus: Int?
    var customerStatusDescr: String?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        // No extension marker (Java has @Sequence only, no @HasExtensionMarker)
        // All 4 fields are @Asn1Optional
        let presence = try decoder.decodePresenceBitmap(count: 4)

        if presence[0] { statusProviderNum = try decoder.decodeConstrainedInt(min: 1, max: 32000) }
        if presence[1] { statusProviderIA5 = try decoder.decodeIA5String() }
        if presence[2] { customerStatus = Int(try decoder.decodeUnconstrainedInteger()) }
        if presence[3] { customerStatusDescr = try decoder.decodeIA5String() }
    }
}

extension CustomerStatusTypeV1: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodePresenceBitmap([
            statusProviderNum != nil,
            statusProviderIA5 != nil,
            customerStatus != nil,
            customerStatusDescr != nil
        ])
        if let v = statusProviderNum { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        if let v = statusProviderIA5 { try encoder.encodeIA5String(v) }
        if let v = customerStatus { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = customerStatusDescr { try encoder.encodeIA5String(v) }
    }
}
