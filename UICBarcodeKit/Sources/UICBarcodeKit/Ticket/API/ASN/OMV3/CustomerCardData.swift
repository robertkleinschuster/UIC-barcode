import Foundation

// MARK: - Customer Card Data

/// Customer card data - matches Java CustomerCardData.java
public struct CustomerCardData: ASN1Decodable {
    // Field 0: customer (TravelerType, optional)
    public var customer: TravelerType?
    // Field 1: cardIdIA5 (IA5String, optional)
    public var cardIdIA5: String?
    // Field 2: cardIdNum (BigInteger, optional)
    public var cardIdNum: Int?
    // Field 3: validFromYear (2016..2269, MANDATORY)
    public var validFromYear: Int = 2024
    // Field 4: validFromDay (0..500, optional)
    public var validFromDay: Int?
    // Field 5: validUntilYear (0..250, optional) - offset from validFromYear
    public var validUntilYear: Int?
    // Field 6: validUntilDay (0..500, optional)
    public var validUntilDay: Int?
    // Field 7: classCode (TravelClassType, optional)
    public var classCode: TravelClassType?
    // Field 8: cardType (1..1000, optional)
    public var cardType: Int?
    // Field 9: cardTypeDescr (UTF8String, optional)
    public var cardTypeDescr: String?
    // Field 10: customerStatus (BigInteger, optional)
    public var customerStatus: Int?
    // Field 11: customerStatusDescr (IA5String, optional)
    public var customerStatusDescr: String?
    // Field 12: includedServices (SEQUENCE OF INTEGER, optional)
    public var includedServices: [Int]?
    // Field 13: extension (ExtensionData, optional)
    public var extensionData: ExtensionData?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 13 optional fields: 0,1,2,4,5,6,7,8,9,10,11,12,13 (field 3 is mandatory)
        let presence = try decoder.decodePresenceBitmap(count: 13)
        var idx = 0

        // Field 0: customer (optional)
        if presence[idx] { customer = try TravelerType(from: &decoder) }; idx += 1
        // Field 1: cardIdIA5 (optional)
        if presence[idx] { cardIdIA5 = try decoder.decodeIA5String() }; idx += 1
        // Field 2: cardIdNum (optional)
        if presence[idx] { cardIdNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        // Field 3: validFromYear (MANDATORY)
        validFromYear = try decoder.decodeConstrainedInt(min: 2016, max: 2269)
        // Field 4: validFromDay (optional)
        if presence[idx] { validFromDay = try decoder.decodeConstrainedInt(min: 0, max: 500) }; idx += 1
        // Field 5: validUntilYear (optional, default 0) - range 0..250
        if presence[idx] { validUntilYear = try decoder.decodeConstrainedInt(min: 0, max: 250) } else { validUntilYear = 0 }; idx += 1
        // Field 6: validUntilDay (optional)
        if presence[idx] { validUntilDay = try decoder.decodeConstrainedInt(min: 0, max: 500) }; idx += 1
        // Field 7: classCode (optional)
        if presence[idx] {
            let value = try decoder.decodeEnumerated(rootCount: 12, hasExtensionMarker: true)
            classCode = TravelClassType(rawValue: value)
        }; idx += 1
        // Field 8: cardType (optional)
        if presence[idx] { cardType = try decoder.decodeConstrainedInt(min: 1, max: 1000) }; idx += 1
        // Field 9: cardTypeDescr (optional)
        if presence[idx] { cardTypeDescr = try decoder.decodeUTF8String() }; idx += 1
        // Field 10: customerStatus (optional)
        if presence[idx] { customerStatus = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        // Field 11: customerStatusDescr (optional) - IA5String in Java!
        if presence[idx] { customerStatusDescr = try decoder.decodeIA5String() }; idx += 1
        // Field 12: includedServices (optional)
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            includedServices = []
            for _ in 0..<count {
                includedServices?.append(Int(try decoder.decodeUnconstrainedInteger()))
            }
        }; idx += 1
        // Field 13: extension (optional)
        if presence[idx] { extensionData = try ExtensionData(from: &decoder) }

        if hasExtensions {
            let numExt = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt where extPresence[i] {
                try decoder.skipOpenType()
            }
        }
    }
}

// MARK: - CustomerCardData Encoding

extension CustomerCardData: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)

        let validUntilYearPresent = validUntilYear != nil && validUntilYear != 0

        try encoder.encodePresenceBitmap([
            customer != nil,
            cardIdIA5 != nil,
            cardIdNum != nil,
            validFromDay != nil,
            validUntilYearPresent,
            validUntilDay != nil,
            classCode != nil,
            cardType != nil,
            cardTypeDescr != nil,
            customerStatus != nil,
            customerStatusDescr != nil,
            includedServices != nil,
            extensionData != nil
        ])

        if let v = customer { try v.encode(to: &encoder) }
        if let v = cardIdIA5 { try encoder.encodeIA5String(v) }
        if let v = cardIdNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        try encoder.encodeConstrainedInt(validFromYear, min: 2016, max: 2269)
        if let v = validFromDay { try encoder.encodeConstrainedInt(v, min: 0, max: 500) }
        if validUntilYearPresent { try encoder.encodeConstrainedInt(validUntilYear!, min: 0, max: 250) }
        if let v = validUntilDay { try encoder.encodeConstrainedInt(v, min: 0, max: 500) }
        if let v = classCode { try encoder.encodeEnumerated(v.rawValue, rootCount: 12, hasExtensionMarker: true) }
        if let v = cardType { try encoder.encodeConstrainedInt(v, min: 1, max: 1000) }
        if let v = cardTypeDescr { try encoder.encodeUTF8String(v) }
        if let v = customerStatus { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = customerStatusDescr { try encoder.encodeIA5String(v) }
        if let arr = includedServices {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        }
        if let v = extensionData { try v.encode(to: &encoder) }
    }
}
