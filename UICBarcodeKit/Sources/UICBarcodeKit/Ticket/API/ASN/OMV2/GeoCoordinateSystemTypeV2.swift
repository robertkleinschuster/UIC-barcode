import Foundation

/// Geographic coordinate system type (V2: 2 values, NO extension marker)
enum GeoCoordinateSystemTypeV2: Int, ASN1Decodable {
    case wgs84 = 0
    case grs80 = 1

    static let hasExtensionMarker = false
    static let rootValueCount = 2

    init(from decoder: inout UPERDecoder) throws {
        let rawValue = try decoder.decodeEnumerated(
            rootCount: Self.rootValueCount,
            hasExtensionMarker: Self.hasExtensionMarker
        )
        guard let value = GeoCoordinateSystemTypeV2(rawValue: rawValue) else {
            throw UICBarcodeError.asn1DecodingError("Invalid GeoCoordinateSystemTypeV2: \(rawValue)")
        }
        self = value
    }
}
