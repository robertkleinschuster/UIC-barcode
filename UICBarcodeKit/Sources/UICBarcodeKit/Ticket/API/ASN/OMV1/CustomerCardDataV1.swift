import Foundation

// MARK: - Customer Card Data

struct CustomerCardDataV1: ASN1Decodable {
    var customer: TravelerTypeV1?
    var cardIdIA5: String?
    var cardIdNum: Int?
    var validFromYear: Int = 2016
    var validFromDay: Int?
    var validUntilYear: Int?
    var validUntilDay: Int?
    var classCode: TravelClassTypeV1?
    var cardType: Int?
    var cardTypeDescr: String?
    var customerStatus: Int?
    var customerStatusDescr: String?
    var includedServices: [Int]?
    var extensionData: ExtensionDataV1?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 13 optional+default fields; validFromYear is mandatory
        // customer, cardIdIA5, cardIdNum = 3 optional
        // validFromDay = 1 optional
        // validUntilYear(D) = 1 default
        // validUntilDay, classCode, cardType, cardTypeDescr, customerStatus, customerStatusDescr = 6 optional
        // includedServices, extensionData = 2 optional
        // Total = 13 optional+default
        let presence = try decoder.decodePresenceBitmap(count: 13)
        var idx = 0

        if presence[idx] { customer = try TravelerTypeV1(from: &decoder) }; idx += 1
        if presence[idx] { cardIdIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { cardIdNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1

        // validFromYear is MANDATORY
        validFromYear = try decoder.decodeConstrainedInt(min: 2016, max: 2269)

        if presence[idx] { validFromDay = try decoder.decodeConstrainedInt(min: 0, max: 370) }; idx += 1
        if presence[idx] { validUntilYear = try decoder.decodeConstrainedInt(min: 0, max: 250) } else { validUntilYear = 0 }; idx += 1
        if presence[idx] { validUntilDay = try decoder.decodeConstrainedInt(min: 0, max: 370) }; idx += 1
        if presence[idx] { classCode = try TravelClassTypeV1(from: &decoder) }; idx += 1
        if presence[idx] { cardType = try decoder.decodeConstrainedInt(min: 0, max: 1000) }; idx += 1
        if presence[idx] { cardTypeDescr = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] { customerStatus = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { customerStatusDescr = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            includedServices = []
            for _ in 0..<count {
                includedServices?.append(Int(try decoder.decodeUnconstrainedInteger()))
            }
        }; idx += 1
        if presence[idx] { extensionData = try ExtensionDataV1(from: &decoder) }

        if hasExtensions {
            let numExt = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt where extPresence[i] {
                try decoder.skipOpenType()
            }
        }
    }
}

// MARK: - CustomerCardDataV1 Encoding

extension CustomerCardDataV1: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
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
        if let v = validFromDay { try encoder.encodeConstrainedInt(v, min: 0, max: 370) }
        if validUntilYearPresent { try encoder.encodeConstrainedInt(validUntilYear!, min: 0, max: 250) }
        if let v = validUntilDay { try encoder.encodeConstrainedInt(v, min: 0, max: 370) }
        if let v = classCode { try encoder.encodeEnumerated(v.rawValue, rootCount: TravelClassTypeV1.rootValueCount, hasExtensionMarker: TravelClassTypeV1.hasExtensionMarker) }
        if let v = cardType { try encoder.encodeConstrainedInt(v, min: 0, max: 1000) }
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
