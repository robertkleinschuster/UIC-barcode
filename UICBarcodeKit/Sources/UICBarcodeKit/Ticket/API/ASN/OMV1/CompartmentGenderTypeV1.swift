import Foundation

/// Compartment gender type (V1: 5 root values, @HasExtensionMarker)
enum CompartmentGenderTypeV1: Int, ASN1Decodable {
    case unspecified = 0
    case family = 1
    case female = 2
    case male = 3
    case mixed = 4

    static let hasExtensionMarker = true
    static let rootValueCount = 5

    init(from decoder: inout UPERDecoder) throws {
        let rawValue = try decoder.decodeEnumerated(
            rootCount: Self.rootValueCount,
            hasExtensionMarker: Self.hasExtensionMarker
        )
        guard let value = CompartmentGenderTypeV1(rawValue: rawValue) else {
            throw UICBarcodeError.asn1DecodingError("Invalid CompartmentGenderTypeV1: \(rawValue)")
        }
        self = value
    }
}
