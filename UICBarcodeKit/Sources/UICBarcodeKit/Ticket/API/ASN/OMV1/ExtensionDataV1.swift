import Foundation

struct ExtensionDataV1: ASN1Decodable {
    var extensionId: String = ""
    var extensionData: Data = Data()

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        extensionId = try decoder.decodeIA5String()
        extensionData = try decoder.decodeOctetString()
    }
}

extension ExtensionDataV1: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeIA5String(extensionId)
        try encoder.encodeOctetString(extensionData)
    }
}
