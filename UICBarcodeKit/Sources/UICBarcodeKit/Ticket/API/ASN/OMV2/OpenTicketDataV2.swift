import Foundation

// MARK: - Open Ticket Data

struct OpenTicketDataV2: ASN1Decodable {
    var referenceNum: Int?
    var referenceIA5: String?
    var productOwnerNum: Int?
    var productOwnerIA5: String?
    var productIdNum: Int?
    var productIdIA5: String?
    var extIssuerId: Int?
    var issuerAuthorizationId: Int?
    var returnIncluded: Bool = false
    var stationCodeTable: CodeTableTypeV2?
    var fromStationNum: Int?
    var fromStationIA5: String?
    var toStationNum: Int?
    var toStationIA5: String?
    var fromStationNameUTF8: String?
    var toStationNameUTF8: String?
    var validRegionDesc: String?
    var validRegion: [RegionalValidityTypeV2]?
    var returnDescription: ReturnRouteDescriptionTypeV2?
    var validFromDay: Int?
    var validFromTime: Int?
    var validFromUTCOffset: Int?
    var validUntilDay: Int?
    var validUntilTime: Int?
    var validUntilUTCOffset: Int?
    var activatedDay: [Int]?
    var classCode: TravelClassTypeV2?
    var serviceLevel: String?
    var carrierNum: [Int]?
    var carrierIA5: [String]?
    var includedServiceBrands: [Int]?
    var excludedServiceBrands: [Int]?
    var tariffs: [TariffTypeV2]?
    var price: Int?
    var vatDetail: [VatDetailTypeV2]?
    var infoText: String?
    var includedAddOns: [IncludedOpenTicketTypeV2]?
    var luggage: LuggageRestrictionTypeV2?
    var includedTransportTypes: [Int]?
    var excludedTransportTypes: [Int]?
    var extensionData: ExtensionDataV2?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 40 optional+default fields; returnIncluded is mandatory
        // V2 field order: 0-7, [8=mandatory], 9-31, 32=tariffs, 33=price, 34=vatDetails,
        // 35=infoText, 36=includedAddOns, 37=luggage, 38=includedTransportTypes, 39=excludedTransportTypes, 40=extension
        let presence = try decoder.decodePresenceBitmap(count: 40)
        var idx = 0

        if presence[idx] { referenceNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { referenceIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { productOwnerNum = try decoder.decodeConstrainedInt(min: 1, max: 32000) }; idx += 1
        if presence[idx] { productOwnerIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { productIdNum = try decoder.decodeConstrainedInt(min: 0, max: 65535) }; idx += 1
        if presence[idx] { productIdIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { extIssuerId = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { issuerAuthorizationId = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1

        // returnIncluded is MANDATORY
        returnIncluded = try decoder.decodeBoolean()

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
        if presence[idx] { returnDescription = try ReturnRouteDescriptionTypeV2(from: &decoder) }; idx += 1
        if presence[idx] { validFromDay = try decoder.decodeConstrainedInt(min: -1, max: 700) } else { validFromDay = 0 }; idx += 1
        if presence[idx] { validFromTime = try decoder.decodeConstrainedInt(min: 0, max: 1439) }; idx += 1
        if presence[idx] { validFromUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }; idx += 1
        if presence[idx] { validUntilDay = try decoder.decodeConstrainedInt(min: -1, max: 370) } else { validUntilDay = 0 }; idx += 1
        if presence[idx] { validUntilTime = try decoder.decodeConstrainedInt(min: 0, max: 1439) }; idx += 1
        if presence[idx] { validUntilUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            activatedDay = []
            for _ in 0..<count {
                activatedDay?.append(try decoder.decodeConstrainedInt(min: 0, max: 370))
            }
        }; idx += 1
        if presence[idx] {
            classCode = try TravelClassTypeV2(from: &decoder)
        } else {
            classCode = .second
        }; idx += 1
        if presence[idx] {
            serviceLevel = try decoder.decodeIA5String(
                constraint: ASN1StringConstraint(type: .ia5String, minLength: 1, maxLength: 2)
            )
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
        // V2 order: tariffs(32), price(33), vatDetails(34), infoText(35),
        // includedAddOns(36), luggage(37), includedTransportTypes(38), excludedTransportTypes(39), extension(40)
        if presence[idx] { tariffs = try decoder.decodeSequenceOf() }; idx += 1
        if presence[idx] { price = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { vatDetail = try decoder.decodeSequenceOf() }; idx += 1
        if presence[idx] { infoText = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] { includedAddOns = try decoder.decodeSequenceOf() }; idx += 1
        if presence[idx] { luggage = try LuggageRestrictionTypeV2(from: &decoder) }; idx += 1
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

// MARK: - OpenTicketDataV2 Encoding

extension OpenTicketDataV2: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        let stationCodeTablePresent = stationCodeTable != nil && stationCodeTable != .stationUIC
        let validFromDayPresent = validFromDay != nil && validFromDay != 0
        let validUntilDayPresent = validUntilDay != nil && validUntilDay != 0
        let classCodePresent = classCode != nil && classCode != .second
        // V2: 40 optional+default fields; returnIncluded is mandatory
        try encoder.encodePresenceBitmap([
            referenceNum != nil,
            referenceIA5 != nil,
            productOwnerNum != nil,
            productOwnerIA5 != nil,
            productIdNum != nil,
            productIdIA5 != nil,
            extIssuerId != nil,
            issuerAuthorizationId != nil,
            // returnIncluded is mandatory - not in bitmap
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
            // V2 order: tariffs, price, vatDetail, infoText, includedAddOns, luggage, transport types
            tariffs != nil,
            price != nil,
            vatDetail != nil,
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
        if let v = extIssuerId { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = issuerAuthorizationId { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        // returnIncluded is MANDATORY
        try encoder.encodeBoolean(returnIncluded)
        if stationCodeTablePresent { try encoder.encodeEnumerated(stationCodeTable!.rawValue, rootCount: CodeTableTypeV2.rootValueCount) }
        if let v = fromStationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = fromStationIA5 { try encoder.encodeIA5String(v) }
        if let v = toStationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = toStationIA5 { try encoder.encodeIA5String(v) }
        if let v = fromStationNameUTF8 { try encoder.encodeUTF8String(v) }
        if let v = toStationNameUTF8 { try encoder.encodeUTF8String(v) }
        if let v = validRegionDesc { try encoder.encodeUTF8String(v) }
        if let v = validRegion { try encoder.encodeSequenceOf(v) }
        if let v = returnDescription { try v.encode(to: &encoder) }
        if validFromDayPresent { try encoder.encodeConstrainedInt(validFromDay!, min: -1, max: 700) }
        if let v = validFromTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1439) }
        if let v = validFromUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if validUntilDayPresent { try encoder.encodeConstrainedInt(validUntilDay!, min: -1, max: 370) }
        if let v = validUntilTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1439) }
        if let v = validUntilUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if let v = activatedDay {
            try encoder.encodeLengthDeterminant(v.count)
            for day in v { try encoder.encodeConstrainedInt(day, min: 0, max: 370) }
        }
        if classCodePresent { try encoder.encodeEnumerated(classCode!.rawValue, rootCount: TravelClassTypeV2.rootValueCount, hasExtensionMarker: TravelClassTypeV2.hasExtensionMarker) }
        if let v = serviceLevel { try encoder.encodeIA5String(v, constraint: ASN1StringConstraint(type: .ia5String, minLength: 1, maxLength: 2)) }
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
        // V2 order: tariffs, price, vatDetail, infoText, addOns, luggage, transport types, extension
        if let v = tariffs { try encoder.encodeSequenceOf(v) }
        if let v = price { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = vatDetail { try encoder.encodeSequenceOf(v) }
        if let v = infoText { try encoder.encodeUTF8String(v) }
        if let v = includedAddOns { try encoder.encodeSequenceOf(v) }
        if let v = luggage { try v.encode(to: &encoder) }
        if let v = includedTransportTypes {
            try encoder.encodeLengthDeterminant(v.count)
            for num in v { try encoder.encodeConstrainedInt(num, min: 0, max: 31) }
        }
        if let v = excludedTransportTypes {
            try encoder.encodeLengthDeterminant(v.count)
            for num in v { try encoder.encodeConstrainedInt(num, min: 0, max: 31) }
        }
        if let v = extensionData { try v.encode(to: &encoder) }
    }
}
