import Foundation

/// Customer status type
public struct CustomerStatusType: ASN1Decodable {
    public var statusProviderNum: Int?
    public var statusProviderIA5: String?
    public var customerStatus: Int?
    public var customerStatusDescr: String?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let presence = try decoder.decodePresenceBitmap(count: 4)

        if presence[0] { statusProviderNum = try decoder.decodeConstrainedInt(min: 1, max: 32000) }
        if presence[1] { statusProviderIA5 = try decoder.decodeIA5String() }
        if presence[2] { customerStatus = Int(try decoder.decodeUnconstrainedInteger()) }
        if presence[3] { customerStatusDescr = try decoder.decodeIA5String() }  // IA5String in Java
    }
}

extension CustomerStatusType: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
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
