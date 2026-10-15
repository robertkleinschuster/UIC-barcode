import Foundation

// MARK: - Car Carriage Reservation Data

/// Car carriage reservation data - FCB v3 all 45 fields
public struct CarCarriageReservationData: ASN1Decodable {
    public var trainNum: Int?
    public var trainIA5: String?
    public var beginLoadingDate: Int?
    public var beginLoadingTime: Int?
    public var endLoadingTime: Int?
    public var loadingUTCOffset: Int?
    public var referenceIA5: String?
    public var referenceNum: Int?
    public var productOwnerNum: Int?
    public var productOwnerIA5: String?
    public var productIdNum: Int?
    public var productIdIA5: String?
    public var serviceBrand: Int?
    public var serviceBrandAbrUTF8: String?
    public var serviceBrandNameUTF8: String?
    public var stationCodeTable: CodeTableType?
    public var fromStationNum: Int?
    public var fromStationIA5: String?
    public var toStationNum: Int?
    public var toStationIA5: String?
    public var fromStationNameUTF8: String?
    public var toStationNameUTF8: String?
    public var coach: String?
    public var place: String?
    public var compartmentDetails: CompartmentDetailsType?
    public var numberPlate: String?
    public var trailerPlate: String?
    public var carCategory: Int?
    public var boatCategory: Int?
    public var textileRoof: Bool?
    public var roofRackType: RoofRackType?
    public var roofRackHeight: Int?
    public var attachedBoats: Int?
    public var attachedBicycles: Int?
    public var attachedSurfboards: Int?
    public var loadingListEntry: Int?
    public var loadingDeck: LoadingDeckType?
    public var carrierNum: [Int]?
    public var carrierIA5: [String]?
    public var tariff: TariffType?
    public var priceType: PriceTypeType?
    public var price: Int?
    public var vatDetails: [VatDetailType]?
    public var infoText: String?
    public var extensionData: ExtensionData?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 41 optional fields (fields 25, 27, 29, 39 are MANDATORY per Java CarCarriageReservationData.java)
        let optionalCount = 41
        let presence = try decoder.decodePresenceBitmap(count: optionalCount)
        var idx = 0

        // Field 0: trainNum (optional, BigInteger)
        if presence[idx] { trainNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        // Field 1: trainIA5 (optional, IA5String)
        if presence[idx] { trainIA5 = try decoder.decodeIA5String() }; idx += 1
        // Field 2: beginLoadingDate (optional, -1..500, default 0)
        if presence[idx] { beginLoadingDate = try decoder.decodeConstrainedInt(min: -1, max: 500) } else { beginLoadingDate = 0 }; idx += 1
        // Field 3: beginLoadingTime (optional, 0..1439)
        if presence[idx] { beginLoadingTime = try decoder.decodeConstrainedInt(min: 0, max: 1439) }; idx += 1
        // Field 4: endLoadingTime (optional, 0..1439)
        if presence[idx] { endLoadingTime = try decoder.decodeConstrainedInt(min: 0, max: 1439) }; idx += 1
        // Field 5: loadingUTCOffset (optional, -60..60)
        if presence[idx] { loadingUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }; idx += 1
        // Field 6: referenceIA5 (optional, IA5String)
        if presence[idx] { referenceIA5 = try decoder.decodeIA5String() }; idx += 1
        // Field 7: referenceNum (optional, BigInteger)
        if presence[idx] { referenceNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        // Field 8: productOwnerNum (optional, 1..32000)
        if presence[idx] { productOwnerNum = try decoder.decodeConstrainedInt(min: 1, max: 32000) }; idx += 1
        // Field 9: productOwnerIA5 (optional, IA5String)
        if presence[idx] { productOwnerIA5 = try decoder.decodeIA5String() }; idx += 1
        // Field 10: productIdNum (optional, 0..65535)
        if presence[idx] { productIdNum = try decoder.decodeConstrainedInt(min: 0, max: 65535) }; idx += 1
        // Field 11: productIdIA5 (optional, IA5String)
        if presence[idx] { productIdIA5 = try decoder.decodeIA5String() }; idx += 1
        // Field 12: serviceBrand (optional, 1..32000)
        if presence[idx] { serviceBrand = try decoder.decodeConstrainedInt(min: 1, max: 32000) }; idx += 1
        // Field 13: serviceBrandAbrUTF8 (optional, UTF8String)
        if presence[idx] { serviceBrandAbrUTF8 = try decoder.decodeUTF8String() }; idx += 1
        // Field 14: serviceBrandNameUTF8 (optional, UTF8String)
        if presence[idx] { serviceBrandNameUTF8 = try decoder.decodeUTF8String() }; idx += 1
        // Field 15: stationCodeTable (optional, CodeTableType, default stationUICReservation)
        if presence[idx] {
            let value = try decoder.decodeEnumerated(rootCount: 5)
            stationCodeTable = CodeTableType(rawValue: value)
        } else {
            stationCodeTable = .stationUICReservation
        }; idx += 1
        // Field 16: fromStationNum (optional, 1..9999999)
        if presence[idx] { fromStationNum = try decoder.decodeConstrainedInt(min: 1, max: 9999999) }; idx += 1
        // Field 17: fromStationIA5 (optional, IA5String)
        if presence[idx] { fromStationIA5 = try decoder.decodeIA5String() }; idx += 1
        // Field 18: toStationNum (optional, 1..9999999)
        if presence[idx] { toStationNum = try decoder.decodeConstrainedInt(min: 1, max: 9999999) }; idx += 1
        // Field 19: toStationIA5 (optional, IA5String)
        if presence[idx] { toStationIA5 = try decoder.decodeIA5String() }; idx += 1
        // Field 20: fromStationNameUTF8 (optional, UTF8String)
        if presence[idx] { fromStationNameUTF8 = try decoder.decodeUTF8String() }; idx += 1
        // Field 21: toStationNameUTF8 (optional, UTF8String)
        if presence[idx] { toStationNameUTF8 = try decoder.decodeUTF8String() }; idx += 1
        // Field 22: coach (optional, IA5String)
        if presence[idx] { coach = try decoder.decodeIA5String() }; idx += 1
        // Field 23: place (optional, IA5String)
        if presence[idx] { place = try decoder.decodeIA5String() }; idx += 1
        // Field 24: compartmentDetails (optional, CompartmentDetailsType)
        if presence[idx] { compartmentDetails = try CompartmentDetailsType(from: &decoder) }; idx += 1

        // Field 25: numberPlate (MANDATORY, IA5String)
        numberPlate = try decoder.decodeIA5String()

        // Field 26: trailerPlate (optional, IA5String)
        if presence[idx] { trailerPlate = try decoder.decodeIA5String() }; idx += 1

        // Field 27: carCategory (MANDATORY, 0..9)
        carCategory = try decoder.decodeConstrainedInt(min: 0, max: 9)

        // Field 28: boatCategory (optional, 0..6)
        if presence[idx] { boatCategory = try decoder.decodeConstrainedInt(min: 0, max: 6) }; idx += 1

        // Field 29: textileRoof (MANDATORY, Boolean, default false)
        textileRoof = try decoder.decodeBoolean()

        // Field 30: roofRackType (optional, RoofRackType, default norack)
        if presence[idx] {
            let value = try decoder.decodeEnumerated(rootCount: 9, hasExtensionMarker: true)
            roofRackType = RoofRackType(rawValue: value)
        } else {
            roofRackType = .norack
        }; idx += 1
        // Field 31: roofRackHeight (optional, 0..99)
        if presence[idx] { roofRackHeight = try decoder.decodeConstrainedInt(min: 0, max: 99) }; idx += 1
        // Field 32: attachedBoats (optional, 0..2)
        if presence[idx] { attachedBoats = try decoder.decodeConstrainedInt(min: 0, max: 2) }; idx += 1
        // Field 33: attachedBicycles (optional, 0..4)
        if presence[idx] { attachedBicycles = try decoder.decodeConstrainedInt(min: 0, max: 4) }; idx += 1
        // Field 34: attachedSurfboards (optional, 0..5)
        if presence[idx] { attachedSurfboards = try decoder.decodeConstrainedInt(min: 0, max: 5) }; idx += 1
        // Field 35: loadingListEntry (optional, 0..999)
        if presence[idx] { loadingListEntry = try decoder.decodeConstrainedInt(min: 0, max: 999) }; idx += 1
        // Field 36: loadingDeck (optional, LoadingDeckType, default upper)
        if presence[idx] {
            let value = try decoder.decodeEnumerated(rootCount: 3)
            loadingDeck = LoadingDeckType(rawValue: value)
        } else {
            loadingDeck = .upper
        }; idx += 1
        // Field 37: carrierNum (optional, SEQUENCE OF INTEGER 1..32000)
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            carrierNum = []
            for _ in 0..<count {
                carrierNum?.append(try decoder.decodeConstrainedInt(min: 1, max: 32000))
            }
        }; idx += 1
        // Field 38: carrierIA5 (optional, SEQUENCE OF IA5String)
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            carrierIA5 = []
            for _ in 0..<count {
                carrierIA5?.append(try decoder.decodeIA5String())
            }
        }; idx += 1

        // Field 39: tariff (MANDATORY, TariffType)
        tariff = try TariffType(from: &decoder)

        // Field 40: priceType (optional, PriceTypeType, default travelPrice)
        if presence[idx] {
            let value = try decoder.decodeEnumerated(rootCount: 4)
            priceType = PriceTypeType(rawValue: value)
        } else {
            priceType = .travelPrice
        }; idx += 1
        // Field 41: price (optional, BigInteger)
        if presence[idx] { price = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        // Field 42: vatDetails (optional, SEQUENCE OF VatDetailType)
        if presence[idx] { vatDetails = try decoder.decodeSequenceOf() }; idx += 1
        // Field 43: infoText (optional, UTF8String)
        if presence[idx] { infoText = try decoder.decodeUTF8String() }; idx += 1
        // Field 44: extension (optional, ExtensionData)
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

// MARK: - CarCarriageReservationData Encoding

extension CarCarriageReservationData: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)

        let beginLoadingDatePresent = beginLoadingDate != nil && beginLoadingDate != 0
        let stationCodeTablePresent = stationCodeTable != nil && stationCodeTable != .stationUICReservation
        let roofRackTypePresent = roofRackType != nil && roofRackType != .norack
        let loadingDeckPresent = loadingDeck != nil && loadingDeck != .upper
        let priceTypePresent = priceType != nil && priceType != .travelPrice

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
            trailerPlate != nil,
            boatCategory != nil,
            roofRackTypePresent,
            roofRackHeight != nil,
            attachedBoats != nil,
            attachedBicycles != nil,
            attachedSurfboards != nil,
            loadingListEntry != nil,
            loadingDeckPresent,
            carrierNum != nil,
            carrierIA5 != nil,
            priceTypePresent,
            price != nil,
            vatDetails != nil,
            infoText != nil,
            extensionData != nil
        ])

        if let v = trainNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = trainIA5 { try encoder.encodeIA5String(v) }
        if beginLoadingDatePresent { try encoder.encodeConstrainedInt(beginLoadingDate!, min: -1, max: 500) }
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
        if stationCodeTablePresent { try encoder.encodeEnumerated(stationCodeTable!.rawValue, rootCount: 5) }
        if let v = fromStationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = fromStationIA5 { try encoder.encodeIA5String(v) }
        if let v = toStationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = toStationIA5 { try encoder.encodeIA5String(v) }
        if let v = fromStationNameUTF8 { try encoder.encodeUTF8String(v) }
        if let v = toStationNameUTF8 { try encoder.encodeUTF8String(v) }
        if let v = coach { try encoder.encodeIA5String(v) }
        if let v = place { try encoder.encodeIA5String(v) }
        if let v = compartmentDetails { try v.encode(to: &encoder) }
        try encoder.encodeIA5String(numberPlate ?? "")
        if let v = trailerPlate { try encoder.encodeIA5String(v) }
        try encoder.encodeConstrainedInt(carCategory ?? 0, min: 0, max: 9)
        if let v = boatCategory { try encoder.encodeConstrainedInt(v, min: 0, max: 6) }
        try encoder.encodeBoolean(textileRoof ?? false)
        if roofRackTypePresent { try encoder.encodeEnumerated(roofRackType!.rawValue, rootCount: 9, hasExtensionMarker: true) }
        if let v = roofRackHeight { try encoder.encodeConstrainedInt(v, min: 0, max: 99) }
        if let v = attachedBoats { try encoder.encodeConstrainedInt(v, min: 0, max: 2) }
        if let v = attachedBicycles { try encoder.encodeConstrainedInt(v, min: 0, max: 4) }
        if let v = attachedSurfboards { try encoder.encodeConstrainedInt(v, min: 0, max: 5) }
        if let v = loadingListEntry { try encoder.encodeConstrainedInt(v, min: 0, max: 999) }
        if loadingDeckPresent { try encoder.encodeEnumerated(loadingDeck!.rawValue, rootCount: 3) }
        if let arr = carrierNum {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        }
        if let arr = carrierIA5 {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeIA5String(v) }
        }
        try (tariff ?? TariffType()).encode(to: &encoder)
        if priceTypePresent { try encoder.encodeEnumerated(priceType!.rawValue, rootCount: 4) }
        if let v = price { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let arr = vatDetails { try encoder.encodeSequenceOf(arr) }
        if let v = infoText { try encoder.encodeUTF8String(v) }
        if let v = extensionData { try v.encode(to: &encoder) }
    }
}
