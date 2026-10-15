import Foundation

/// Confirmation type for delay (V2: 3 root values, @HasExtensionMarker)
enum ConfirmationTypeTypeV2: Int, ASN1Decodable {
    case trainDelay = 0
    case travelerDelay = 1
    case trainLinkedTicket = 2

    static let hasExtensionMarker = true
    static let rootValueCount = 3

    init(from decoder: inout UPERDecoder) throws {
        let rawValue = try decoder.decodeEnumerated(
            rootCount: Self.rootValueCount,
            hasExtensionMarker: Self.hasExtensionMarker
        )
        guard let value = ConfirmationTypeTypeV2(rawValue: rawValue) else {
            throw UICBarcodeError.asn1DecodingError("Invalid ConfirmationTypeTypeV2: \(rawValue)")
        }
        self = value
    }
}
