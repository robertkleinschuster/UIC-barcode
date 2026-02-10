import Foundation

/// Travel class type (V1: 8 root values, @HasExtensionMarker)
enum TravelClassTypeV1: Int, ASN1Decodable {
    case notApplicable = 0
    case first = 1
    case second = 2
    case tourist = 3
    case comfort = 4
    case premium = 5
    case business = 6
    case all = 7

    static let hasExtensionMarker = true
    static let rootValueCount = 8

    init(from decoder: inout UPERDecoder) throws {
        let rawValue = try decoder.decodeEnumerated(
            rootCount: Self.rootValueCount,
            hasExtensionMarker: Self.hasExtensionMarker
        )
        guard let value = TravelClassTypeV1(rawValue: rawValue) else {
            throw UICBarcodeError.asn1DecodingError("Invalid TravelClassTypeV1: \(rawValue)")
        }
        self = value
    }
}
