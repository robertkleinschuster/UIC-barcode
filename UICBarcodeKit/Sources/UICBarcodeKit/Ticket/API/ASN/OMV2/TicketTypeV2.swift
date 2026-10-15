import Foundation

/// Ticket type (V2: 4 root values, @HasExtensionMarker)
enum TicketTypeV2: Int, ASN1Decodable {
    case openTicket = 0
    case pass = 1
    case reservation = 2
    case carCarriageReservation = 3

    static let hasExtensionMarker = true
    static let rootValueCount = 4

    init(from decoder: inout UPERDecoder) throws {
        let rawValue = try decoder.decodeEnumerated(
            rootCount: Self.rootValueCount,
            hasExtensionMarker: Self.hasExtensionMarker
        )
        guard let value = TicketTypeV2(rawValue: rawValue) else {
            throw UICBarcodeError.asn1DecodingError("Invalid TicketTypeV2: \(rawValue)")
        }
        self = value
    }
}
