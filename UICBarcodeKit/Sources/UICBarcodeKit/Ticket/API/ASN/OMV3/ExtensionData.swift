import Foundation

/// Generic extension data
public struct ExtensionData: ASN1Decodable {
    public var extensionId: String = ""
    public var extensionData: Data = Data()

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        extensionId = try decoder.decodeIA5String()
        extensionData = try decoder.decodeOctetString()
    }
}

extension ExtensionData: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeIA5String(extensionId)
        try encoder.encodeOctetString(extensionData)
    }
}
