import Foundation

// MARK: - Reservation Data

struct ReservationDataV2: ASN1Decodable {
    var trainNum: Int?
    var trainIA5: String?
    var departureDate: Int?
    var referenceIA5: String?
    var referenceNum: Int?
    var productOwnerNum: Int?
    var productOwnerIA5: String?
    var productIdNum: Int?
    var productIdIA5: String?
    var serviceBrand: Int?
    var serviceBrandAbrUTF8: String?
    var serviceBrandNameUTF8: String?
    var service: ServiceTypeV2?
    var stationCodeTable: CodeTableTypeV2?
    var fromStationNum: Int?
    var fromStationIA5: String?
    var toStationNum: Int?
    var toStationIA5: String?
    var fromStationNameUTF8: String?
    var toStationNameUTF8: String?
    var departureTime: Int = 0
    var departureUTCOffset: Int?
    var arrivalDate: Int?
    var arrivalTime: Int?
    var arrivalUTCOffset: Int?
    var carrierNum: [Int]?
    var carrierIA5: [String]?
    var classCode: TravelClassTypeV2?
    var serviceLevel: String?
    var places: PlacesTypeV2?
    var additionalPlaces: PlacesTypeV2?
    var bicyclePlaces: PlacesTypeV2?
    var compartmentDetails: CompartmentDetailsTypeV2?
    var numberOfOverbooked: Int?
    var berth: [BerthDetailDataV2]?
    var tariff: [TariffTypeV2]?
    var priceType: PriceTypeTypeV2?
    var price: Int?
    var vatDetail: [VatDetailTypeV2]?
    var typeOfSupplement: Int?
    var numberOfSupplements: Int?
    var luggage: LuggageRestrictionTypeV2?
    var infoText: String?
    var extensionData: ExtensionDataV2?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 43 optional+default fields; departureTime is mandatory
        // V1 had 41; V2 adds departureUTCOffset and arrivalUTCOffset = +2
        let presence = try decoder.decodePresenceBitmap(count: 43)
        var idx = 0

        if presence[idx] { trainNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { trainIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { departureDate = try decoder.decodeConstrainedInt(min: -1, max: 370) } else { departureDate = 0 }; idx += 1
        if presence[idx] { referenceIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { referenceNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { productOwnerNum = try decoder.decodeConstrainedInt(min: 1, max: 32000) }; idx += 1
        if presence[idx] { productOwnerIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { productIdNum = try decoder.decodeConstrainedInt(min: 0, max: 65535) }; idx += 1
        if presence[idx] { productIdIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { serviceBrand = try decoder.decodeConstrainedInt(min: 0, max: 32000) }; idx += 1
        if presence[idx] { serviceBrandAbrUTF8 = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] { serviceBrandNameUTF8 = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] {
            service = try ServiceTypeV2(from: &decoder)
        } else {
            service = .seat
        }; idx += 1
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

        // departureTime is MANDATORY
        departureTime = try decoder.decodeConstrainedInt(min: 0, max: 1439)

        if presence[idx] { departureUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }; idx += 1
        if presence[idx] { arrivalDate = try decoder.decodeConstrainedInt(min: -1, max: 20) } else { arrivalDate = 0 }; idx += 1
        if presence[idx] { arrivalTime = try decoder.decodeConstrainedInt(min: 0, max: 1439) }; idx += 1
        if presence[idx] { arrivalUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }; idx += 1
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
            classCode = try TravelClassTypeV2(from: &decoder)
        } else {
            classCode = .second
        }; idx += 1
        if presence[idx] {
            serviceLevel = try decoder.decodeIA5String(
                constraint: ASN1StringConstraint(type: .ia5String, minLength: 1, maxLength: 2)
            )
        }; idx += 1
        if presence[idx] { places = try PlacesTypeV2(from: &decoder) }; idx += 1
        if presence[idx] { additionalPlaces = try PlacesTypeV2(from: &decoder) }; idx += 1
        if presence[idx] { bicyclePlaces = try PlacesTypeV2(from: &decoder) }; idx += 1
        if presence[idx] { compartmentDetails = try CompartmentDetailsTypeV2(from: &decoder) }; idx += 1
        if presence[idx] {
            numberOfOverbooked = try decoder.decodeConstrainedInt(min: 0, max: 200)
        } else {
            numberOfOverbooked = 0
        }; idx += 1
        if presence[idx] { berth = try decoder.decodeSequenceOf() }; idx += 1
        if presence[idx] { tariff = try decoder.decodeSequenceOf() }; idx += 1
        if presence[idx] {
            priceType = try PriceTypeTypeV2(from: &decoder)
        } else {
            priceType = .travelPrice
        }; idx += 1
        if presence[idx] { price = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { vatDetail = try decoder.decodeSequenceOf() }; idx += 1
        if presence[idx] {
            typeOfSupplement = try decoder.decodeConstrainedInt(min: 0, max: 9)
        } else {
            typeOfSupplement = 0
        }; idx += 1
        if presence[idx] {
            numberOfSupplements = try decoder.decodeConstrainedInt(min: 0, max: 200)
        } else {
            numberOfSupplements = 0
        }; idx += 1
        if presence[idx] { luggage = try LuggageRestrictionTypeV2(from: &decoder) }; idx += 1
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

// MARK: - ReservationDataV2 Encoding

extension ReservationDataV2: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        let departureDatePresent = departureDate != nil && departureDate != 0
        let servicePresent = service != nil && service != .seat
        let stationCodeTablePresent = stationCodeTable != nil && stationCodeTable != .stationUICReservation
        let classCodePresent = classCode != nil && classCode != .second
        let numberOfOverbookedPresent = numberOfOverbooked != nil && numberOfOverbooked != 0
        let priceTypePresent = priceType != nil && priceType != .travelPrice
        let typeOfSupplementPresent = typeOfSupplement != nil && typeOfSupplement != 0
        let numberOfSupplementsPresent = numberOfSupplements != nil && numberOfSupplements != 0
        // V2: 43 optional+default fields
        try encoder.encodePresenceBitmap([
            trainNum != nil,
            trainIA5 != nil,
            departureDatePresent,
            referenceIA5 != nil,
            referenceNum != nil,
            productOwnerNum != nil,
            productOwnerIA5 != nil,
            productIdNum != nil,
            productIdIA5 != nil,
            serviceBrand != nil,
            serviceBrandAbrUTF8 != nil,
            serviceBrandNameUTF8 != nil,
            servicePresent,
            stationCodeTablePresent,
            fromStationNum != nil,
            fromStationIA5 != nil,
            toStationNum != nil,
            toStationIA5 != nil,
            fromStationNameUTF8 != nil,
            toStationNameUTF8 != nil,
            // departureTime is mandatory - not in bitmap
            departureUTCOffset != nil,
            arrivalDate != nil && arrivalDate != 0,
            arrivalTime != nil,
            arrivalUTCOffset != nil,
            carrierNum != nil,
            carrierIA5 != nil,
            classCodePresent,
            serviceLevel != nil,
            places != nil,
            additionalPlaces != nil,
            bicyclePlaces != nil,
            compartmentDetails != nil,
            numberOfOverbookedPresent,
            berth != nil,
            tariff != nil,
            priceTypePresent,
            price != nil,
            vatDetail != nil,
            typeOfSupplementPresent,
            numberOfSupplementsPresent,
            luggage != nil,
            infoText != nil,
            extensionData != nil
        ])
        if let v = trainNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = trainIA5 { try encoder.encodeIA5String(v) }
        if departureDatePresent { try encoder.encodeConstrainedInt(departureDate!, min: -1, max: 370) }
        if let v = referenceIA5 { try encoder.encodeIA5String(v) }
        if let v = referenceNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = productOwnerNum { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        if let v = productOwnerIA5 { try encoder.encodeIA5String(v) }
        if let v = productIdNum { try encoder.encodeConstrainedInt(v, min: 0, max: 65535) }
        if let v = productIdIA5 { try encoder.encodeIA5String(v) }
        if let v = serviceBrand { try encoder.encodeConstrainedInt(v, min: 0, max: 32000) }
        if let v = serviceBrandAbrUTF8 { try encoder.encodeUTF8String(v) }
        if let v = serviceBrandNameUTF8 { try encoder.encodeUTF8String(v) }
        if servicePresent { try encoder.encodeEnumerated(service!.rawValue, rootCount: ServiceTypeV2.rootValueCount) }
        if stationCodeTablePresent { try encoder.encodeEnumerated(stationCodeTable!.rawValue, rootCount: CodeTableTypeV2.rootValueCount) }
        if let v = fromStationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = fromStationIA5 { try encoder.encodeIA5String(v) }
        if let v = toStationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = toStationIA5 { try encoder.encodeIA5String(v) }
        if let v = fromStationNameUTF8 { try encoder.encodeUTF8String(v) }
        if let v = toStationNameUTF8 { try encoder.encodeUTF8String(v) }
        // departureTime is MANDATORY
        try encoder.encodeConstrainedInt(departureTime, min: 0, max: 1439)
        if let v = departureUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if let v = arrivalDate, v != 0 { try encoder.encodeConstrainedInt(v, min: -1, max: 20) }
        if let v = arrivalTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1439) }
        if let v = arrivalUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if let v = carrierNum {
            try encoder.encodeLengthDeterminant(v.count)
            for num in v { try encoder.encodeConstrainedInt(num, min: 1, max: 32000) }
        }
        if let v = carrierIA5 {
            try encoder.encodeLengthDeterminant(v.count)
            for s in v { try encoder.encodeIA5String(s) }
        }
        if classCodePresent { try encoder.encodeEnumerated(classCode!.rawValue, rootCount: TravelClassTypeV2.rootValueCount, hasExtensionMarker: TravelClassTypeV2.hasExtensionMarker) }
        if let v = serviceLevel { try encoder.encodeIA5String(v, constraint: ASN1StringConstraint(type: .ia5String, minLength: 1, maxLength: 2)) }
        if let v = places { try v.encode(to: &encoder) }
        if let v = additionalPlaces { try v.encode(to: &encoder) }
        if let v = bicyclePlaces { try v.encode(to: &encoder) }
        if let v = compartmentDetails { try v.encode(to: &encoder) }
        if numberOfOverbookedPresent { try encoder.encodeConstrainedInt(numberOfOverbooked!, min: 0, max: 200) }
        if let v = berth { try encoder.encodeSequenceOf(v) }
        if let v = tariff { try encoder.encodeSequenceOf(v) }
        if priceTypePresent { try encoder.encodeEnumerated(priceType!.rawValue, rootCount: PriceTypeTypeV2.rootValueCount) }
        if let v = price { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = vatDetail { try encoder.encodeSequenceOf(v) }
        if typeOfSupplementPresent { try encoder.encodeConstrainedInt(typeOfSupplement!, min: 0, max: 9) }
        if numberOfSupplementsPresent { try encoder.encodeConstrainedInt(numberOfSupplements!, min: 0, max: 200) }
        if let v = luggage { try v.encode(to: &encoder) }
        if let v = infoText { try encoder.encodeUTF8String(v) }
        if let v = extensionData { try v.encode(to: &encoder) }
    }
}
