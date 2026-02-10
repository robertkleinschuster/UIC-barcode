import Foundation

// MARK: - Countermark Data

struct CountermarkDataV2: ASN1Decodable {
    var referenceIA5: String?
    var referenceNum: Int?
    var productOwnerNum: Int?
    var productOwnerIA5: String?
    var productIdNum: Int?
    var productIdIA5: String?
    var ticketReferenceIA5: String?
    var ticketReferenceNum: Int?
    var numberOfCountermark: Int = 1
    var totalOfCountermarks: Int = 1
    var groupName: String = ""
    var stationCodeTable: CodeTableTypeV2?
    var fromStationNum: Int?
    var fromStationIA5: String?
    var toStationNum: Int?
    var toStationIA5: String?
    var fromStationNameUTF8: String?
    var toStationNameUTF8: String?
    var validRegionDesc: String?
    var validRegion: [RegionalValidityTypeV2]?
    var returnIncluded: Bool = false
    var returnDescription: ReturnRouteDescriptionTypeV2?
    var validFromDay: Int?
    var validFromTime: Int?
    var validFromUTCOffset: Int?
    var validUntilDay: Int?
    var validUntilTime: Int?
    var validUntilUTCOffset: Int?
    var classCode: TravelClassTypeV2?
    var carrierNum: [Int]?
    var carrierIA5: [String]?
    var includedServiceBrands: [Int]?
    var excludedServiceBrands: [Int]?
    var infoText: String?
    var extensionData: ExtensionDataV2?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 31 optional+default fields; mandatory: numberOfCountermark, totalOfCountermarks, groupName, returnIncluded
        let presence = try decoder.decodePresenceBitmap(count: 31)
        var idx = 0

        if presence[idx] { referenceIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { referenceNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { productOwnerNum = try decoder.decodeConstrainedInt(min: 1, max: 32000) }; idx += 1
        if presence[idx] { productOwnerIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { productIdNum = try decoder.decodeConstrainedInt(min: 0, max: 65535) }; idx += 1
        if presence[idx] { productIdIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { ticketReferenceIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { ticketReferenceNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1

        // numberOfCountermark is MANDATORY
        numberOfCountermark = try decoder.decodeConstrainedInt(min: 1, max: 200)
        // totalOfCountermarks is MANDATORY
        totalOfCountermarks = try decoder.decodeConstrainedInt(min: 1, max: 200)
        // groupName is MANDATORY
        groupName = try decoder.decodeUTF8String()

        if presence[idx] {
            stationCodeTable = try CodeTableTypeV2(from: &decoder)
        } else {
            stationCodeTable = .stationUIC
        }; idx += 1
        if presence[idx] { fromStationNum = try decoder.decodeConstrainedInt(min: 1, max: 9999999) }; idx += 1
        if presence[idx] { fromStationIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { toStationNum = try decoder.decodeConstrainedInt(min: 1, max: 9999999) }; idx += 1
        if presence[idx] { toStationIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { fromStationNameUTF8 = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] { toStationNameUTF8 = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] { validRegionDesc = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] { validRegion = try decoder.decodeSequenceOf() }; idx += 1

        // returnIncluded is MANDATORY
        returnIncluded = try decoder.decodeBoolean()

        if presence[idx] { returnDescription = try ReturnRouteDescriptionTypeV2(from: &decoder) }; idx += 1
        // V2: validFromDay is @Asn1Optional only (no @Asn1Default)
        if presence[idx] { validFromDay = try decoder.decodeConstrainedInt(min: -1, max: 700) }; idx += 1
        // V2: validFromTime constraint 0..1439
        if presence[idx] { validFromTime = try decoder.decodeConstrainedInt(min: 0, max: 1439) }; idx += 1
        if presence[idx] { validFromUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }; idx += 1
        // V2: validUntilDay is @Asn1Optional only (no @Asn1Default)
        if presence[idx] { validUntilDay = try decoder.decodeConstrainedInt(min: -1, max: 370) }; idx += 1
        // V2: validUntilTime constraint 0..1439
        if presence[idx] { validUntilTime = try decoder.decodeConstrainedInt(min: 0, max: 1439) }; idx += 1
        if presence[idx] { validUntilUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }; idx += 1
        if presence[idx] {
            classCode = try TravelClassTypeV2(from: &decoder)
        } else {
            classCode = .second
        }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            carrierNum = []
            for _ in 0..<count {
                carrierNum?.append(try decoder.decodeConstrainedInt(min: 1, max: 32000))
            }
        }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            carrierIA5 = []
            for _ in 0..<count {
                carrierIA5?.append(try decoder.decodeIA5String())
            }
        }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            includedServiceBrands = []
            for _ in 0..<count {
                includedServiceBrands?.append(try decoder.decodeConstrainedInt(min: 0, max: 32000))
            }
        }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            excludedServiceBrands = []
            for _ in 0..<count {
                excludedServiceBrands?.append(try decoder.decodeConstrainedInt(min: 0, max: 32000))
            }
        }; idx += 1
        if presence[idx] { infoText = try decoder.decodeUTF8String() }; idx += 1
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

// MARK: - Countermark Data Encoding

extension CountermarkDataV2: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        let stationCodeTablePresent = stationCodeTable != nil && stationCodeTable != .stationUIC
        let classCodePresent = classCode != nil && classCode != .second
        // V2: 31 optional+default fields; mandatory: numberOfCountermark, totalOfCountermarks, groupName, returnIncluded
        try encoder.encodePresenceBitmap([
            referenceIA5 != nil,
            referenceNum != nil,
            productOwnerNum != nil,
            productOwnerIA5 != nil,
            productIdNum != nil,
            productIdIA5 != nil,
            ticketReferenceIA5 != nil,
            ticketReferenceNum != nil,
            // numberOfCountermark, totalOfCountermarks, groupName are mandatory
            stationCodeTablePresent,
            fromStationNum != nil,
            fromStationIA5 != nil,
            toStationNum != nil,
            toStationIA5 != nil,
            fromStationNameUTF8 != nil,
            toStationNameUTF8 != nil,
            validRegionDesc != nil,
            validRegion != nil,
            // returnIncluded is mandatory
            returnDescription != nil,
            // V2: validFromDay is @Asn1Optional only (no @Asn1Default)
            validFromDay != nil,
            validFromTime != nil,
            validFromUTCOffset != nil,
            // V2: validUntilDay is @Asn1Optional only (no @Asn1Default)
            validUntilDay != nil,
            validUntilTime != nil,
            validUntilUTCOffset != nil,
            classCodePresent,
            carrierNum != nil,
            carrierIA5 != nil,
            includedServiceBrands != nil,
            excludedServiceBrands != nil,
            infoText != nil,
            extensionData != nil
        ])
        if let v = referenceIA5 { try encoder.encodeIA5String(v) }
        if let v = referenceNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = productOwnerNum { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        if let v = productOwnerIA5 { try encoder.encodeIA5String(v) }
        if let v = productIdNum { try encoder.encodeConstrainedInt(v, min: 0, max: 65535) }
        if let v = productIdIA5 { try encoder.encodeIA5String(v) }
        if let v = ticketReferenceIA5 { try encoder.encodeIA5String(v) }
        if let v = ticketReferenceNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        // MANDATORY fields
        try encoder.encodeConstrainedInt(numberOfCountermark, min: 1, max: 200)
        try encoder.encodeConstrainedInt(totalOfCountermarks, min: 1, max: 200)
        try encoder.encodeUTF8String(groupName)
        if stationCodeTablePresent { try encoder.encodeEnumerated(stationCodeTable!.rawValue, rootCount: CodeTableTypeV2.rootValueCount) }
        if let v = fromStationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = fromStationIA5 { try encoder.encodeIA5String(v) }
        if let v = toStationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = toStationIA5 { try encoder.encodeIA5String(v) }
        if let v = fromStationNameUTF8 { try encoder.encodeUTF8String(v) }
        if let v = toStationNameUTF8 { try encoder.encodeUTF8String(v) }
        if let v = validRegionDesc { try encoder.encodeUTF8String(v) }
        if let v = validRegion { try encoder.encodeSequenceOf(v) }
        // returnIncluded is MANDATORY
        try encoder.encodeBoolean(returnIncluded)
        if let v = returnDescription { try v.encode(to: &encoder) }
        // V2: validFromDay is @Asn1Optional only (no @Asn1Default)
        if let v = validFromDay { try encoder.encodeConstrainedInt(v, min: -1, max: 700) }
        if let v = validFromTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1439) }
        if let v = validFromUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        // V2: validUntilDay is @Asn1Optional only (no @Asn1Default)
        if let v = validUntilDay { try encoder.encodeConstrainedInt(v, min: -1, max: 370) }
        if let v = validUntilTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1439) }
        if let v = validUntilUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if classCodePresent { try encoder.encodeEnumerated(classCode!.rawValue, rootCount: TravelClassTypeV2.rootValueCount, hasExtensionMarker: TravelClassTypeV2.hasExtensionMarker) }
        if let v = carrierNum {
            try encoder.encodeLengthDeterminant(v.count)
            for num in v { try encoder.encodeConstrainedInt(num, min: 1, max: 32000) }
        }
        if let v = carrierIA5 {
            try encoder.encodeLengthDeterminant(v.count)
            for s in v { try encoder.encodeIA5String(s) }
        }
        if let v = includedServiceBrands {
            try encoder.encodeLengthDeterminant(v.count)
            for num in v { try encoder.encodeConstrainedInt(num, min: 0, max: 32000) }
        }
        if let v = excludedServiceBrands {
            try encoder.encodeLengthDeterminant(v.count)
            for num in v { try encoder.encodeConstrainedInt(num, min: 0, max: 32000) }
        }
        if let v = infoText { try encoder.encodeUTF8String(v) }
        if let v = extensionData { try v.encode(to: &encoder) }
    }
}
