import Foundation

// MARK: - Countermark Data

/// Countermark data - FCB v3: 35 fields (8 optional, 3 mandatory, 9 optional, 1 mandatory, 14 optional = 31 optional bits)
public struct CountermarkData: ASN1Decodable {
    public var referenceIA5: String?
    public var referenceNum: Int?
    public var productOwnerNum: Int?
    public var productOwnerIA5: String?
    public var productIdNum: Int?
    public var productIdIA5: String?
    public var ticketReferenceIA5: String?
    public var ticketReferenceNum: Int?
    public var numberOfCountermark: Int = 0      // MANDATORY in Java (no @Asn1Optional)
    public var totalOfCountermarks: Int = 0      // MANDATORY in Java (no @Asn1Optional)
    public var groupName: String = ""            // MANDATORY in Java (no @Asn1Optional)
    public var stationCodeTable: CodeTableType?
    public var fromStationNum: Int?
    public var fromStationIA5: String?
    public var toStationNum: Int?
    public var toStationIA5: String?
    public var fromStationNameUTF8: String?
    public var toStationNameUTF8: String?
    public var validRegionDesc: String?
    public var validRegion: [RegionalValidityType]?
    public var returnIncluded: Bool = false       // MANDATORY in Java (no @Asn1Optional)
    public var returnDescription: ReturnRouteDescriptionType?
    public var validFromDay: Int?
    public var validFromTime: Int?
    public var validFromUTCOffset: Int?
    public var validUntilDay: Int?
    public var validUntilTime: Int?
    public var validUntilUTCOffset: Int?
    public var classCode: TravelClassType?
    public var carrierNum: [Int]?
    public var carrierIA5: [String]?
    public var includedServiceBrands: [Int]?
    public var excludedServiceBrands: [Int]?
    public var infoText: String?
    public var extensionData: ExtensionData?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 31 optional fields (fields 8,9,10,20 are mandatory = no presence bits)
        let optionalCount = 31
        let presence = try decoder.decodePresenceBitmap(count: optionalCount)
        var idx = 0

        if presence[idx] { referenceIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { referenceNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { productOwnerNum = try decoder.decodeConstrainedInt(min: 1, max: 32000) }; idx += 1
        if presence[idx] { productOwnerIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { productIdNum = try decoder.decodeConstrainedInt(min: 0, max: 65535) }; idx += 1
        if presence[idx] { productIdIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { ticketReferenceIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { ticketReferenceNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        // Field 8: numberOfCountermark is MANDATORY (no presence bit), range 1..200
        numberOfCountermark = try decoder.decodeConstrainedInt(min: 1, max: 200)
        // Field 9: totalOfCountermarks is MANDATORY (no presence bit), range 1..200
        totalOfCountermarks = try decoder.decodeConstrainedInt(min: 1, max: 200)
        // Field 10: groupName is MANDATORY (no presence bit)
        groupName = try decoder.decodeUTF8String()
        if presence[idx] {
            let value = try decoder.decodeEnumerated(rootCount: 5)
            stationCodeTable = CodeTableType(rawValue: value)
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
        // Field 20: returnIncluded is MANDATORY (no presence bit)
        returnIncluded = try decoder.decodeBoolean()
        if presence[idx] { returnDescription = try ReturnRouteDescriptionType(from: &decoder) }; idx += 1
        if presence[idx] { validFromDay = try decoder.decodeConstrainedInt(min: -367, max: 700) } else { validFromDay = 0 }; idx += 1
        if presence[idx] { validFromTime = try decoder.decodeConstrainedInt(min: 0, max: 1439) }; idx += 1
        if presence[idx] { validFromUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }; idx += 1
        if presence[idx] { validUntilDay = try decoder.decodeConstrainedInt(min: -1, max: 500) } else { validUntilDay = 0 }; idx += 1
        if presence[idx] { validUntilTime = try decoder.decodeConstrainedInt(min: 0, max: 1439) }; idx += 1
        if presence[idx] { validUntilUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }; idx += 1
        if presence[idx] {
            let value = try decoder.decodeEnumerated(rootCount: 12, hasExtensionMarker: true)
            classCode = TravelClassType(rawValue: value)
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
                includedServiceBrands?.append(try decoder.decodeConstrainedInt(min: 1, max: 32000))
            }
        }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            excludedServiceBrands = []
            for _ in 0..<count {
                excludedServiceBrands?.append(try decoder.decodeConstrainedInt(min: 1, max: 32000))
            }
        }; idx += 1
        if presence[idx] { infoText = try decoder.decodeUTF8String() }; idx += 1
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

// MARK: - CountermarkData Encoding

extension CountermarkData: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)

        let stationCodeTablePresent = stationCodeTable != nil && stationCodeTable != .stationUIC
        let validFromDayPresent = validFromDay != nil && validFromDay != 0
        let validUntilDayPresent = validUntilDay != nil && validUntilDay != 0
        let classCodePresent = classCode != nil && classCode != .second

        try encoder.encodePresenceBitmap([
            referenceIA5 != nil,
            referenceNum != nil,
            productOwnerNum != nil,
            productOwnerIA5 != nil,
            productIdNum != nil,
            productIdIA5 != nil,
            ticketReferenceIA5 != nil,
            ticketReferenceNum != nil,
            stationCodeTablePresent,
            fromStationNum != nil,
            fromStationIA5 != nil,
            toStationNum != nil,
            toStationIA5 != nil,
            fromStationNameUTF8 != nil,
            toStationNameUTF8 != nil,
            validRegionDesc != nil,
            validRegion != nil,
            returnDescription != nil,
            validFromDayPresent,
            validFromTime != nil,
            validFromUTCOffset != nil,
            validUntilDayPresent,
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
        try encoder.encodeConstrainedInt(numberOfCountermark, min: 1, max: 200)
        try encoder.encodeConstrainedInt(totalOfCountermarks, min: 1, max: 200)
        try encoder.encodeUTF8String(groupName)
        if stationCodeTablePresent { try encoder.encodeEnumerated(stationCodeTable!.rawValue, rootCount: 5) }
        if let v = fromStationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = fromStationIA5 { try encoder.encodeIA5String(v) }
        if let v = toStationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = toStationIA5 { try encoder.encodeIA5String(v) }
        if let v = fromStationNameUTF8 { try encoder.encodeUTF8String(v) }
        if let v = toStationNameUTF8 { try encoder.encodeUTF8String(v) }
        if let v = validRegionDesc { try encoder.encodeUTF8String(v) }
        if let arr = validRegion { try encoder.encodeSequenceOf(arr) }
        try encoder.encodeBoolean(returnIncluded)
        if let v = returnDescription { try v.encode(to: &encoder) }
        if validFromDayPresent { try encoder.encodeConstrainedInt(validFromDay!, min: -367, max: 700) }
        if let v = validFromTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1439) }
        if let v = validFromUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if validUntilDayPresent { try encoder.encodeConstrainedInt(validUntilDay!, min: -1, max: 500) }
        if let v = validUntilTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1439) }
        if let v = validUntilUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if classCodePresent { try encoder.encodeEnumerated(classCode!.rawValue, rootCount: 12, hasExtensionMarker: true) }
        if let arr = carrierNum {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        }
        if let arr = carrierIA5 {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeIA5String(v) }
        }
        if let arr = includedServiceBrands {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        }
        if let arr = excludedServiceBrands {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        }
        if let v = infoText { try encoder.encodeUTF8String(v) }
        if let v = extensionData { try v.encode(to: &encoder) }
    }
}
