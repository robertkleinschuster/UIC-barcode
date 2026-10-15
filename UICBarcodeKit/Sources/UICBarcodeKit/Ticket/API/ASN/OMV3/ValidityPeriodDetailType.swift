import Foundation

public struct ValidityPeriodDetailType: ASN1Decodable {
    public var validityPeriod: [ValidityPeriodType]?
    public var excludedTimeRange: [TimeRangeType]?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let presence = try decoder.decodePresenceBitmap(count: 2)
        if presence[0] { validityPeriod = try decoder.decodeSequenceOf() }
        if presence[1] { excludedTimeRange = try decoder.decodeSequenceOf() }
    }
}

extension ValidityPeriodDetailType: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodePresenceBitmap([
            validityPeriod != nil,
            excludedTimeRange != nil
        ])

        if let arr = validityPeriod { try encoder.encodeSequenceOf(arr) }
        if let arr = excludedTimeRange { try encoder.encodeSequenceOf(arr) }
    }
}
