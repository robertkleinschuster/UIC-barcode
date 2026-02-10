import Foundation

/// Hemisphere for latitude (V1: 2 values, NO extension marker)
enum HemisphereLatitudeTypeV1: Int, ASN1Decodable {
    case north = 0
    case south = 1

    static let hasExtensionMarker = false
    static let rootValueCount = 2

    init(from decoder: inout UPERDecoder) throws {
        let rawValue = try decoder.decodeEnumerated(
            rootCount: Self.rootValueCount,
            hasExtensionMarker: Self.hasExtensionMarker
        )
        guard let value = HemisphereLatitudeTypeV1(rawValue: rawValue) else {
            throw UICBarcodeError.asn1DecodingError("Invalid HemisphereLatitudeTypeV1: \(rawValue)")
        }
        self = value
    }
}
