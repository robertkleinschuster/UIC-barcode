import Foundation

// MARK: - Car Carriage Reservation Data

struct CarCarriageReservationDataV2: ASN1Decodable {
    var trainNum: Int?
    var trainIA5: String?
    var beginLoadingDate: Int?
    var beginLoadingTime: Int?
    var endLoadingTime: Int?
    var loadingUTCOffset: Int?
    var referenceIA5: String?
    var referenceNum: Int?
    var productOwnerNum: Int?
    var productOwnerIA5: String?
    var productIdNum: Int?
    var productIdIA5: String?
    var serviceBrand: Int?
    var serviceBrandAbrUTF8: String?
    var serviceBrandNameUTF8: String?
    var stationCodeTable: CodeTableTypeV2?
    var fromStationNum: Int?
    var fromStationIA5: String?
    var toStationNum: Int?
    var toStationIA5: String?
    var fromStationNameUTF8: String?
    var toStationNameUTF8: String?
    var coach: String?
    var place: String?
    var compartmentDetails: CompartmentDetailsTypeV2?
    var numberPlate: String = ""
    var trailerPlate: String?
    var carCategory: Int = 0
    var boatCategory: Int?
    var textileRoof: Bool = false
    var roofRackType: RoofRackTypeV2?
    var roofRackHeight: Int?
    var attachedBoats: Int?
    var attachedBicycles: Int?
    var attachedSurfboards: Int?
    var loadingListEntry: Int?
    var loadingDeck: LoadingDeckTypeV2?
    var carrierNum: [Int]?
    var carrierIA5: [String]?
    var tariff: TariffTypeV2 = TariffTypeV2()
    var priceType: PriceTypeTypeV2?
    var price: Int?
    var vatDetail: [VatDetailTypeV2]?
    var infoText: String?
    var extensionData: ExtensionDataV2?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 41 optional+default fields; numberPlate, carCategory, textileRoof, tariff are mandatory
        let presence = try decoder.decodePresenceBitmap(count: 41)
        var idx = 0

        if presence[idx] { trainNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { trainIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { beginLoadingDate = try decoder.decodeConstrainedInt(min: -1, max: 370) } else { beginLoadingDate = 0 }; idx += 1
        if presence[idx] { beginLoadingTime = try decoder.decodeConstrainedInt(min: 0, max: 1439) }; idx += 1
        if presence[idx] { endLoadingTime = try decoder.decodeConstrainedInt(min: 0, max: 1439) }; idx += 1
        if presence[idx] { loadingUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }; idx += 1
        if presence[idx] { referenceIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { referenceNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { productOwnerNum = try decoder.decodeConstrainedInt(min: 1, max: 32000) }; idx += 1
        if presence[idx] { productOwnerIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { productIdNum = try decoder.decodeConstrainedInt(min: 0, max: 65535) }; idx += 1
        if presence[idx] { productIdIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { serviceBrand = try decoder.decodeConstrainedInt(min: 1, max: 32000) }; idx += 1
        if presence[idx] { serviceBrandAbrUTF8 = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] { serviceBrandNameUTF8 = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] {
            stationCodeTable = try CodeTableTypeV2(from: &decoder)
        } else {
            stationCodeTable = .stationUICReservation
        }; idx += 1
        if presence[idx] { fromStationNum = try decoder.decodeConstrainedInt(min: 1, max: 9999999) }; idx += 1
        if presence[idx] { fromStationIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { toStationNum = try decoder.decodeConstrainedInt(min: 1, max: 9999999) }; idx += 1
        if presence[idx] { toStationIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { fromStationNameUTF8 = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] { toStationNameUTF8 = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] { coach = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { place = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { compartmentDetails = try CompartmentDetailsTypeV2(from: &decoder) }; idx += 1

        // numberPlate is MANDATORY
        numberPlate = try decoder.decodeIA5String()

        if presence[idx] { trailerPlate = try decoder.decodeIA5String() }; idx += 1

        // carCategory is MANDATORY
        carCategory = try decoder.decodeConstrainedInt(min: 0, max: 9)

        if presence[idx] { boatCategory = try decoder.decodeConstrainedInt(min: 0, max: 6) }; idx += 1

        // textileRoof is MANDATORY
        textileRoof = try decoder.decodeBoolean()

        if presence[idx] {
            roofRackType = try RoofRackTypeV2(from: &decoder)
        } else {
            roofRackType = .norack
        }; idx += 1
        if presence[idx] { roofRackHeight = try decoder.decodeConstrainedInt(min: 0, max: 99) }; idx += 1
        if presence[idx] { attachedBoats = try decoder.decodeConstrainedInt(min: 0, max: 2) }; idx += 1
        if presence[idx] { attachedBicycles = try decoder.decodeConstrainedInt(min: 0, max: 4) }; idx += 1
        if presence[idx] { attachedSurfboards = try decoder.decodeConstrainedInt(min: 0, max: 5) }; idx += 1
        if presence[idx] { loadingListEntry = try decoder.decodeConstrainedInt(min: 0, max: 999) }; idx += 1
        if presence[idx] {
            loadingDeck = try LoadingDeckTypeV2(from: &decoder)
        } else {
            loadingDeck = .upper
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

        // tariff is MANDATORY
        tariff = try TariffTypeV2(from: &decoder)

        if presence[idx] {
            priceType = try PriceTypeTypeV2(from: &decoder)
        } else {
            priceType = .travelPrice
        }; idx += 1
        if presence[idx] { price = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { vatDetail = try decoder.decodeSequenceOf() }; idx += 1
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

// MARK: - CarCarriageReservationDataV2 Encoding

extension CarCarriageReservationDataV2: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        let beginLoadingDatePresent = beginLoadingDate != nil && beginLoadingDate != 0
        let stationCodeTablePresent = stationCodeTable != nil && stationCodeTable != .stationUICReservation
        let roofRackTypePresent = roofRackType != nil && roofRackType != .norack
        let loadingDeckPresent = loadingDeck != nil && loadingDeck != .upper
        let priceTypePresent = priceType != nil && priceType != .travelPrice
        // V2: 41 optional+default fields; numberPlate, carCategory, textileRoof, tariff are mandatory
        try encoder.encodePresenceBitmap([
            trainNum != nil,
            trainIA5 != nil,
            beginLoadingDatePresent,
            beginLoadingTime != nil,
            endLoadingTime != nil,
            loadingUTCOffset != nil,
            referenceIA5 != nil,
            referenceNum != nil,
            productOwnerNum != nil,
            productOwnerIA5 != nil,
            productIdNum != nil,
            productIdIA5 != nil,
            serviceBrand != nil,
            serviceBrandAbrUTF8 != nil,
            serviceBrandNameUTF8 != nil,
            stationCodeTablePresent,
            fromStationNum != nil,
            fromStationIA5 != nil,
            toStationNum != nil,
            toStationIA5 != nil,
            fromStationNameUTF8 != nil,
            toStationNameUTF8 != nil,
            coach != nil,
            place != nil,
            compartmentDetails != nil,
            // numberPlate is mandatory
            trailerPlate != nil,
            // carCategory is mandatory
            boatCategory != nil,
            // textileRoof is mandatory
            roofRackTypePresent,
            roofRackHeight != nil,
            attachedBoats != nil,
            attachedBicycles != nil,
            attachedSurfboards != nil,
            loadingListEntry != nil,
            loadingDeckPresent,
            carrierNum != nil,
            carrierIA5 != nil,
            // tariff is mandatory
            priceTypePresent,
            price != nil,
            vatDetail != nil,
            infoText != nil,
            extensionData != nil
        ])
        if let v = trainNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = trainIA5 { try encoder.encodeIA5String(v) }
        if beginLoadingDatePresent { try encoder.encodeConstrainedInt(beginLoadingDate!, min: -1, max: 370) }
        if let v = beginLoadingTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1439) }
        if let v = endLoadingTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1439) }
        if let v = loadingUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if let v = referenceIA5 { try encoder.encodeIA5String(v) }
        if let v = referenceNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = productOwnerNum { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        if let v = productOwnerIA5 { try encoder.encodeIA5String(v) }
        if let v = productIdNum { try encoder.encodeConstrainedInt(v, min: 0, max: 65535) }
        if let v = productIdIA5 { try encoder.encodeIA5String(v) }
        if let v = serviceBrand { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        if let v = serviceBrandAbrUTF8 { try encoder.encodeUTF8String(v) }
        if let v = serviceBrandNameUTF8 { try encoder.encodeUTF8String(v) }
        if stationCodeTablePresent { try encoder.encodeEnumerated(stationCodeTable!.rawValue, rootCount: CodeTableTypeV2.rootValueCount) }
        if let v = fromStationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = fromStationIA5 { try encoder.encodeIA5String(v) }
        if let v = toStationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = toStationIA5 { try encoder.encodeIA5String(v) }
        if let v = fromStationNameUTF8 { try encoder.encodeUTF8String(v) }
        if let v = toStationNameUTF8 { try encoder.encodeUTF8String(v) }
        if let v = coach { try encoder.encodeIA5String(v) }
        if let v = place { try encoder.encodeIA5String(v) }
        if let v = compartmentDetails { try v.encode(to: &encoder) }
        // numberPlate is MANDATORY
        try encoder.encodeIA5String(numberPlate)
        if let v = trailerPlate { try encoder.encodeIA5String(v) }
        // carCategory is MANDATORY
        try encoder.encodeConstrainedInt(carCategory, min: 0, max: 9)
        if let v = boatCategory { try encoder.encodeConstrainedInt(v, min: 0, max: 6) }
        // textileRoof is MANDATORY
        try encoder.encodeBoolean(textileRoof)
        if roofRackTypePresent { try encoder.encodeEnumerated(roofRackType!.rawValue, rootCount: RoofRackTypeV2.rootValueCount, hasExtensionMarker: RoofRackTypeV2.hasExtensionMarker) }
        if let v = roofRackHeight { try encoder.encodeConstrainedInt(v, min: 0, max: 99) }
        if let v = attachedBoats { try encoder.encodeConstrainedInt(v, min: 0, max: 2) }
        if let v = attachedBicycles { try encoder.encodeConstrainedInt(v, min: 0, max: 4) }
        if let v = attachedSurfboards { try encoder.encodeConstrainedInt(v, min: 0, max: 5) }
        if let v = loadingListEntry { try encoder.encodeConstrainedInt(v, min: 0, max: 999) }
        if loadingDeckPresent { try encoder.encodeEnumerated(loadingDeck!.rawValue, rootCount: LoadingDeckTypeV2.rootValueCount) }
        if let v = carrierNum {
            try encoder.encodeLengthDeterminant(v.count)
            for num in v { try encoder.encodeConstrainedInt(num, min: 1, max: 32000) }
        }
        if let v = carrierIA5 {
            try encoder.encodeLengthDeterminant(v.count)
            for s in v { try encoder.encodeIA5String(s) }
        }
        // tariff is MANDATORY
        try tariff.encode(to: &encoder)
        if priceTypePresent { try encoder.encodeEnumerated(priceType!.rawValue, rootCount: PriceTypeTypeV2.rootValueCount) }
        if let v = price { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = vatDetail { try encoder.encodeSequenceOf(v) }
        if let v = infoText { try encoder.encodeUTF8String(v) }
        if let v = extensionData { try v.encode(to: &encoder) }
    }
}
