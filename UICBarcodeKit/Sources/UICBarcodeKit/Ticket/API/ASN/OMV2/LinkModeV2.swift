import Foundation

/// Link mode for ticket links (V2: 2 root values, @HasExtensionMarker)
enum LinkModeV2: Int, ASN1Decodable {
    case issuedTogether = 0
    case onlyValidInCombination = 1

    static let hasExtensionMarker = true
    static let rootValueCount = 2

    init(from decoder: inout UPERDecoder) throws {
        let rawValue = try decoder.decodeEnumerated(
            rootCount: Self.rootValueCount,
            hasExtensionMarker: Self.hasExtensionMarker
        )
        guard let value = LinkModeV2(rawValue: rawValue) else {
            throw UICBarcodeError.asn1DecodingError("Invalid LinkModeV2: \(rawValue)")
        }
        self = value
    }
}
