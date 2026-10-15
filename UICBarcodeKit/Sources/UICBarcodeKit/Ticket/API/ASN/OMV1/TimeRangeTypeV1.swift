import Foundation

struct TimeRangeTypeV1: ASN1Decodable {
    var fromTime: Int
    var untilTime: Int

    init(fromTime: Int = 0, untilTime: Int = 0) {
        self.fromTime = fromTime
        self.untilTime = untilTime
    }

    init(from decoder: inout UPERDecoder) throws {
        // No extension marker, no optional fields
        fromTime = try decoder.decodeConstrainedInt(min: 0, max: 1440)
        untilTime = try decoder.decodeConstrainedInt(min: 0, max: 1440)
    }
}

// MARK: - TimeRangeTypeV1 Encoding

extension TimeRangeTypeV1: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeConstrainedInt(fromTime, min: 0, max: 1440)
        try encoder.encodeConstrainedInt(untilTime, min: 0, max: 1440)
    }
}
