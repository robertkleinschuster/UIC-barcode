import Foundation

/// Compartment position type (V2: 3 values, NO extension marker)
enum CompartmentPositionTypeV2: Int, ASN1Decodable {
    case unspecified = 0
    case upperLevel = 1
    case lowerLevel = 2

    static let hasExtensionMarker = false
    static let rootValueCount = 3

    init(from decoder: inout UPERDecoder) throws {
        let rawValue = try decoder.decodeEnumerated(
            rootCount: Self.rootValueCount,
            hasExtensionMarker: Self.hasExtensionMarker
        )
        guard let value = CompartmentPositionTypeV2(rawValue: rawValue) else {
            throw UICBarcodeError.asn1DecodingError("Invalid CompartmentPositionTypeV2: \(rawValue)")
        }
        self = value
    }
}
