import Foundation

/// Service type (V2: 4 values, NO extension marker)
enum ServiceTypeV2: Int, ASN1Decodable {
    case seat = 0
    case couchette = 1
    case berth = 2
    case carCarriage = 3

    static let hasExtensionMarker = false
    static let rootValueCount = 4

    init(from decoder: inout UPERDecoder) throws {
        let rawValue = try decoder.decodeEnumerated(
            rootCount: Self.rootValueCount,
            hasExtensionMarker: Self.hasExtensionMarker
        )
        guard let value = ServiceTypeV2(rawValue: rawValue) else {
            throw UICBarcodeError.asn1DecodingError("Invalid ServiceTypeV2: \(rawValue)")
        }
        self = value
    }
}
