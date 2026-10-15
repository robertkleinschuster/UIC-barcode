import Foundation

public struct ValidityPeriodType: ASN1Decodable {
    public var validFromDay: Int?
    public var validFromTime: Int?
    public var validFromUTCOffset: Int?
    public var validUntilDay: Int?
    public var validUntilTime: Int?
    public var validUntilUTCOffset: Int?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let presence = try decoder.decodePresenceBitmap(count: 6)
        // Field 0: validFromDay (-367..700, default 0)
        if presence[0] { validFromDay = try decoder.decodeConstrainedInt(min: -367, max: 700) } else { validFromDay = 0 }
        if presence[1] { validFromTime = try decoder.decodeConstrainedInt(min: 0, max: 1439) }
        if presence[2] { validFromUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }
        // Field 3: validUntilDay (-1..500, default 0)
        if presence[3] { validUntilDay = try decoder.decodeConstrainedInt(min: -1, max: 500) } else { validUntilDay = 0 }
        if presence[4] { validUntilTime = try decoder.decodeConstrainedInt(min: 0, max: 1439) }
        if presence[5] { validUntilUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }
    }
}

extension ValidityPeriodType: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
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

        if validFromDayPresent { try encoder.encodeConstrainedInt(validFromDay!, min: -367, max: 700) }
        if let v = validFromTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1439) }
        if let v = validFromUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if validUntilDayPresent { try encoder.encodeConstrainedInt(validUntilDay!, min: -1, max: 500) }
        if let v = validUntilTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1439) }
        if let v = validUntilUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
    }
}
