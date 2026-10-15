import Foundation

/// Gender type (V2: 4 root values, @HasExtensionMarker)
enum GenderTypeV2: Int, ASN1Decodable {
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
        guard let value = GenderTypeV2(rawValue: rawValue) else {
            throw UICBarcodeError.asn1DecodingError("Invalid GenderTypeV2: \(rawValue)")
        }
        self = value
    }
}
