import Foundation

/// Passenger type (V2: 8 root values, @HasExtensionMarker)
enum PassengerTypeV2: Int, ASN1Decodable {
    case adult = 0
    case senior = 1
    case child = 2
    case youth = 3
    case dog = 4
    case bicycle = 5
    case freeAddonPassenger = 6
    case freeAddonChild = 7

    static let hasExtensionMarker = true
    static let rootValueCount = 8

    init(from decoder: inout UPERDecoder) throws {
        let rawValue = try decoder.decodeEnumerated(
            rootCount: Self.rootValueCount,
            hasExtensionMarker: Self.hasExtensionMarker
        )
        guard let value = PassengerTypeV2(rawValue: rawValue) else {
            throw UICBarcodeError.asn1DecodingError("Invalid PassengerTypeV2: \(rawValue)")
        }
        self = value
    }
}
