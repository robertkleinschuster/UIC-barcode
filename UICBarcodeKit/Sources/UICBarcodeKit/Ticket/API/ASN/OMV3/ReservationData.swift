import Foundation

// MARK: - Reservation Data

/// Reservation ticket data (FCB v3 - 43 optional + 1 mandatory field)
public struct ReservationData: ASN1Decodable {
    public var trainNum: Int?
    public var trainIA5: String?
    public var departureDate: Int?
    public var referenceIA5: String?
    public var referenceNum: Int?
    public var productOwnerNum: Int?
    public var productOwnerIA5: String?
    public var productIdNum: Int?
    public var productIdIA5: String?
    public var serviceBrand: Int?
    public var serviceBrandAbrUTF8: String?
    public var serviceBrandNameUTF8: String?
    public var service: ServiceType?
    public var stationCodeTable: CodeTableType?
    public var fromStationNum: Int?
    public var fromStationIA5: String?
    public var toStationNum: Int?
    public var toStationIA5: String?
    public var fromStationNameUTF8: String?
    public var toStationNameUTF8: String?
    public var departureTime: Int?
    public var departureUTCOffset: Int?
    public var arrivalDate: Int?
    public var arrivalTime: Int?
    public var arrivalUTCOffset: Int?
    public var carrierNum: [Int]?
    public var carrierIA5: [String]?
    public var classCode: TravelClassType?
    public var serviceLevel: String?
    public var places: PlacesType?
    public var additionalPlaces: PlacesType?
    public var bicyclePlaces: PlacesType?
    public var compartmentDetails: CompartmentDetailsType?
    public var numberOfOverbooked: Int?
    public var berth: [BerthDetailData]?
    public var tariff: [TariffType]?
    public var priceType: PriceTypeType?
    public var price: Int?
    public var vatDetails: [VatDetailType]?
    public var typeOfSupplement: Int?
    public var numberOfSupplements: Int?
    public var luggage: LuggageRestrictionType?
    public var infoText: String?
    public var extensionData: ExtensionData?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 43 optional fields; departureTime is mandatory (no presence bit)
        let presence = try decoder.decodePresenceBitmap(count: 43)
        var idx = 0


        if presence[idx] { trainNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { trainIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { departureDate = try decoder.decodeConstrainedInt(min: -1, max: 500) } else { departureDate = 0 }; idx += 1
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
            let value = try decoder.decodeEnumerated(rootCount: 4)
            service = ServiceType(rawValue: value)
        } else {
            service = .seat
        }; idx += 1
        if presence[idx] {
            let value = try decoder.decodeEnumerated(rootCount: 5)
            stationCodeTable = CodeTableType(rawValue: value)
        } else {
            stationCodeTable = .stationUICReservation
        }; idx += 1

        if presence[idx] { fromStationNum = try decoder.decodeConstrainedInt(min: 1, max: 9999999) }; idx += 1
        if presence[idx] { fromStationIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { toStationNum = try decoder.decodeConstrainedInt(min: 1, max: 9999999) }; idx += 1
        if presence[idx] { toStationIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { fromStationNameUTF8 = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] { toStationNameUTF8 = try decoder.decodeUTF8String() }; idx += 1
        // departureTime is MANDATORY (no @Asn1Optional in Java)
        departureTime = try decoder.decodeConstrainedInt(min: 0, max: 1440)

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
            let value = try decoder.decodeEnumerated(rootCount: 12, hasExtensionMarker: true)
            classCode = TravelClassType(rawValue: value)
        } else {
            classCode = .second
        }; idx += 1

        if presence[idx] { serviceLevel = try decoder.decodeIA5String(constraint: ASN1StringConstraint(type: .ia5String, minLength: 1, maxLength: 2)) }; idx += 1
        if presence[idx] { places = try PlacesType(from: &decoder) }; idx += 1
        if presence[idx] { additionalPlaces = try PlacesType(from: &decoder) }; idx += 1
        if presence[idx] { bicyclePlaces = try PlacesType(from: &decoder) }; idx += 1
        if presence[idx] { compartmentDetails = try CompartmentDetailsType(from: &decoder) }; idx += 1
        if presence[idx] {
            numberOfOverbooked = try decoder.decodeConstrainedInt(min: 0, max: 200)
        } else {
            numberOfOverbooked = 0
        }; idx += 1
        if presence[idx] { berth = try decoder.decodeSequenceOf() }; idx += 1
        if presence[idx] { tariff = try decoder.decodeSequenceOf() }; idx += 1
        if presence[idx] {
            let value = try decoder.decodeEnumerated(rootCount: 4)
            priceType = PriceTypeType(rawValue: value)
        } else {
            priceType = .travelPrice
        }; idx += 1
        if presence[idx] { price = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { vatDetails = try decoder.decodeSequenceOf() }; idx += 1
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
        if presence[idx] { luggage = try LuggageRestrictionType(from: &decoder) }; idx += 1
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

// MARK: - ReservationData Encoding

extension ReservationData: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)

        let servicePresent = service != nil && service != .seat
        let stationCodeTablePresent = stationCodeTable != nil && stationCodeTable != .stationUICReservation
        let arrivalDatePresent = arrivalDate != nil && arrivalDate != 0
        let classCodePresent = classCode != nil && classCode != .second
        let numberOfOverbookedPresent = numberOfOverbooked != nil && numberOfOverbooked != 0
        let priceTypePresent = priceType != nil && priceType != .travelPrice
        let typeOfSupplementPresent = typeOfSupplement != nil && typeOfSupplement != 0
        let numberOfSupplementsPresent = numberOfSupplements != nil && numberOfSupplements != 0
        let departureDatePresent = departureDate != nil && departureDate != 0

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
            departureUTCOffset != nil,
            arrivalDatePresent,
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
            vatDetails != nil,
            typeOfSupplementPresent,
            numberOfSupplementsPresent,
            luggage != nil,
            infoText != nil,
            extensionData != nil
        ])

        if let v = trainNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = trainIA5 { try encoder.encodeIA5String(v) }
        if departureDatePresent { try encoder.encodeConstrainedInt(departureDate!, min: -1, max: 500) }
        if let v = referenceIA5 { try encoder.encodeIA5String(v) }
        if let v = referenceNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = productOwnerNum { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        if let v = productOwnerIA5 { try encoder.encodeIA5String(v) }
        if let v = productIdNum { try encoder.encodeConstrainedInt(v, min: 0, max: 65535) }
        if let v = productIdIA5 { try encoder.encodeIA5String(v) }
        if let v = serviceBrand { try encoder.encodeConstrainedInt(v, min: 0, max: 32000) }
        if let v = serviceBrandAbrUTF8 { try encoder.encodeUTF8String(v) }
        if let v = serviceBrandNameUTF8 { try encoder.encodeUTF8String(v) }
        if servicePresent { try encoder.encodeEnumerated(service!.rawValue, rootCount: 4) }
        if stationCodeTablePresent { try encoder.encodeEnumerated(stationCodeTable!.rawValue, rootCount: 5) }
        if let v = fromStationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = fromStationIA5 { try encoder.encodeIA5String(v) }
        if let v = toStationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = toStationIA5 { try encoder.encodeIA5String(v) }
        if let v = fromStationNameUTF8 { try encoder.encodeUTF8String(v) }
        if let v = toStationNameUTF8 { try encoder.encodeUTF8String(v) }
        try encoder.encodeConstrainedInt(departureTime ?? 0, min: 0, max: 1440)
        if let v = departureUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if arrivalDatePresent { try encoder.encodeConstrainedInt(arrivalDate!, min: -1, max: 20) }
        if let v = arrivalTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1439) }
        if let v = arrivalUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if let arr = carrierNum {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        }
        if let arr = carrierIA5 {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeIA5String(v) }
        }
        if classCodePresent { try encoder.encodeEnumerated(classCode!.rawValue, rootCount: 12, hasExtensionMarker: true) }
        if let v = serviceLevel { try encoder.encodeIA5String(v, constraint: ASN1StringConstraint(type: .ia5String, minLength: 1, maxLength: 2)) }
        if let v = places { try v.encode(to: &encoder) }
        if let v = additionalPlaces { try v.encode(to: &encoder) }
        if let v = bicyclePlaces { try v.encode(to: &encoder) }
        if let v = compartmentDetails { try v.encode(to: &encoder) }
        if numberOfOverbookedPresent { try encoder.encodeConstrainedInt(numberOfOverbooked!, min: 0, max: 200) }
        if let arr = berth { try encoder.encodeSequenceOf(arr) }
        if let arr = tariff { try encoder.encodeSequenceOf(arr) }
        if priceTypePresent { try encoder.encodeEnumerated(priceType!.rawValue, rootCount: 4) }
        if let v = price { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let arr = vatDetails { try encoder.encodeSequenceOf(arr) }
        if typeOfSupplementPresent { try encoder.encodeConstrainedInt(typeOfSupplement!, min: 0, max: 9) }
        if numberOfSupplementsPresent { try encoder.encodeConstrainedInt(numberOfSupplements!, min: 0, max: 200) }
        if let v = luggage { try v.encode(to: &encoder) }
        if let v = infoText { try encoder.encodeUTF8String(v) }
        if let v = extensionData { try v.encode(to: &encoder) }
    }
}
