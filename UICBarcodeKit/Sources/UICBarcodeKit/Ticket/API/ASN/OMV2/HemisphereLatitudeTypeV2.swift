import Foundation

/// Hemisphere for latitude (V2: 2 values, NO extension marker)
enum HemisphereLatitudeTypeV2: Int, ASN1Decodable {
    case north = 0
    case south = 1

    static let hasExtensionMarker = false
    static let rootValueCount = 2

    init(from decoder: inout UPERDecoder) throws {
        let rawValue = try decoder.decodeEnumerated(
            rootCount: Self.rootValueCount,
            hasExtensionMarker: Self.hasExtensionMarker
        )
        guard let value = HemisphereLatitudeTypeV2(rawValue: rawValue) else {
            throw UICBarcodeError.asn1DecodingError("Invalid HemisphereLatitudeTypeV2: \(rawValue)")
        }
        self = value
    }
}
