import Foundation

/// Code table type for station codes (V2: 5 values, NO extension marker)
enum CodeTableTypeV2: Int, ASN1Decodable {
    case stationUIC = 0
    case stationUICReservation = 1
    case stationERA = 2
    case localCarrierStationCodeTable = 3
    case proprietaryIssuerStationCodeTable = 4

    static let hasExtensionMarker = false
    static let rootValueCount = 5

    init(from decoder: inout UPERDecoder) throws {
        let rawValue = try decoder.decodeEnumerated(
            rootCount: Self.rootValueCount,
            hasExtensionMarker: Self.hasExtensionMarker
        )
        guard let value = CodeTableTypeV2(rawValue: rawValue) else {
            throw UICBarcodeError.asn1DecodingError("Invalid CodeTableTypeV2: \(rawValue)")
        }
        self = value
    }
}
