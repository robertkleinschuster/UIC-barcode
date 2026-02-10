import Foundation

/// Travel class type (V2: 12 root values, @HasExtensionMarker)
enum TravelClassTypeV2: Int, ASN1Decodable {
    case notApplicable = 0
    case first = 1
    case second = 2
    case tourist = 3
    case comfort = 4
    case premium = 5
    case business = 6
    case all = 7
    case premiumFirst = 8
    case standardFirst = 9
    case premiumSecond = 10
    case standardSecond = 11

    static let hasExtensionMarker = true
    static let rootValueCount = 12

    init(from decoder: inout UPERDecoder) throws {
        let rawValue = try decoder.decodeEnumerated(
            rootCount: Self.rootValueCount,
            hasExtensionMarker: Self.hasExtensionMarker
        )
        guard let value = TravelClassTypeV2(rawValue: rawValue) else {
            throw UICBarcodeError.asn1DecodingError("Invalid TravelClassTypeV2: \(rawValue)")
        }
        self = value
    }
}
