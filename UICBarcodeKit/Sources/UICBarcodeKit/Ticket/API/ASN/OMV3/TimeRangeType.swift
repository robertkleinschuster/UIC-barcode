import Foundation

public struct TimeRangeType: ASN1Decodable {
    public var fromTime: Int
    public var untilTime: Int

    public init(fromTime: Int = 0, untilTime: Int = 0) {
        self.fromTime = fromTime
        self.untilTime = untilTime
    }

    public init(from decoder: inout UPERDecoder) throws {
        fromTime = try decoder.decodeConstrainedInt(min: 0, max: 1439)
        untilTime = try decoder.decodeConstrainedInt(min: 0, max: 1439)
    }
}

extension TimeRangeType: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeConstrainedInt(fromTime, min: 0, max: 1439)
        try encoder.encodeConstrainedInt(untilTime, min: 0, max: 1439)
    }
}
