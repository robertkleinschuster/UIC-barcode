import Foundation

/// Geographic unit type (V1: 5 values, NO extension marker)
enum GeoUnitTypeV1: Int, ASN1Decodable {
    case microDegree = 0
    case tenthmilliDegree = 1
    case milliDegree = 2
    case centiDegree = 3
    case deciDegree = 4

    static let hasExtensionMarker = false
    static let rootValueCount = 5

    init(from decoder: inout UPERDecoder) throws {
        let rawValue = try decoder.decodeEnumerated(
            rootCount: Self.rootValueCount,
            hasExtensionMarker: Self.hasExtensionMarker
        )
        guard let value = GeoUnitTypeV1(rawValue: rawValue) else {
            throw UICBarcodeError.asn1DecodingError("Invalid GeoUnitTypeV1: \(rawValue)")
        }
        self = value
    }
}
