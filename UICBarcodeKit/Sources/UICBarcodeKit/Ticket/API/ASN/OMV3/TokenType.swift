import Foundation

/// Token type for security tokens
/// In Java: no @HasExtensionMarker, token is MANDATORY
public struct TokenType: ASN1Decodable {
    public var tokenProviderNum: Int?        // Field 0: optional
    public var tokenProviderIA5: String?     // Field 1: optional
    public var tokenSpecification: String?   // Field 2: optional
    public var token: Data = Data()          // Field 4: MANDATORY (no @Asn1Optional in Java)

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        // No extension marker in Java TokenType
        // 3 presence bits for optional fields 0, 1, 2
        let presence = try decoder.decodePresenceBitmap(count: 3)

        if presence[0] { tokenProviderNum = Int(try decoder.decodeUnconstrainedInteger()) }
        if presence[1] { tokenProviderIA5 = try decoder.decodeIA5String() }
        if presence[2] { tokenSpecification = try decoder.decodeIA5String() }

        // token is MANDATORY - always decode it
        token = try decoder.decodeOctetString()
    }
}

extension TokenType: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodePresenceBitmap([
            tokenProviderNum != nil,
            tokenProviderIA5 != nil,
            tokenSpecification != nil
        ])
        if let tokenProviderNum { try encoder.encodeUnconstrainedInteger(Int64(tokenProviderNum)) }
        if let tokenProviderIA5 { try encoder.encodeIA5String(tokenProviderIA5) }
        if let tokenSpecification { try encoder.encodeIA5String(tokenSpecification) }
        try encoder.encodeOctetString(token)
    }
}
