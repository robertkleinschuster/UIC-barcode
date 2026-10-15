import Foundation

// MARK: - Customer Card Data

struct CustomerCardDataV2: ASN1Decodable {
    var customer: TravelerTypeV2?
    var cardIdIA5: String?
    var cardIdNum: Int?
    var validFromYear: Int?
    var validFromDay: Int?
    var validUntilYear: Int?
    var validUntilDay: Int?
    var classCode: TravelClassTypeV2?
    var cardType: Int?
    var cardTypeDescr: String?
    var customerStatus: Int?
    var customerStatusDescr: String?
    var includedServices: [Int]?
    var extensionData: ExtensionDataV2?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 14 optional fields; no mandatory fields, no @Asn1Default in V2
        let presence = try decoder.decodePresenceBitmap(count: 14)
        var idx = 0

        if presence[idx] { customer = try TravelerTypeV2(from: &decoder) }; idx += 1
        if presence[idx] { cardIdIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { cardIdNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { validFromYear = try decoder.decodeConstrainedInt(min: 2016, max: 2269) }; idx += 1
        // V2: validFromDay constraint 0..700 (not 0..370)
        if presence[idx] { validFromDay = try decoder.decodeConstrainedInt(min: 0, max: 700) }; idx += 1
        // V2: validUntilYear is @Asn1Optional only (no @Asn1Default)
        if presence[idx] { validUntilYear = try decoder.decodeConstrainedInt(min: 0, max: 250) }; idx += 1
        if presence[idx] { validUntilDay = try decoder.decodeConstrainedInt(min: 0, max: 370) }; idx += 1
        if presence[idx] { classCode = try TravelClassTypeV2(from: &decoder) }; idx += 1
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
        if presence[idx] { extensionData = try ExtensionDataV2(from: &decoder) }

        if hasExtensions {
            let numExt = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt where extPresence[i] {
                try decoder.skipOpenType()
            }
        }
    }
}

// MARK: - CustomerCardDataV2 Encoding

extension CustomerCardDataV2: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        // V2: 14 optional fields; no mandatory fields, no @Asn1Default
        try encoder.encodePresenceBitmap([
            customer != nil,
            cardIdIA5 != nil,
            cardIdNum != nil,
            validFromYear != nil,
            validFromDay != nil,
            validUntilYear != nil,
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
        if let v = validFromYear { try encoder.encodeConstrainedInt(v, min: 2016, max: 2269) }
        // V2: validFromDay constraint 0..700 (not 0..370)
        if let v = validFromDay { try encoder.encodeConstrainedInt(v, min: 0, max: 700) }
        // V2: validUntilYear constraint 0..250
        if let v = validUntilYear { try encoder.encodeConstrainedInt(v, min: 0, max: 250) }
        if let v = validUntilDay { try encoder.encodeConstrainedInt(v, min: 0, max: 370) }
        if let v = classCode { try encoder.encodeEnumerated(v.rawValue, rootCount: TravelClassTypeV2.rootValueCount, hasExtensionMarker: TravelClassTypeV2.hasExtensionMarker) }
        if let v = cardType { try encoder.encodeConstrainedInt(v, min: 0, max: 1000) }
        if let v = cardTypeDescr { try encoder.encodeUTF8String(v) }
        if let v = customerStatus { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = customerStatusDescr { try encoder.encodeIA5String(v) }
        if let v = includedServices {
            try encoder.encodeLengthDeterminant(v.count)
            for num in v { try encoder.encodeUnconstrainedInteger(Int64(num)) }
        }
        if let v = extensionData { try v.encode(to: &encoder) }
    }
}
