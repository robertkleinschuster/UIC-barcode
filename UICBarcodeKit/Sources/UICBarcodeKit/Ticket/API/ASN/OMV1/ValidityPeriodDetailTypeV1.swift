import Foundation

struct ValidityPeriodDetailTypeV1: ASN1Decodable {
    var validityPeriod: [ValidityPeriodTypeV1]?
    var excludedTimeRange: [TimeRangeTypeV1]?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        // No extension marker
        let presence = try decoder.decodePresenceBitmap(count: 2)

        if presence[0] { validityPeriod = try decoder.decodeSequenceOf() }
        if presence[1] { excludedTimeRange = try decoder.decodeSequenceOf() }
    }
}

// MARK: - ValidityPeriodDetailTypeV1 Encoding

extension ValidityPeriodDetailTypeV1: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodePresenceBitmap([
            validityPeriod != nil,
            excludedTimeRange != nil
        ])
        if let arr = validityPeriod { try encoder.encodeSequenceOf(arr) }
        if let arr = excludedTimeRange { try encoder.encodeSequenceOf(arr) }
    }
}
