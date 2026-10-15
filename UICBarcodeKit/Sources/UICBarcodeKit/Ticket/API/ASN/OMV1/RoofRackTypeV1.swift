import Foundation

/// Roof rack type (V1: 9 root values, @HasExtensionMarker)
/// V1/V2 names differ from V3
enum RoofRackTypeV1: Int, ASN1Decodable {
    case norack = 0
    case roofRailing = 1
    case luggageRack = 2
    case skiRack = 3
    case boxRack = 4
    case rackWithOneBox = 5
    case rackWithTwoBoxes = 6
    case bicycleRack = 7
    case otherRack = 8

    static let hasExtensionMarker = true
    static let rootValueCount = 9

    init(from decoder: inout UPERDecoder) throws {
        let rawValue = try decoder.decodeEnumerated(
            rootCount: Self.rootValueCount,
            hasExtensionMarker: Self.hasExtensionMarker
        )
        guard let value = RoofRackTypeV1(rawValue: rawValue) else {
            throw UICBarcodeError.asn1DecodingError("Invalid RoofRackTypeV1: \(rawValue)")
        }
        self = value
    }
}
