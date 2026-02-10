import Foundation

/// Price type (V2: 4 values, NO extension marker)
enum PriceTypeTypeV2: Int, ASN1Decodable {
    case noPrice = 0
    case reservationFee = 1
    case supplement = 2
    case travelPrice = 3

    static let hasExtensionMarker = false
    static let rootValueCount = 4

    init(from decoder: inout UPERDecoder) throws {
        let rawValue = try decoder.decodeEnumerated(
            rootCount: Self.rootValueCount,
            hasExtensionMarker: Self.hasExtensionMarker
        )
        guard let value = PriceTypeTypeV2(rawValue: rawValue) else {
            throw UICBarcodeError.asn1DecodingError("Invalid PriceTypeTypeV2: \(rawValue)")
        }
        self = value
    }
}
