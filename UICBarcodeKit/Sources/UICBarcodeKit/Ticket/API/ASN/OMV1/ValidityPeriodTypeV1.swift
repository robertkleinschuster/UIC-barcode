import Foundation

struct ValidityPeriodTypeV1: ASN1Decodable {
    var validFromDay: Int?
    var validFromTime: Int?
    var validFromUTCOffset: Int?
    var validUntilDay: Int?
    var validUntilTime: Int?
    var validUntilUTCOffset: Int?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        // No extension marker
        // 6 optional+default fields (validFromDay(D), validUntilDay(D) = 2 defaults + 4 optional)
        let presence = try decoder.decodePresenceBitmap(count: 6)

        if presence[0] { validFromDay = try decoder.decodeConstrainedInt(min: -1, max: 700) } else { validFromDay = 0 }
        if presence[1] { validFromTime = try decoder.decodeConstrainedInt(min: 0, max: 1440) }
        if presence[2] { validFromUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }
        if presence[3] { validUntilDay = try decoder.decodeConstrainedInt(min: 0, max: 370) } else { validUntilDay = 0 }
        if presence[4] { validUntilTime = try decoder.decodeConstrainedInt(min: 0, max: 1440) }
        if presence[5] { validUntilUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }
    }
}

// MARK: - ValidityPeriodTypeV1 Encoding

extension ValidityPeriodTypeV1: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        let validFromDayPresent = validFromDay != nil && validFromDay != 0
        let validUntilDayPresent = validUntilDay != nil && validUntilDay != 0
        try encoder.encodePresenceBitmap([
            validFromDayPresent,
            validFromTime != nil,
            validFromUTCOffset != nil,
            validUntilDayPresent,
            validUntilTime != nil,
            validUntilUTCOffset != nil
        ])
        if validFromDayPresent { try encoder.encodeConstrainedInt(validFromDay!, min: -1, max: 700) }
        if let v = validFromTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1440) }
        if let v = validFromUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if validUntilDayPresent { try encoder.encodeConstrainedInt(validUntilDay!, min: 0, max: 370) }
        if let v = validUntilTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1440) }
        if let v = validUntilUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
    }
}
