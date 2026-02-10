import Foundation

/// Geographic coordinate system type (V1: 2 values, NO extension marker)
enum GeoCoordinateSystemTypeV1: Int, ASN1Decodable {
    case wgs84 = 0
    case grs80 = 1

    static let hasExtensionMarker = false
    static let rootValueCount = 2

    init(from decoder: inout UPERDecoder) throws {
        let rawValue = try decoder.decodeEnumerated(
            rootCount: Self.rootValueCount,
            hasExtensionMarker: Self.hasExtensionMarker
        )
        guard let value = GeoCoordinateSystemTypeV1(rawValue: rawValue) else {
            throw UICBarcodeError.asn1DecodingError("Invalid GeoCoordinateSystemTypeV1: \(rawValue)")
        }
        self = value
    }
}
