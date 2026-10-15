import Foundation

/// Hemisphere for longitude (V1: 2 values, NO extension marker)
enum HemisphereLongitudeTypeV1: Int, ASN1Decodable {
    case east = 0
    case west = 1

    static let hasExtensionMarker = false
    static let rootValueCount = 2

    init(from decoder: inout UPERDecoder) throws {
        let rawValue = try decoder.decodeEnumerated(
            rootCount: Self.rootValueCount,
            hasExtensionMarker: Self.hasExtensionMarker
        )
        guard let value = HemisphereLongitudeTypeV1(rawValue: rawValue) else {
            throw UICBarcodeError.asn1DecodingError("Invalid HemisphereLongitudeTypeV1: \(rawValue)")
        }
        self = value
    }
}
