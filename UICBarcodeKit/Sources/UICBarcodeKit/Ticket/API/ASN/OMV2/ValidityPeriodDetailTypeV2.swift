import Foundation

struct ValidityPeriodDetailTypeV2: ASN1Decodable {
    var validityPeriod: [ValidityPeriodTypeV2]?
    var excludedTimeRange: [TimeRangeTypeV2]?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        // No extension marker
        let presence = try decoder.decodePresenceBitmap(count: 2)

        if presence[0] { validityPeriod = try decoder.decodeSequenceOf() }
        if presence[1] { excludedTimeRange = try decoder.decodeSequenceOf() }
    }
}

extension ValidityPeriodDetailTypeV2: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodePresenceBitmap([
            validityPeriod != nil,
            excludedTimeRange != nil
        ])
        if let v = validityPeriod { try encoder.encodeSequenceOf(v) }
        if let v = excludedTimeRange { try encoder.encodeSequenceOf(v) }
    }
}
