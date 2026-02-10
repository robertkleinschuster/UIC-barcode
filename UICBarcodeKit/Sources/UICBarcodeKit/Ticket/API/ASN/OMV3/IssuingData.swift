import Foundation

// MARK: - Issuing Data

/// Information about ticket issuance
public struct IssuingData: ASN1Decodable {
    public static let hasExtensionMarker = true
    // Note: In Java, fields 15-18 are NOT marked @IsExtension, so they're in root
    public static let optionalFieldCount = 13

    // Fields (order matters for UPER)
    public var securityProviderNum: Int?        // 0: optional, 1..32000
    public var securityProviderIA5: String?     // 1: optional, IA5String
    public var issuerNum: Int?                  // 2: optional, 1..32000
    public var issuerIA5: String?               // 3: optional, IA5String
    public var issuingYear: Int = 2024          // 4: mandatory, 2016..2269
    public var issuingDay: Int = 1              // 5: mandatory, 1..366
    public var issuingTime: Int = 0             // 6: mandatory, 0..1439
    public var issuerName: String?              // 7: optional, UTF8String
    public var specimen: Bool = false           // 8: mandatory
    public var securePaperTicket: Bool = false  // 9: mandatory
    public var activated: Bool = true           // 10: mandatory
    public var currency: String?                // 11: optional, fixed 3 chars, default "EUR"
    public var currencyFract: Int?              // 12: optional, 1..3, default 2
    public var issuerPNR: String?               // 13: optional, IA5String
    public var extensionData: ExtensionData?    // 14: optional
    public var issuedOnTrainNum: Int?           // 15: optional (NOT extension in Java!)
    public var issuedOnTrainIA5: String?        // 16: optional (NOT extension in Java!)
    public var issuedOnLine: Int?               // 17: optional (NOT extension in Java!)
    public var pointOfSale: GeoCoordinateType?  // 18: optional (NOT extension in Java!)

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()

        // Presence bitmap for 13 optional fields in root:
        // 0: securityProviderNum, 1: securityProviderIA5, 2: issuerNum, 3: issuerIA5,
        // 7: issuerName, 11: currency, 12: currencyFract, 13: issuerPNR, 14: extensionData,
        // 15: issuedOnTrainNum, 16: issuedOnTrainIA5, 17: issuedOnLine, 18: pointOfSale
        let presence = try decoder.decodePresenceBitmap(count: 13)

        // Field 0: securityProviderNum (optional)
        if presence[0] {
            securityProviderNum = try decoder.decodeConstrainedInt(min: 1, max: 32000)
        }

        // Field 1: securityProviderIA5 (optional)
        if presence[1] {
            securityProviderIA5 = try decoder.decodeIA5String()
        }

        // Field 2: issuerNum (optional)
        if presence[2] {
            issuerNum = try decoder.decodeConstrainedInt(min: 1, max: 32000)
        }

        // Field 3: issuerIA5 (optional)
        if presence[3] {
            issuerIA5 = try decoder.decodeIA5String()
        }

        // Field 4: issuingYear (mandatory)
        issuingYear = try decoder.decodeConstrainedInt(min: 2016, max: 2269)

        // Field 5: issuingDay (mandatory)
        issuingDay = try decoder.decodeConstrainedInt(min: 1, max: 366)

        // Field 6: issuingTime (mandatory)
        issuingTime = try decoder.decodeConstrainedInt(min: 0, max: 1439)

        // Field 7: issuerName (optional)
        if presence[4] {
            issuerName = try decoder.decodeUTF8String()
        }

        // Field 8: specimen (mandatory)
        specimen = try decoder.decodeBoolean()

        // Field 9: securePaperTicket (mandatory)
        securePaperTicket = try decoder.decodeBoolean()

        // Field 10: activated (mandatory)
        activated = try decoder.decodeBoolean()

        // Field 11: currency (optional, fixed 3 chars, default "EUR")
        if presence[5] {
            currency = try decoder.decodeIA5String(constraint: ASN1StringConstraint(type: .ia5String, fixedLength: 3))
        } else {
            currency = "EUR"
        }

        // Field 12: currencyFract (optional, default 2)
        if presence[6] {
            currencyFract = try decoder.decodeConstrainedInt(min: 1, max: 3)
        } else {
            currencyFract = 2
        }

        // Field 13: issuerPNR (optional)
        if presence[7] {
            issuerPNR = try decoder.decodeIA5String()
        }

        // Field 14: extensionData (optional)
        if presence[8] {
            extensionData = try ExtensionData(from: &decoder)
        }

        // Field 15: issuedOnTrainNum (optional, in root!)
        if presence[9] {
            issuedOnTrainNum = Int(try decoder.decodeUnconstrainedInteger())
        }

        // Field 16: issuedOnTrainIA5 (optional, in root!)
        if presence[10] {
            issuedOnTrainIA5 = try decoder.decodeIA5String()
        }

        // Field 17: issuedOnLine (optional, in root!)
        if presence[11] {
            issuedOnLine = Int(try decoder.decodeUnconstrainedInteger())
        }

        // Field 18: pointOfSale (optional, in root!)
        if presence[12] {
            pointOfSale = try GeoCoordinateType(from: &decoder)
        }

        // Handle extensions (if the class has @HasExtensionMarker and extensions are present)
        if hasExtensions {
            let numExtensions = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExtensions)

            // Skip any unknown extension fields
            for i in 0..<numExtensions {
                if extPresence[i] {
                    try decoder.skipOpenType()
                }
            }
        }
    }

    /// Get the issuing date as a Date object
    public func getIssuingDate() -> Date? {
        var components = DateComponents()
        components.year = issuingYear
        components.day = issuingDay
        components.hour = issuingTime / 60
        components.minute = issuingTime % 60
        components.timeZone = TimeZone(identifier: "UTC")

        let calendar = Calendar(identifier: .gregorian)
        return calendar.date(from: components)
    }
}

// MARK: - Encoding

extension IssuingData: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        try encoder.encodePresenceBitmap([
            securityProviderNum != nil,
            securityProviderIA5 != nil,
            issuerNum != nil,
            issuerIA5 != nil,
            issuerName != nil,
            currency != nil && currency != "EUR",
            currencyFract != nil && currencyFract != 2,
            issuerPNR != nil,
            extensionData != nil,
            issuedOnTrainNum != nil,
            issuedOnTrainIA5 != nil,
            issuedOnLine != nil,
            pointOfSale != nil
        ])
        if let securityProviderNum {
            try encoder.encodeConstrainedInt(securityProviderNum, min: 1, max: 32000)
        }
        if let securityProviderIA5 {
            try encoder.encodeIA5String(securityProviderIA5)
        }
        if let issuerNum {
            try encoder.encodeConstrainedInt(issuerNum, min: 1, max: 32000)
        }
        if let issuerIA5 {
            try encoder.encodeIA5String(issuerIA5)
        }
        try encoder.encodeConstrainedInt(issuingYear, min: 2016, max: 2269)
        try encoder.encodeConstrainedInt(issuingDay, min: 1, max: 366)
        try encoder.encodeConstrainedInt(issuingTime, min: 0, max: 1439)
        if let issuerName {
            try encoder.encodeUTF8String(issuerName)
        }
        try encoder.encodeBoolean(specimen)
        try encoder.encodeBoolean(securePaperTicket)
        try encoder.encodeBoolean(activated)
        if let currency, currency != "EUR" {
            try encoder.encodeIA5String(currency, constraint: ASN1StringConstraint(type: .ia5String, fixedLength: 3))
        }
        if let currencyFract, currencyFract != 2 {
            try encoder.encodeConstrainedInt(currencyFract, min: 1, max: 3)
        }
        if let issuerPNR {
            try encoder.encodeIA5String(issuerPNR)
        }
        if let extensionData {
            try extensionData.encode(to: &encoder)
        }
        if let issuedOnTrainNum {
            try encoder.encodeUnconstrainedInteger(Int64(issuedOnTrainNum))
        }
        if let issuedOnTrainIA5 {
            try encoder.encodeIA5String(issuedOnTrainIA5)
        }
        if let issuedOnLine {
            try encoder.encodeUnconstrainedInteger(Int64(issuedOnLine))
        }
        if let pointOfSale {
            try pointOfSale.encode(to: &encoder)
        }
    }
}
