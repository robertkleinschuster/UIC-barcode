import Foundation

/// Gender type (V1: 4 root values, @HasExtensionMarker)
enum GenderTypeV1: Int, ASN1Decodable {
    case unspecified = 0
    case female = 1
    case male = 2
    case other = 3

    static let hasExtensionMarker = true
    static let rootValueCount = 4

    init(from decoder: inout UPERDecoder) throws {
        let rawValue = try decoder.decodeEnumerated(
            rootCount: Self.rootValueCount,
            hasExtensionMarker: Self.hasExtensionMarker
        )
        guard let value = GenderTypeV1(rawValue: rawValue) else {
            throw UICBarcodeError.asn1DecodingError("Invalid GenderTypeV1: \(rawValue)")
        }
        self = value
    }
}
