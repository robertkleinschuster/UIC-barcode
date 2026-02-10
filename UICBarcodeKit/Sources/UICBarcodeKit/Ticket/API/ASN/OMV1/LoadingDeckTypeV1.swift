import Foundation

/// Loading deck type (V1: 3 values, NO extension marker)
enum LoadingDeckTypeV1: Int, ASN1Decodable {
    case unspecified = 0
    case upper = 1
    case lower = 2

    static let hasExtensionMarker = false
    static let rootValueCount = 3

    init(from decoder: inout UPERDecoder) throws {
        let rawValue = try decoder.decodeEnumerated(
            rootCount: Self.rootValueCount,
            hasExtensionMarker: Self.hasExtensionMarker
        )
        guard let value = LoadingDeckTypeV1(rawValue: rawValue) else {
            throw UICBarcodeError.asn1DecodingError("Invalid LoadingDeckTypeV1: \(rawValue)")
        }
        self = value
    }
}
