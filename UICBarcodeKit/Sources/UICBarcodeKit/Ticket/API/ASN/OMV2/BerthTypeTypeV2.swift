import Foundation

/// Berth type (V2: 6 values, NO extension marker)
enum BerthTypeTypeV2: Int, ASN1Decodable {
    case single = 0
    case special = 1
    case double_ = 2
    case t2 = 3
    case t3 = 4
    case t4 = 5

    static let hasExtensionMarker = false
    static let rootValueCount = 6

    init(from decoder: inout UPERDecoder) throws {
        let rawValue = try decoder.decodeEnumerated(
            rootCount: Self.rootValueCount,
            hasExtensionMarker: Self.hasExtensionMarker
        )
        guard let value = BerthTypeTypeV2(rawValue: rawValue) else {
            throw UICBarcodeError.asn1DecodingError("Invalid BerthTypeTypeV2: \(rawValue)")
        }
        self = value
    }
}
