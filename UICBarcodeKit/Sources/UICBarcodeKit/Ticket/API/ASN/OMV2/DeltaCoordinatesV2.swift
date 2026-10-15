import Foundation

struct DeltaCoordinatesV2: ASN1Decodable {
    var longitude: Int = 0
    var latitude: Int = 0

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        longitude = Int(try decoder.decodeUnconstrainedInteger())
        latitude = Int(try decoder.decodeUnconstrainedInteger())
    }
}

extension DeltaCoordinatesV2: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeUnconstrainedInteger(Int64(longitude))
        try encoder.encodeUnconstrainedInteger(Int64(latitude))
    }
}
