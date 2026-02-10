import Foundation

// MARK: - Open Ticket Data

/// Open ticket data (non-reservation) - FCB v3 all 41 fields
/// In Java: returnIncluded (field 8) is MANDATORY
public struct OpenTicketData: ASN1Decodable {
    public var referenceNum: Int?
    public var referenceIA5: String?
    public var productOwnerNum: Int?
    public var productOwnerIA5: String?
    public var productIdNum: Int?
    public var productIdIA5: String?
    public var externalIssuerId: Int?
    public var issuerAutorizationId: Int?
    public var returnIncluded: Bool = false  // MANDATORY in Java
    public var stationCodeTable: CodeTableType?
    public var fromStationNum: Int?
    public var fromStationIA5: String?
    public var toStationNum: Int?
    public var toStationIA5: String?
    public var fromStationNameUTF8: String?
    public var toStationNameUTF8: String?
    public var validRegionDesc: String?
    public var validRegion: [RegionalValidityType]?
    public var returnDescription: ReturnRouteDescriptionType?
    public var validFromDay: Int?
    public var validFromTime: Int?
    public var validFromUTCOffset: Int?
    public var validUntilDay: Int?
    public var validUntilTime: Int?
    public var validUntilUTCOffset: Int?
    public var activatedDay: [Int]?
    public var classCode: TravelClassType?
    public var serviceLevel: String?
    public var carrierNum: [Int]?
    public var carrierIA5: [String]?
    public var includedServiceBrands: [Int]?
    public var excludedServiceBrands: [Int]?
    public var tariffs: [TariffType]?
    public var price: Int?
    public var vatDetails: [VatDetailType]?
    public var infoText: String?
    public var includedAddOns: [IncludedOpenTicketType]?
    public var luggage: LuggageRestrictionType?
    public var includedTransportTypes: [Int]?
    public var excludedTransportTypes: [Int]?
    public var extensionData: ExtensionData?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 40 optional fields (0-7, 9-40); field 8 (returnIncluded) is mandatory
        let presence = try decoder.decodePresenceBitmap(count: 40)
        var idx = 0

        if presence[idx] { referenceNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { referenceIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { productOwnerNum = try decoder.decodeConstrainedInt(min: 1, max: 32000) }; idx += 1
        if presence[idx] { productOwnerIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { productIdNum = try decoder.decodeConstrainedInt(min: 0, max: 65535) }; idx += 1
        if presence[idx] { productIdIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { externalIssuerId = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { issuerAutorizationId = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        // Field 8: returnIncluded is MANDATORY
        returnIncluded = try decoder.decodeBoolean()
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
        if presence[idx] { returnDescription = try ReturnRouteDescriptionType(from: &decoder) }; idx += 1
        if presence[idx] { validFromDay = try decoder.decodeConstrainedInt(min: -367, max: 700) } else { validFromDay = 0 }; idx += 1
        if presence[idx] { validFromTime = try decoder.decodeConstrainedInt(min: 0, max: 1439) }; idx += 1
        if presence[idx] { validFromUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }; idx += 1
        if presence[idx] { validUntilDay = try decoder.decodeConstrainedInt(min: -1, max: 500) } else { validUntilDay = 0 }; idx += 1
        if presence[idx] { validUntilTime = try decoder.decodeConstrainedInt(min: 0, max: 1439) }; idx += 1
        if presence[idx] { validUntilUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            activatedDay = []
            for _ in 0..<count {
                activatedDay?.append(try decoder.decodeConstrainedInt(min: 0, max: 500))
            }
        }; idx += 1
        if presence[idx] {
            let value = try decoder.decodeEnumerated(rootCount: 12, hasExtensionMarker: true)
            classCode = TravelClassType(rawValue: value)
        } else {
            classCode = .second
        }; idx += 1
        if presence[idx] { serviceLevel = try decoder.decodeIA5String(constraint: ASN1StringConstraint(type: .ia5String, minLength: 1, maxLength: 2)) }; idx += 1
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
        if presence[idx] { tariffs = try decoder.decodeSequenceOf() }; idx += 1
        if presence[idx] { price = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { vatDetails = try decoder.decodeSequenceOf() }; idx += 1
        if presence[idx] { infoText = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] { includedAddOns = try decoder.decodeSequenceOf() }; idx += 1
        if presence[idx] { luggage = try LuggageRestrictionType(from: &decoder) }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            includedTransportTypes = []
            for _ in 0..<count {
                includedTransportTypes?.append(try decoder.decodeConstrainedInt(min: 0, max: 31))
            }
        }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            excludedTransportTypes = []
            for _ in 0..<count {
                excludedTransportTypes?.append(try decoder.decodeConstrainedInt(min: 0, max: 31))
            }
        }; idx += 1
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

// MARK: - OpenTicketData Encoding

extension OpenTicketData: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)

        let stationCodeTablePresent = stationCodeTable != nil && stationCodeTable != .stationUIC
        let validFromDayPresent = validFromDay != nil && validFromDay != 0
        let validUntilDayPresent = validUntilDay != nil && validUntilDay != 0
        let classCodePresent = classCode != nil && classCode != .second

        try encoder.encodePresenceBitmap([
            referenceNum != nil,
            referenceIA5 != nil,
            productOwnerNum != nil,
            productOwnerIA5 != nil,
            productIdNum != nil,
            productIdIA5 != nil,
            externalIssuerId != nil,
            issuerAutorizationId != nil,
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
            activatedDay != nil,
            classCodePresent,
            serviceLevel != nil,
            carrierNum != nil,
            carrierIA5 != nil,
            includedServiceBrands != nil,
            excludedServiceBrands != nil,
            tariffs != nil,
            price != nil,
            vatDetails != nil,
            infoText != nil,
            includedAddOns != nil,
            luggage != nil,
            includedTransportTypes != nil,
            excludedTransportTypes != nil,
            extensionData != nil
        ])

        if let v = referenceNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = referenceIA5 { try encoder.encodeIA5String(v) }
        if let v = productOwnerNum { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        if let v = productOwnerIA5 { try encoder.encodeIA5String(v) }
        if let v = productIdNum { try encoder.encodeConstrainedInt(v, min: 0, max: 65535) }
        if let v = productIdIA5 { try encoder.encodeIA5String(v) }
        if let v = externalIssuerId { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = issuerAutorizationId { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        try encoder.encodeBoolean(returnIncluded)
        if stationCodeTablePresent { try encoder.encodeEnumerated(stationCodeTable!.rawValue, rootCount: 5) }
        if let v = fromStationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = fromStationIA5 { try encoder.encodeIA5String(v) }
        if let v = toStationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = toStationIA5 { try encoder.encodeIA5String(v) }
        if let v = fromStationNameUTF8 { try encoder.encodeUTF8String(v) }
        if let v = toStationNameUTF8 { try encoder.encodeUTF8String(v) }
        if let v = validRegionDesc { try encoder.encodeUTF8String(v) }
        if let arr = validRegion { try encoder.encodeSequenceOf(arr) }
        if let v = returnDescription { try v.encode(to: &encoder) }
        if validFromDayPresent { try encoder.encodeConstrainedInt(validFromDay!, min: -367, max: 700) }
        if let v = validFromTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1439) }
        if let v = validFromUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if validUntilDayPresent { try encoder.encodeConstrainedInt(validUntilDay!, min: -1, max: 500) }
        if let v = validUntilTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1439) }
        if let v = validUntilUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if let arr = activatedDay {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeConstrainedInt(v, min: 0, max: 500) }
        }
        if classCodePresent { try encoder.encodeEnumerated(classCode!.rawValue, rootCount: 12, hasExtensionMarker: true) }
        if let v = serviceLevel { try encoder.encodeIA5String(v, constraint: ASN1StringConstraint(type: .ia5String, minLength: 1, maxLength: 2)) }
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
        if let arr = tariffs { try encoder.encodeSequenceOf(arr) }
        if let v = price { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let arr = vatDetails { try encoder.encodeSequenceOf(arr) }
        if let v = infoText { try encoder.encodeUTF8String(v) }
        if let arr = includedAddOns { try encoder.encodeSequenceOf(arr) }
        if let v = luggage { try v.encode(to: &encoder) }
        if let arr = includedTransportTypes {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeConstrainedInt(v, min: 0, max: 31) }
        }
        if let arr = excludedTransportTypes {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeConstrainedInt(v, min: 0, max: 31) }
        }
        if let v = extensionData { try v.encode(to: &encoder) }
    }
}
