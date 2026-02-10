import Foundation

// MARK: - IssuingDataV2

struct IssuingDataV2: ASN1Decodable {
    static let hasExtensionMarker = true
    static let optionalFieldCount = 14

    var securityProviderNum: Int?
    var securityProviderIA5: String?
    var issuerNum: Int?
    var issuerIA5: String?
    var issuingYear: Int = 2024
    var issuingDay: Int = 1
    var issuingTime: Int?
    var issuerName: String?
    var specimen: Bool = false
    var securePaperTicket: Bool = false
    var activated: Bool = true
    var currency: String?
    var currencyFract: Int?
    var issuerPNR: String?
    var extensionData: ExtensionDataV2?
    var issuedOnTrainNum: Int?
    var issuedOnTrainIA5: String?
    var issuedOnLine: Int?
    var pointOfSale: GeoCoordinateTypeV2?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()

        // 14 optional fields:
        // 0: securityProviderNum, 1: securityProviderIA5, 2: issuerNum, 3: issuerIA5,
        // 4: issuingTime, 5: issuerName, 6: currency(default), 7: currencyFract(default),
        // 8: issuerPNR, 9: extensionData, 10: issuedOnTrainNum, 11: issuedOnTrainIA5,
        // 12: issuedOnLine, 13: pointOfSale
        let presence = try decoder.decodePresenceBitmap(count: Self.optionalFieldCount)

        if presence[0] { securityProviderNum = try decoder.decodeConstrainedInt(min: 1, max: 32000) }
        if presence[1] { securityProviderIA5 = try decoder.decodeIA5String() }
        if presence[2] { issuerNum = try decoder.decodeConstrainedInt(min: 1, max: 32000) }
        if presence[3] { issuerIA5 = try decoder.decodeIA5String() }

        issuingYear = try decoder.decodeConstrainedInt(min: 2016, max: 2269)
        issuingDay = try decoder.decodeConstrainedInt(min: 1, max: 366)

        if presence[4] {
            issuingTime = try decoder.decodeConstrainedInt(min: 0, max: 1440)
        }

        if presence[5] { issuerName = try decoder.decodeUTF8String() }

        specimen = try decoder.decodeBoolean()
        securePaperTicket = try decoder.decodeBoolean()
        activated = try decoder.decodeBoolean()

        if presence[6] {
            currency = try decoder.decodeIA5String(constraint: ASN1StringConstraint(type: .ia5String, fixedLength: 3))
        } else {
            currency = "EUR"
        }

        if presence[7] {
            currencyFract = try decoder.decodeConstrainedInt(min: 1, max: 3)
        } else {
            currencyFract = 2
        }

        if presence[8] { issuerPNR = try decoder.decodeIA5String() }
        if presence[9] { extensionData = try ExtensionDataV2(from: &decoder) }
        if presence[10] { issuedOnTrainNum = Int(try decoder.decodeUnconstrainedInteger()) }
        if presence[11] { issuedOnTrainIA5 = try decoder.decodeIA5String() }
        if presence[12] { issuedOnLine = Int(try decoder.decodeUnconstrainedInteger()) }
        if presence[13] { pointOfSale = try GeoCoordinateTypeV2(from: &decoder) }

        if hasExtensions {
            let numExt = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt where extPresence[i] {
                try decoder.skipOpenType()
            }
        }
    }

    func getIssuingDate() -> Date? {
        var components = DateComponents()
        components.year = issuingYear
        components.day = issuingDay
        components.timeZone = TimeZone(identifier: "UTC")

        if let time = issuingTime {
            components.hour = time / 60
            components.minute = time % 60
        }

        let calendar = Calendar(identifier: .gregorian)
        return calendar.date(from: components)
    }
}

// MARK: - Encoding

extension IssuingDataV2: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        let currencyPresent = currency != nil && currency != "EUR"
        let currencyFractPresent = currencyFract != nil && currencyFract != 2
        try encoder.encodePresenceBitmap([
            securityProviderNum != nil,
            securityProviderIA5 != nil,
            issuerNum != nil,
            issuerIA5 != nil,
            issuingTime != nil,
            issuerName != nil,
            currencyPresent,
            currencyFractPresent,
            issuerPNR != nil,
            extensionData != nil,
            issuedOnTrainNum != nil,
            issuedOnTrainIA5 != nil,
            issuedOnLine != nil,
            pointOfSale != nil
        ])
        if let v = securityProviderNum { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        if let v = securityProviderIA5 { try encoder.encodeIA5String(v) }
        if let v = issuerNum { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        if let v = issuerIA5 { try encoder.encodeIA5String(v) }
        try encoder.encodeConstrainedInt(issuingYear, min: 2016, max: 2269)
        try encoder.encodeConstrainedInt(issuingDay, min: 1, max: 366)
        if let v = issuingTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1440) }
        if let v = issuerName { try encoder.encodeUTF8String(v) }
        try encoder.encodeBoolean(specimen)
        try encoder.encodeBoolean(securePaperTicket)
        try encoder.encodeBoolean(activated)
        if currencyPresent { try encoder.encodeIA5String(currency!, constraint: ASN1StringConstraint(type: .ia5String, fixedLength: 3)) }
        if currencyFractPresent { try encoder.encodeConstrainedInt(currencyFract!, min: 1, max: 3) }
        if let v = issuerPNR { try encoder.encodeIA5String(v) }
        if let v = extensionData { try v.encode(to: &encoder) }
        if let v = issuedOnTrainNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = issuedOnTrainIA5 { try encoder.encodeIA5String(v) }
        if let v = issuedOnLine { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = pointOfSale { try v.encode(to: &encoder) }
    }
}
