// FCBVersionDecoder.swift
// Decodes FCB data from any version (v1, v2, v3) and converts to v3 UicRailTicketData.

import Foundation

// MARK: - Version Decoder

enum FCBVersionDecoder {

    /// Decode FCB data from the given version into v3 UicRailTicketData.
    /// - Parameters:
    ///   - data: The UPER-encoded FCB data
    ///   - version: FCB version number (1, 2, or 3)
    /// - Returns: Decoded UicRailTicketData (always v3 format)
    static func decode(data: Data, version: Int) throws -> UicRailTicketData {
        var decoder = UPERDecoder(data: data)
        switch version {
        case 1:
            let v1 = try UicRailTicketDataV1(from: &decoder)
            return convertV1ToV3(v1)
        case 2:
            let v2 = try UicRailTicketDataV2(from: &decoder)
            return convertV2ToV3(v2)
        case 3:
            return try UicRailTicketData(from: &decoder)
        default:
            throw UICBarcodeError.invalidData("Unsupported FCB version: \(version)")
        }
    }

    /// Parse an FCB version number from a version string.
    /// - "13" → 1 (v1.3.x), "02" → 2, "03" → 3
    static func parseVersion(_ versionString: String) -> Int {
        switch versionString {
        case "13": return 1
        case "01", "02": return 2
        case "03": return 3
        default:
            return Int(versionString) ?? 3
        }
    }

    /// Parse an FCB version number from a format string.
    /// - "FCB1" → 1, "FCB2" → 2, "FCB3" → 3
    static func parseFormatVersion(_ format: String) -> Int? {
        switch format {
        case "FCB1": return 1
        case "FCB2": return 2
        case "FCB3": return 3
        default: return nil
        }
    }
}

// MARK: - V1 to V3 Conversion

extension FCBVersionDecoder {

    private static func convertV1ToV3(_ v1: UicRailTicketDataV1) -> UicRailTicketData {
        var v3 = UicRailTicketData()
        v3.issuingDetail = convertIssuingDataV1(v1.issuingDetail)
        v3.travelerDetail = v1.travelerDetail.map { convertTravelerDataV1($0) }
        v3.transportDocument = v1.transportDocument?.map { convertDocumentDataV1($0) }
        v3.controlDetail = v1.controlDetail.map { convertControlDataV1($0) }
        v3.extensionData = v1.extensionData?.map { convertExtensionDataV1($0) }
        return v3
    }

    private static func convertIssuingDataV1(_ v1: IssuingDataV1) -> IssuingData {
        var v3 = IssuingData()
        v3.securityProviderNum = v1.securityProviderNum
        v3.securityProviderIA5 = v1.securityProviderIA5
        v3.issuerNum = v1.issuerNum
        v3.issuerIA5 = v1.issuerIA5
        v3.issuingYear = v1.issuingYear
        v3.issuingDay = v1.issuingDay
        v3.issuingTime = v1.issuingTime ?? 0
        v3.issuerName = v1.issuerName
        v3.specimen = v1.specimen
        v3.securePaperTicket = v1.securePaperTicket
        v3.activated = v1.activated
        v3.currency = v1.currency
        v3.currencyFract = v1.currencyFract
        v3.issuerPNR = v1.issuerPNR
        v3.extensionData = v1.extensionData.map { convertExtensionDataV1($0) }
        v3.issuedOnTrainNum = v1.issuedOnTrainNum
        v3.issuedOnTrainIA5 = v1.issuedOnTrainIA5
        v3.issuedOnLine = v1.issuedOnLine
        v3.pointOfSale = v1.pointOfSale.map { convertGeoCoordinateV1($0) }
        return v3
    }

    private static func convertTravelerDataV1(_ v1: TravelerDataV1) -> TravelerData {
        var v3 = TravelerData()
        v3.traveler = v1.traveler?.map { convertTravelerTypeV1($0) }
        v3.preferedLanguage = v1.preferedLanguage
        v3.groupName = v1.groupName
        return v3
    }

    private static func convertTravelerTypeV1(_ v1: TravelerTypeV1) -> TravelerType {
        var v3 = TravelerType()
        v3.firstName = v1.firstName
        v3.secondName = v1.secondName
        v3.lastName = v1.lastName
        v3.idCard = v1.idCard
        v3.passportId = v1.passportId
        v3.title = v1.title
        v3.gender = v1.gender.map { convertGenderV1($0) }
        v3.customerIdIA5 = v1.customerIdIA5
        v3.customerIdNum = v1.customerIdNum
        v3.yearOfBirth = v1.yearOfBirth
        // V1 has no monthOfBirth
        v3.dayOfBirth = v1.dayOfBirth
        v3.ticketHolder = v1.ticketHolder
        v3.passengerType = v1.passengerType.map { convertPassengerTypeV1($0) }
        v3.passengerWithReducedMobility = v1.passengerWithReducedMobility
        v3.countryOfResidence = v1.countryOfResidence
        v3.countryOfPassport = v1.countryOfPassport
        v3.countryOfIdCard = v1.countryOfIdCard
        v3.status = v1.status?.map { convertCustomerStatusTypeV1($0) }
        return v3
    }

    private static func convertCustomerStatusTypeV1(_ v1: CustomerStatusTypeV1) -> CustomerStatusType {
        var v3 = CustomerStatusType()
        v3.statusProviderNum = v1.statusProviderNum
        v3.statusProviderIA5 = v1.statusProviderIA5
        v3.customerStatus = v1.customerStatus
        v3.customerStatusDescr = v1.customerStatusDescr
        return v3
    }

    private static func convertDocumentDataV1(_ v1: DocumentDataV1) -> DocumentData {
        var v3 = DocumentData()
        v3.token = v1.token.map { convertTokenTypeV1($0) }
        v3.ticket = convertTicketDetailDataV1(v1.ticket)
        return v3
    }

    private static func convertTokenTypeV1(_ v1: TokenTypeV1) -> TokenType {
        var v3 = TokenType()
        v3.tokenProviderNum = v1.tokenProviderNum
        v3.tokenProviderIA5 = v1.tokenProviderIA5
        v3.tokenSpecification = v1.tokenSpecification
        v3.token = v1.token
        return v3
    }

    private static func convertTicketDetailDataV1(_ v1: TicketDetailDataV1) -> TicketDetailData {
        var v3 = TicketDetailData()
        if let tt = v1.ticketType {
            switch tt {
            case .reservation(let d): v3.ticketType = .reservation(convertReservationDataV1(d))
            case .carCarriageReservation(let d): v3.ticketType = .carCarriageReservation(convertCarCarriageReservationDataV1(d))
            case .openTicket(let d): v3.ticketType = .openTicket(convertOpenTicketDataV1(d))
            case .pass(let d): v3.ticketType = .pass(convertPassDataV1(d))
            case .voucher(let d): v3.ticketType = .voucher(convertVoucherDataV1(d))
            case .customerCard(let d): v3.ticketType = .customerCard(convertCustomerCardDataV1(d))
            case .countermark(let d): v3.ticketType = .countermark(convertCountermarkDataV1(d))
            case .parkingGround(let d): v3.ticketType = .parkingGround(convertParkingGroundDataV1(d))
            case .fipTicket(let d): v3.ticketType = .fipTicket(convertFIPTicketDataV1(d))
            case .stationPassage(let d): v3.ticketType = .stationPassage(convertStationPassageDataV1(d))
            case .ticketExtension(let d): v3.ticketType = .ticketExtension(convertExtensionDataV1(d))
            case .delayConfirmation(let d): v3.ticketType = .delayConfirmation(convertDelayConfirmationV1(d))
            case .unknown(let d): v3.ticketType = .unknown(d)
            }
        }
        return v3
    }

    private static func convertControlDataV1(_ v1: ControlDataV1) -> ControlData {
        var v3 = ControlData()
        v3.identificationByCardReference = v1.identificationByCardReference?.map { convertCardReferenceTypeV1($0) }
        v3.identificationByIdCard = v1.identificationByIdCard
        v3.identificationByPassportId = v1.identificationByPassportId
        v3.identificationItem = v1.identificationItem
        v3.passportValidationRequired = v1.passportValidationRequired
        v3.onlineValidationRequired = v1.onlineValidationRequired
        v3.randomDetailedValidationRequired = v1.randomDetailedValidationRequired
        v3.ageCheckRequired = v1.ageCheckRequired
        v3.reductionCardCheckRequired = v1.reductionCardCheckRequired
        v3.infoText = v1.infoText
        v3.includedTickets = v1.includedTickets?.map { convertTicketLinkTypeV1($0) }
        v3.extensionData = v1.extensionData.map { convertExtensionDataV1($0) }
        return v3
    }

    private static func convertExtensionDataV1(_ v1: ExtensionDataV1) -> ExtensionData {
        var v3 = ExtensionData()
        v3.extensionId = v1.extensionId
        v3.extensionData = v1.extensionData
        return v3
    }

    private static func convertGeoCoordinateV1(_ v1: GeoCoordinateTypeV1) -> GeoCoordinateType {
        var v3 = GeoCoordinateType()
        v3.geoUnit = v1.geoUnit.map { GeoUnitType(rawValue: $0.rawValue) ?? .milliDegree }
        v3.coordinateSystem = v1.coordinateSystem.map { GeoCoordinateSystemType(rawValue: $0.rawValue) ?? .wgs84 }
        v3.hemisphereLongitude = v1.hemisphereLongitude.map { HemisphereLongitudeType(rawValue: $0.rawValue) ?? .east }
        v3.hemisphereLatitude = v1.hemisphereLatitude.map { HemisphereLatitudeType(rawValue: $0.rawValue) ?? .north }
        v3.longitude = v1.longitude
        v3.latitude = v1.latitude
        v3.accuracy = v1.accuracy.map { GeoUnitType(rawValue: $0.rawValue) ?? .milliDegree }
        return v3
    }

    private static func convertCardReferenceTypeV1(_ v1: CardReferenceTypeV1) -> CardReferenceType {
        var v3 = CardReferenceType()
        v3.cardIssuerNum = v1.cardIssuerNum
        v3.cardIssuerIA5 = v1.cardIssuerIA5
        v3.cardIdNum = v1.cardIdNum
        v3.cardIdIA5 = v1.cardIdIA5
        v3.cardName = v1.cardName
        v3.cardType = v1.cardType
        v3.leadingCardIdNum = v1.leadingCardIdNum
        v3.leadingCardIdIA5 = v1.leadingCardIdIA5
        v3.trailingCardIdNum = v1.trailingCardIdNum
        v3.trailingCardIdIA5 = v1.trailingCardIdIA5
        return v3
    }

    private static func convertTicketLinkTypeV1(_ v1: TicketLinkTypeV1) -> TicketLinkType {
        var v3 = TicketLinkType()
        v3.referenceIA5 = v1.referenceIA5
        v3.referenceNum = v1.referenceNum
        v3.issuerName = v1.issuerName
        v3.issuerPNR = v1.issuerPNR
        v3.productOwnerNum = v1.productOwnerNum
        v3.productOwnerIA5 = v1.productOwnerIA5
        v3.ticketType = v1.ticketType.map { TicketType(rawValue: $0.rawValue) ?? .openTicket }
        v3.linkMode = v1.linkMode.map { LinkMode(rawValue: $0.rawValue) ?? .issuedTogether }
        return v3
    }

    // MARK: - V1 Ticket Type Conversions

    private static func convertReservationDataV1(_ v1: ReservationDataV1) -> ReservationData {
        var v3 = ReservationData()
        v3.trainNum = v1.trainNum
        v3.trainIA5 = v1.trainIA5
        v3.departureDate = v1.departureDate
        v3.referenceIA5 = v1.referenceIA5
        v3.referenceNum = v1.referenceNum
        v3.productOwnerNum = v1.productOwnerNum
        v3.productOwnerIA5 = v1.productOwnerIA5
        v3.productIdNum = v1.productIdNum
        v3.productIdIA5 = v1.productIdIA5
        v3.serviceBrand = v1.serviceBrand
        v3.serviceBrandAbrUTF8 = v1.serviceBrandAbrUTF8
        v3.serviceBrandNameUTF8 = v1.serviceBrandNameUTF8
        v3.service = v1.service.map { ServiceType(rawValue: $0.rawValue) ?? .seat }
        v3.stationCodeTable = v1.stationCodeTable.map { convertCodeTableV1($0) }
        v3.fromStationNum = v1.fromStationNum
        v3.fromStationIA5 = v1.fromStationIA5
        v3.fromStationNameUTF8 = v1.fromStationNameUTF8
        v3.toStationNum = v1.toStationNum
        v3.toStationIA5 = v1.toStationIA5
        v3.toStationNameUTF8 = v1.toStationNameUTF8
        v3.departureTime = v1.departureTime
        v3.departureUTCOffset = v1.departureUTCOffset
        v3.arrivalDate = v1.arrivalDate
        v3.arrivalTime = v1.arrivalTime
        v3.arrivalUTCOffset = v1.arrivalUTCOffset
        v3.carrierNum = v1.carrierNum
        v3.carrierIA5 = v1.carrierIA5
        v3.classCode = v1.classCode.map { convertTravelClassV1($0) }
        v3.serviceLevel = v1.serviceLevel
        v3.places = v1.places.map { convertPlacesTypeV1($0) }
        v3.additionalPlaces = v1.additionalPlaces.map { convertPlacesTypeV1($0) }
        v3.bicyclePlaces = v1.bicyclePlaces.map { convertPlacesTypeV1($0) }
        v3.compartmentDetails = v1.compartmentDetails.map { convertCompartmentDetailsTypeV1($0) }
        v3.numberOfOverbooked = v1.numberOfOverbooked
        v3.berth = v1.berth?.map { convertBerthDetailDataV1($0) }
        v3.tariff = v1.tariff?.map { convertTariffTypeV1($0) }
        v3.priceType = v1.priceType.map { PriceTypeType(rawValue: $0.rawValue) ?? .travelPrice }
        v3.price = v1.price
        v3.vatDetails = v1.vatDetail?.map { convertVatDetailTypeV1($0) }
        v3.typeOfSupplement = v1.typeOfSupplement
        v3.numberOfSupplements = v1.numberOfSupplements
        v3.luggage = v1.luggage.map { convertLuggageRestrictionTypeV1($0) }
        v3.infoText = v1.infoText
        v3.extensionData = v1.extensionData.map { convertExtensionDataV1($0) }
        return v3
    }

    private static func convertOpenTicketDataV1(_ v1: OpenTicketDataV1) -> OpenTicketData {
        var v3 = OpenTicketData()
        v3.referenceIA5 = v1.referenceIA5
        v3.referenceNum = v1.referenceNum
        v3.productOwnerNum = v1.productOwnerNum
        v3.productOwnerIA5 = v1.productOwnerIA5
        v3.productIdNum = v1.productIdNum
        v3.productIdIA5 = v1.productIdIA5
        v3.externalIssuerId = v1.extIssuerId
        v3.issuerAutorizationId = v1.issuerAuthorizationId
        v3.returnIncluded = v1.returnIncluded
        v3.stationCodeTable = v1.stationCodeTable.map { convertCodeTableV1($0) }
        v3.fromStationNum = v1.fromStationNum
        v3.fromStationIA5 = v1.fromStationIA5
        v3.toStationNum = v1.toStationNum
        v3.toStationIA5 = v1.toStationIA5
        v3.fromStationNameUTF8 = v1.fromStationNameUTF8
        v3.toStationNameUTF8 = v1.toStationNameUTF8
        v3.validRegionDesc = v1.validRegionDesc
        v3.validRegion = v1.validRegion?.map { convertRegionalValidityTypeV1($0) }
        v3.returnDescription = v1.returnDescription.map { convertReturnRouteDescriptionTypeV1($0) }
        v3.validFromDay = v1.validFromDay
        v3.validFromTime = v1.validFromTime
        v3.validFromUTCOffset = v1.validFromUTCOffset
        v3.validUntilDay = v1.validUntilDay
        v3.validUntilTime = v1.validUntilTime
        v3.validUntilUTCOffset = v1.validUntilUTCOffset
        v3.activatedDay = v1.activatedDay
        v3.classCode = v1.classCode.map { convertTravelClassV1($0) }
        v3.serviceLevel = v1.serviceLevel
        v3.carrierNum = v1.carrierNum
        v3.carrierIA5 = v1.carrierIA5
        v3.includedServiceBrands = v1.includedServiceBrands
        v3.excludedServiceBrands = v1.excludedServiceBrands
        v3.tariffs = v1.tariffs?.map { convertTariffTypeV1($0) }
        v3.price = v1.price
        v3.vatDetails = v1.vatDetail?.map { convertVatDetailTypeV1($0) }
        v3.infoText = v1.infoText
        v3.includedAddOns = v1.includedAddOns?.map { convertIncludedOpenTicketTypeV1($0) }
        v3.luggage = v1.luggage.map { convertLuggageRestrictionTypeV1($0) }
        v3.extensionData = v1.extensionData.map { convertExtensionDataV1($0) }
        return v3
    }

    private static func convertPassDataV1(_ v1: PassDataV1) -> PassData {
        var v3 = PassData()
        v3.referenceIA5 = v1.referenceIA5
        v3.referenceNum = v1.referenceNum
        v3.productOwnerNum = v1.productOwnerNum
        v3.productOwnerIA5 = v1.productOwnerIA5
        v3.productIdNum = v1.productIdNum
        v3.productIdIA5 = v1.productIdIA5
        v3.passType = v1.passType
        v3.passDescription = v1.passDescription
        v3.classCode = v1.classCode.map { convertTravelClassV1($0) }
        v3.validFromDay = v1.validFromDay
        v3.validFromTime = v1.validFromTime
        v3.validFromUTCOffset = v1.validFromUTCOffset
        v3.validUntilDay = v1.validUntilDay
        v3.validUntilTime = v1.validUntilTime
        v3.validUntilUTCOffset = v1.validUntilUTCOffset
        v3.validityPeriodDetails = v1.validityPeriodDetails.map { convertValidityPeriodDetailTypeV1($0) }
        v3.numberOfValidityDays = v1.numberOfValidityDays
        v3.numberOfPossibleTrips = v1.numberOfPossibleTrips
        v3.numberOfDaysOfTravel = v1.numberOfDaysOfTravel
        v3.activatedDay = v1.activatedDay?.map { $0 }
        v3.countries = v1.countries
        v3.includedCarrierNum = v1.includedCarrierNum
        v3.includedCarrierIA5 = v1.includedCarrierIA5
        v3.excludedCarrierNum = v1.excludedCarrierNum
        v3.excludedCarrierIA5 = v1.excludedCarrierIA5
        v3.includedServiceBrands = v1.includedServiceBrands
        v3.excludedServiceBrands = v1.excludedServiceBrands
        v3.validRegion = v1.validRegion?.map { convertRegionalValidityTypeV1($0) }
        v3.tariffs = v1.tariffs?.map { convertTariffTypeV1($0) }
        v3.price = v1.price
        v3.vatDetails = v1.vatDetail?.map { convertVatDetailTypeV1($0) }
        v3.infoText = v1.infoText
        v3.extensionData = v1.extensionData.map { convertExtensionDataV1($0) }
        // V1 has no trainValidity
        return v3
    }

    private static func convertCarCarriageReservationDataV1(_ v1: CarCarriageReservationDataV1) -> CarCarriageReservationData {
        var v3 = CarCarriageReservationData()
        v3.trainNum = v1.trainNum
        v3.trainIA5 = v1.trainIA5
        v3.beginLoadingDate = v1.beginLoadingDate
        v3.beginLoadingTime = v1.beginLoadingTime
        v3.endLoadingTime = v1.endLoadingTime
        v3.referenceIA5 = v1.referenceIA5
        v3.referenceNum = v1.referenceNum
        v3.productOwnerNum = v1.productOwnerNum
        v3.productOwnerIA5 = v1.productOwnerIA5
        v3.productIdNum = v1.productIdNum
        v3.productIdIA5 = v1.productIdIA5
        v3.serviceBrand = v1.serviceBrand
        v3.serviceBrandAbrUTF8 = v1.serviceBrandAbrUTF8
        v3.serviceBrandNameUTF8 = v1.serviceBrandNameUTF8
        v3.stationCodeTable = v1.stationCodeTable.map { convertCodeTableV1($0) }
        v3.fromStationNum = v1.fromStationNum
        v3.fromStationIA5 = v1.fromStationIA5
        v3.toStationNum = v1.toStationNum
        v3.toStationIA5 = v1.toStationIA5
        v3.fromStationNameUTF8 = v1.fromStationNameUTF8
        v3.toStationNameUTF8 = v1.toStationNameUTF8
        v3.coach = v1.coach
        v3.place = v1.place
        v3.compartmentDetails = v1.compartmentDetails.map { convertCompartmentDetailsTypeV1($0) }
        v3.numberPlate = v1.numberPlate
        v3.trailerPlate = v1.trailerPlate
        v3.carCategory = v1.carCategory
        v3.boatCategory = v1.boatCategory
        v3.textileRoof = v1.textileRoof
        v3.roofRackType = v1.roofRackType.map { RoofRackType(rawValue: $0.rawValue) ?? .norack }
        v3.roofRackHeight = v1.roofRackHeight
        v3.attachedBoats = v1.attachedBoats
        v3.attachedBicycles = v1.attachedBicycles
        v3.attachedSurfboards = v1.attachedSurfboards
        v3.loadingListEntry = v1.loadingListEntry
        v3.loadingDeck = v1.loadingDeck.map { LoadingDeckType(rawValue: $0.rawValue) ?? .upper }
        v3.loadingUTCOffset = v1.loadingUTCOffset
        v3.carrierNum = v1.carrierNum
        v3.carrierIA5 = v1.carrierIA5
        v3.tariff = convertTariffTypeV1(v1.tariff)
        v3.priceType = v1.priceType.map { PriceTypeType(rawValue: $0.rawValue) ?? .travelPrice }
        v3.price = v1.price
        v3.vatDetails = v1.vatDetail?.map { convertVatDetailTypeV1($0) }
        v3.infoText = v1.infoText
        v3.extensionData = v1.extensionData.map { convertExtensionDataV1($0) }
        return v3
    }

    private static func convertCountermarkDataV1(_ v1: CountermarkDataV1) -> CountermarkData {
        var v3 = CountermarkData()
        v3.referenceIA5 = v1.referenceIA5
        v3.referenceNum = v1.referenceNum
        v3.productOwnerNum = v1.productOwnerNum
        v3.productOwnerIA5 = v1.productOwnerIA5
        v3.productIdNum = v1.productIdNum
        v3.productIdIA5 = v1.productIdIA5
        v3.ticketReferenceIA5 = v1.ticketReferenceIA5
        v3.ticketReferenceNum = v1.ticketReferenceNum
        v3.numberOfCountermark = v1.numberOfCountermark
        v3.totalOfCountermarks = v1.totalOfCountermarks
        v3.groupName = v1.groupName
        v3.stationCodeTable = v1.stationCodeTable.map { convertCodeTableV1($0) }
        v3.fromStationNum = v1.fromStationNum
        v3.fromStationIA5 = v1.fromStationIA5
        v3.toStationNum = v1.toStationNum
        v3.toStationIA5 = v1.toStationIA5
        v3.fromStationNameUTF8 = v1.fromStationNameUTF8
        v3.toStationNameUTF8 = v1.toStationNameUTF8
        v3.validRegionDesc = v1.validRegionDesc
        v3.validRegion = v1.validRegion?.map { convertRegionalValidityTypeV1($0) }
        v3.returnIncluded = v1.returnIncluded
        v3.returnDescription = v1.returnDescription.map { convertReturnRouteDescriptionTypeV1($0) }
        v3.validFromDay = v1.validFromDay
        v3.validFromTime = v1.validFromTime
        v3.validFromUTCOffset = v1.validFromUTCOffset
        v3.validUntilDay = v1.validUntilDay
        v3.validUntilTime = v1.validUntilTime
        v3.validUntilUTCOffset = v1.validUntilUTCOffset
        v3.classCode = v1.classCode.map { convertTravelClassV1($0) }
        v3.carrierNum = v1.carrierNum
        v3.carrierIA5 = v1.carrierIA5
        v3.includedServiceBrands = v1.includedServiceBrands
        v3.excludedServiceBrands = v1.excludedServiceBrands
        v3.infoText = v1.infoText
        v3.extensionData = v1.extensionData.map { convertExtensionDataV1($0) }
        return v3
    }

    private static func convertVoucherDataV1(_ v1: VoucherDataV1) -> VoucherData {
        var v3 = VoucherData()
        v3.referenceIA5 = v1.referenceIA5
        v3.referenceNum = v1.referenceNum
        v3.productOwnerNum = v1.productOwnerNum
        v3.productOwnerIA5 = v1.productOwnerIA5
        v3.productIdNum = v1.productIdNum
        v3.productIdIA5 = v1.productIdIA5
        v3.validFromYear = v1.validFromYear
        v3.validFromDay = v1.validFromDay
        v3.validUntilYear = v1.validUntilYear
        v3.validUntilDay = v1.validUntilDay
        v3.value = v1.value
        v3.voucherType = v1.type
        v3.infoText = v1.infoText
        v3.extensionData = v1.extensionData.map { convertExtensionDataV1($0) }
        return v3
    }

    private static func convertCustomerCardDataV1(_ v1: CustomerCardDataV1) -> CustomerCardData {
        var v3 = CustomerCardData()
        v3.customer = v1.customer.map { convertTravelerTypeV1($0) }
        v3.cardIdIA5 = v1.cardIdIA5
        v3.cardIdNum = v1.cardIdNum
        v3.validFromYear = v1.validFromYear
        v3.validFromDay = v1.validFromDay
        v3.validUntilYear = v1.validUntilYear
        v3.validUntilDay = v1.validUntilDay
        v3.classCode = v1.classCode.map { convertTravelClassV1($0) }
        v3.cardType = v1.cardType
        v3.cardTypeDescr = v1.cardTypeDescr
        v3.customerStatus = v1.customerStatus
        v3.customerStatusDescr = v1.customerStatusDescr
        v3.includedServices = v1.includedServices
        v3.extensionData = v1.extensionData.map { convertExtensionDataV1($0) }
        return v3
    }

    private static func convertParkingGroundDataV1(_ v1: ParkingGroundDataV1) -> ParkingGroundData {
        var v3 = ParkingGroundData()
        v3.referenceIA5 = v1.referenceIA5
        v3.referenceNum = v1.referenceNum
        v3.parkingGroundId = v1.parkingGroundId
        v3.fromParkingDate = v1.fromParkingDate
        v3.toParkingDate = v1.untilParkingDate
        v3.productOwnerNum = v1.productOwnerNum
        v3.productOwnerIA5 = v1.productOwnerIA5
        v3.productIdNum = v1.productIdNum
        v3.productIdIA5 = v1.productIdIA5
        v3.accessCode = v1.accessCode
        v3.location = v1.location
        v3.stationCodeTable = v1.stationCodeTable.map { convertCodeTableV1($0) }
        v3.stationNum = v1.stationNum
        v3.stationIA5 = v1.stationIA5
        v3.specialInformation = v1.specialInformation
        v3.entryTrack = v1.entryTrack
        v3.numberPlate = v1.numberPlate
        v3.price = v1.price
        v3.vatDetails = v1.vatDetail?.map { convertVatDetailTypeV1($0) }
        v3.extensionData = v1.extensionData.map { convertExtensionDataV1($0) }
        return v3
    }

    private static func convertFIPTicketDataV1(_ v1: FIPTicketDataV1) -> FIPTicketData {
        var v3 = FIPTicketData()
        v3.referenceIA5 = v1.referenceIA5
        v3.referenceNum = v1.referenceNum
        v3.productOwnerNum = v1.productOwnerNum
        v3.productOwnerIA5 = v1.productOwnerIA5
        v3.productIdNum = v1.productIdNum
        v3.productIdIA5 = v1.productIdIA5
        v3.validFromDay = v1.validFromDay
        v3.validUntilDay = v1.validUntilDay
        v3.activatedDay = v1.activatedDay?.map { $0 }
        v3.carrierNum = v1.carrierNum
        v3.carrierIA5 = v1.carrierIA5
        v3.numberOfTravelDays = v1.numberOfTravelDays
        v3.includesSupplements = v1.includesSupplements
        v3.classCode = v1.classCode.map { convertTravelClassV1($0) }
        v3.extensionData = v1.extensionData.map { convertExtensionDataV1($0) }
        return v3
    }

    private static func convertStationPassageDataV1(_ v1: StationPassageDataV1) -> StationPassageData {
        var v3 = StationPassageData()
        v3.referenceIA5 = v1.referenceIA5
        v3.referenceNum = v1.referenceNum
        v3.productOwnerNum = v1.productOwnerNum
        v3.productOwnerIA5 = v1.productOwnerIA5
        v3.productIdNum = v1.productIdNum
        v3.productIdIA5 = v1.productIdIA5
        v3.productName = v1.productName
        v3.stationCodeTable = v1.stationCodeTable.map { convertCodeTableV1($0) }
        v3.stationNum = v1.stationNum?.map { $0 }
        v3.stationIA5 = v1.stationIA5
        v3.stationNameUTF8 = v1.stationNameUTF8
        v3.areaCodeNum = v1.areaCodeNum?.map { $0 }
        v3.areaCodeIA5 = v1.areaCodeIA5
        v3.areaNameUTF8 = v1.areaNameUTF8
        v3.validFromDay = v1.validFromDay
        v3.validFromTime = v1.validFromTime
        v3.validFromUTCOffset = v1.validFromUTCOffset
        v3.validUntilDay = v1.validUntilDay
        v3.validUntilTime = v1.validUntilTime
        v3.validUntilUTCOffset = v1.validUntilUTCOffset
        v3.numberOfDaysValid = v1.numberOfDaysValid
        v3.extensionData = v1.extensionData.map { convertExtensionDataV1($0) }
        return v3
    }

    private static func convertDelayConfirmationV1(_ v1: DelayConfirmationV1) -> DelayConfirmation {
        var v3 = DelayConfirmation()
        v3.referenceIA5 = v1.referenceIA5
        v3.referenceNum = v1.referenceNum
        v3.trainNum = v1.trainNum
        v3.trainIA5 = v1.trainIA5
        v3.plannedArrivalYear = v1.departureYear
        v3.plannedArrivalDay = v1.departureDay
        v3.plannedArrivalTime = v1.departureTime
        v3.departureUTCOffset = v1.departureUTCOffset
        v3.stationCodeTable = v1.stationCodeTable.map { convertCodeTableV1($0) }
        v3.stationNum = v1.stationNum
        v3.stationIA5 = v1.stationIA5
        v3.delay = v1.delay
        v3.trainCancelled = v1.trainCancelled
        v3.confirmationType = v1.confirmationType.map { ConfirmationTypeType(rawValue: $0.rawValue) ?? .trainDelayConfirmation }
        v3.affectedTickets = v1.affectedTickets?.map { convertTicketLinkTypeV1($0) }
        v3.infoText = v1.infoText
        v3.extensionData = v1.extensionData.map { convertExtensionDataV1($0) }
        return v3
    }

    // MARK: - V1 Supporting Type Conversions

    private static func convertPlacesTypeV1(_ v1: PlacesTypeV1) -> PlacesType {
        var v3 = PlacesType()
        v3.coach = v1.coach
        v3.placeString = v1.placeString
        v3.placeDescription = v1.placeDescription
        v3.placeIA5 = v1.placeIA5
        v3.placeNum = v1.placeNum?.map { $0 }
        return v3
    }

    private static func convertCompartmentDetailsTypeV1(_ v1: CompartmentDetailsTypeV1) -> CompartmentDetailsType {
        var v3 = CompartmentDetailsType()
        v3.coachType = v1.coachType
        v3.compartmentType = v1.compartmentType
        v3.specialAllocation = v1.specialAllocation
        v3.coachTypeDescr = v1.coachTypeDescr
        v3.compartmentTypeDescr = v1.compartmentTypeDescr
        v3.specialAllocationDescr = v1.specialAllocationDescr
        v3.position = v1.position.map { CompartmentPositionType(rawValue: $0.rawValue) ?? .unspecified }
        return v3
    }

    private static func convertBerthDetailDataV1(_ v1: BerthDetailDataV1) -> BerthDetailData {
        var v3 = BerthDetailData()
        v3.berthType = BerthTypeType(rawValue: v1.berthType.rawValue)
        v3.numberOfBerths = v1.numberOfBerths
        v3.gender = v1.gender.map { CompartmentGenderType(rawValue: $0.rawValue) ?? .unspecified }
        return v3
    }

    private static func convertTariffTypeV1(_ v1: TariffTypeV1) -> TariffType {
        var v3 = TariffType()
        v3.numberOfPassengers = v1.numberOfPassengers
        v3.passengerType = v1.passengerType.map { PassengerType(rawValue: $0.rawValue) ?? .adult }
        v3.ageBelow = v1.ageBelow
        v3.ageAbove = v1.ageAbove
        v3.travelerid = v1.travelerid?.map { $0 }
        v3.restrictedToCountryOfResidence = v1.restrictedToCountryOfResidence
        v3.restrictedToRouteSection = v1.restrictedToRouteSection.map { convertRouteSectionTypeV1($0) }
        v3.seriesDataDetails = v1.seriesDataDetails.map { convertSeriesDetailTypeV1($0) }
        v3.tariffIdNum = v1.tariffIdNum
        v3.tariffIdIA5 = v1.tariffIdIA5
        v3.tariffDesc = v1.tariffDesc
        v3.reductionCard = v1.reductionCard?.map { convertCardReferenceTypeV1($0) }
        return v3
    }

    private static func convertVatDetailTypeV1(_ v1: VatDetailTypeV1) -> VatDetailType {
        var v3 = VatDetailType()
        v3.country = v1.country
        v3.percentage = v1.percentage
        v3.amount = v1.amount
        v3.vatId = v1.vatId
        return v3
    }

    private static func convertRegionalValidityTypeV1(_ v1: RegionalValidityTypeV1) -> RegionalValidityType {
        var v3 = RegionalValidityType()
        guard let rt = v1.validity else { return v3 }
        switch rt {
        case .trainLink(let d): v3.validity = .trainLink(convertTrainLinkTypeV1(d))
        case .viaStations(let d): v3.validity = .viaStations(convertViaStationTypeV1(d))
        case .zone(let d): v3.validity = .zone(convertZoneTypeV1(d))
        case .line(let d): v3.validity = .line(convertLineTypeV1(d))
        case .polygone(let d): v3.validity = .polygone(convertPolygoneTypeV1(d))
        }
        return v3
    }

    private static func convertTrainLinkTypeV1(_ v1: TrainLinkTypeV1) -> TrainLinkType {
        var v3 = TrainLinkType()
        v3.trainNum = v1.trainNum
        v3.trainIA5 = v1.trainIA5
        v3.travelDate = v1.travelDate
        v3.departureTime = v1.departureTime
        v3.departureUTCOffset = v1.departureUTCOffset
        v3.fromStationNum = v1.fromStationNum
        v3.fromStationIA5 = v1.fromStationIA5
        v3.fromStationNameUTF8 = v1.fromStationNameUTF8
        v3.toStationNum = v1.toStationNum
        v3.toStationIA5 = v1.toStationIA5
        v3.toStationNameUTF8 = v1.toStationNameUTF8
        return v3
    }

    private static func convertViaStationTypeV1(_ v1: ViaStationTypeV1) -> ViaStationType {
        var v3 = ViaStationType()
        v3.stationCodeTable = v1.stationCodeTable.map { convertCodeTableV1($0) }
        v3.stationNum = v1.stationNum
        v3.stationIA5 = v1.stationIA5
        v3.alternativeRoutes = v1.alternativeRoutes?.map { convertViaStationTypeV1($0) }
        v3.route = v1.route?.map { convertViaStationTypeV1($0) }
        v3.border = v1.border
        v3.carriersNum = v1.carriersNum
        v3.carriersIA5 = v1.carriersIA5
        v3.seriesId = v1.seriesId
        v3.routeId = v1.routeId
        return v3
    }

    private static func convertZoneTypeV1(_ v1: ZoneTypeV1) -> ZoneType {
        var v3 = ZoneType()
        v3.carrierNum = v1.carrierNum
        v3.carrierIA5 = v1.carrierIA5
        v3.stationCodeTable = v1.stationCodeTable.map { convertCodeTableV1($0) }
        v3.entryStationNum = v1.entryStationNum
        v3.entryStationIA5 = v1.entryStationIA5
        v3.terminatingStationNum = v1.terminatingStationNum
        v3.terminatingStationIA5 = v1.terminatingStationIA5
        v3.city = v1.city
        v3.zoneId = v1.zoneId?.map { $0 }
        v3.binaryZoneId = v1.binaryZoneId
        v3.nutsCode = v1.nutsCode
        return v3
    }

    private static func convertLineTypeV1(_ v1: LineTypeV1) -> LineType {
        var v3 = LineType()
        v3.carrierNum = v1.carrierNum
        v3.carrierIA5 = v1.carrierIA5
        v3.lineId = v1.lineId?.map { $0 }
        v3.stationCodeTable = v1.stationCodeTable.map { convertCodeTableV1($0) }
        v3.entryStationNum = v1.entryStationNum
        v3.entryStationIA5 = v1.entryStationIA5
        v3.terminatingStationNum = v1.terminatingStationNum
        v3.terminatingStationIA5 = v1.terminatingStationIA5
        v3.city = v1.city
        return v3
    }

    private static func convertPolygoneTypeV1(_ v1: PolygoneTypeV1) -> PolygoneType {
        var v3 = PolygoneType()
        v3.firstEdge = convertGeoCoordinateV1(v1.firstEdge)
        v3.edges = v1.edges.map { convertDeltaCoordinatesV1($0) }
        return v3
    }

    private static func convertDeltaCoordinatesV1(_ v1: DeltaCoordinatesV1) -> DeltaCoordinates {
        var v3 = DeltaCoordinates()
        v3.longitude = v1.longitude
        v3.latitude = v1.latitude
        return v3
    }

    private static func convertRouteSectionTypeV1(_ v1: RouteSectionTypeV1) -> RouteSectionType {
        var v3 = RouteSectionType()
        v3.stationCodeTable = v1.stationCodeTable.map { convertCodeTableV1($0) }
        v3.fromStationNum = v1.fromStationNum
        v3.fromStationIA5 = v1.fromStationIA5
        v3.fromStationNameUTF8 = v1.fromStationNameUTF8
        v3.toStationNum = v1.toStationNum
        v3.toStationIA5 = v1.toStationIA5
        v3.toStationNameUTF8 = v1.toStationNameUTF8
        return v3
    }

    private static func convertSeriesDetailTypeV1(_ v1: SeriesDetailTypeV1) -> SeriesDetailType {
        var v3 = SeriesDetailType()
        v3.supplyingCarrier = v1.supplyingCarrier
        v3.offerIdentification = v1.offerIdentification
        v3.series = v1.series
        return v3
    }

    private static func convertValidityPeriodDetailTypeV1(_ v1: ValidityPeriodDetailTypeV1) -> ValidityPeriodDetailType {
        var v3 = ValidityPeriodDetailType()
        v3.validityPeriod = v1.validityPeriod?.map { convertValidityPeriodTypeV1($0) }
        v3.excludedTimeRange = v1.excludedTimeRange?.map { convertTimeRangeTypeV1($0) }
        return v3
    }

    private static func convertValidityPeriodTypeV1(_ v1: ValidityPeriodTypeV1) -> ValidityPeriodType {
        var v3 = ValidityPeriodType()
        v3.validFromDay = v1.validFromDay
        v3.validFromTime = v1.validFromTime
        v3.validFromUTCOffset = v1.validFromUTCOffset
        v3.validUntilDay = v1.validUntilDay
        v3.validUntilTime = v1.validUntilTime
        v3.validUntilUTCOffset = v1.validUntilUTCOffset
        return v3
    }

    private static func convertTimeRangeTypeV1(_ v1: TimeRangeTypeV1) -> TimeRangeType {
        var v3 = TimeRangeType()
        v3.fromTime = v1.fromTime
        v3.untilTime = v1.untilTime
        return v3
    }

    private static func convertReturnRouteDescriptionTypeV1(_ v1: ReturnRouteDescriptionTypeV1) -> ReturnRouteDescriptionType {
        var v3 = ReturnRouteDescriptionType()
        v3.fromStationNum = v1.fromStationNum
        v3.fromStationIA5 = v1.fromStationIA5
        v3.toStationNum = v1.toStationNum
        v3.toStationIA5 = v1.toStationIA5
        v3.fromStationNameUTF8 = v1.fromStationNameUTF8
        v3.toStationNameUTF8 = v1.toStationNameUTF8
        v3.validReturnRegionDesc = v1.validReturnRegionDesc
        v3.validReturnRegion = v1.validReturnRegion?.map { convertRegionalValidityTypeV1($0) }
        return v3
    }

    private static func convertIncludedOpenTicketTypeV1(_ v1: IncludedOpenTicketTypeV1) -> IncludedOpenTicketType {
        var v3 = IncludedOpenTicketType()
        v3.productOwnerNum = v1.productOwnerNum
        v3.productOwnerIA5 = v1.productOwnerIA5
        v3.productIdNum = v1.productIdNum
        v3.productIdIA5 = v1.productIdIA5
        v3.externalIssuerId = v1.externalIssuerId
        v3.issuerAutorizationId = v1.issuerAuthorizationId
        v3.stationCodeTable = v1.stationCodeTable.map { convertCodeTableV1($0) }
        v3.validRegion = v1.validRegion?.map { convertRegionalValidityTypeV1($0) }
        v3.validFromDay = v1.validFromDay
        v3.validFromTime = v1.validFromTime
        v3.validFromUTCOffset = v1.validFromUTCOffset
        v3.validUntilDay = v1.validUntilDay
        v3.validUntilTime = v1.validUntilTime
        v3.validUntilUTCOffset = v1.validUntilUTCOffset
        v3.classCode = v1.classCode.map { convertTravelClassV1($0) }
        v3.serviceLevel = v1.serviceLevel
        v3.carrierNum = v1.carrierNum
        v3.carrierIA5 = v1.carrierIA5
        v3.includedServiceBrands = v1.includedServiceBrands
        v3.excludedServiceBrands = v1.excludedServiceBrands
        v3.tariffs = v1.tariffs?.map { convertTariffTypeV1($0) }
        v3.infoText = v1.infoText
        v3.extensionData = v1.extensionData.map { convertExtensionDataV1($0) }
        return v3
    }

    private static func convertLuggageRestrictionTypeV1(_ v1: LuggageRestrictionTypeV1) -> LuggageRestrictionType {
        var v3 = LuggageRestrictionType()
        v3.maxHandLuggagePieces = v1.maxHandLuggagePieces
        v3.maxNonHandLuggagePieces = v1.maxNonHandLuggagePieces
        v3.registeredLuggage = v1.registeredLuggage?.map { convertRegisteredLuggageTypeV1($0) }
        return v3
    }

    private static func convertRegisteredLuggageTypeV1(_ v1: RegisteredLuggageTypeV1) -> RegisteredLuggageType {
        var v3 = RegisteredLuggageType()
        v3.registrationId = v1.registrationId
        v3.maxWeight = v1.maxWeight
        v3.maxSize = v1.maxSize
        return v3
    }

    // MARK: - V1 Enum Conversions

    private static func convertTravelClassV1(_ v1: TravelClassTypeV1) -> TravelClassType {
        return TravelClassType(rawValue: v1.rawValue) ?? .second
    }

    private static func convertCodeTableV1(_ v1: CodeTableTypeV1) -> CodeTableType {
        return CodeTableType(rawValue: v1.rawValue) ?? .stationUIC
    }

    private static func convertGenderV1(_ v1: GenderTypeV1) -> GenderType {
        return GenderType(rawValue: v1.rawValue) ?? .unspecified
    }

    private static func convertPassengerTypeV1(_ v1: PassengerTypeV1) -> PassengerType {
        return PassengerType(rawValue: v1.rawValue) ?? .adult
    }
}

// MARK: - V2 to V3 Conversion

extension FCBVersionDecoder {

    private static func convertV2ToV3(_ v2: UicRailTicketDataV2) -> UicRailTicketData {
        var v3 = UicRailTicketData()
        v3.issuingDetail = convertIssuingDataV2(v2.issuingDetail)
        v3.travelerDetail = v2.travelerDetail.map { convertTravelerDataV2($0) }
        v3.transportDocument = v2.transportDocument?.map { convertDocumentDataV2($0) }
        v3.controlDetail = v2.controlDetail.map { convertControlDataV2($0) }
        v3.extensionData = v2.extensionData?.map { convertExtensionDataV2($0) }
        return v3
    }

    private static func convertIssuingDataV2(_ v2: IssuingDataV2) -> IssuingData {
        var v3 = IssuingData()
        v3.securityProviderNum = v2.securityProviderNum
        v3.securityProviderIA5 = v2.securityProviderIA5
        v3.issuerNum = v2.issuerNum
        v3.issuerIA5 = v2.issuerIA5
        v3.issuingYear = v2.issuingYear
        v3.issuingDay = v2.issuingDay
        v3.issuingTime = v2.issuingTime ?? 0
        v3.issuerName = v2.issuerName
        v3.specimen = v2.specimen
        v3.securePaperTicket = v2.securePaperTicket
        v3.activated = v2.activated
        v3.currency = v2.currency
        v3.currencyFract = v2.currencyFract
        v3.issuerPNR = v2.issuerPNR
        v3.extensionData = v2.extensionData.map { convertExtensionDataV2($0) }
        v3.issuedOnTrainNum = v2.issuedOnTrainNum
        v3.issuedOnTrainIA5 = v2.issuedOnTrainIA5
        v3.issuedOnLine = v2.issuedOnLine
        v3.pointOfSale = v2.pointOfSale.map { convertGeoCoordinateV2($0) }
        return v3
    }

    private static func convertTravelerDataV2(_ v2: TravelerDataV2) -> TravelerData {
        var v3 = TravelerData()
        v3.traveler = v2.traveler?.map { convertTravelerTypeV2($0) }
        v3.preferedLanguage = v2.preferedLanguage
        v3.groupName = v2.groupName
        return v3
    }

    private static func convertTravelerTypeV2(_ v2: TravelerTypeV2) -> TravelerType {
        var v3 = TravelerType()
        v3.firstName = v2.firstName
        v3.secondName = v2.secondName
        v3.lastName = v2.lastName
        v3.idCard = v2.idCard
        v3.passportId = v2.passportId
        v3.title = v2.title
        v3.gender = v2.gender.map { convertGenderV2($0) }
        v3.customerIdIA5 = v2.customerIdIA5
        v3.customerIdNum = v2.customerIdNum
        v3.yearOfBirth = v2.yearOfBirth
        v3.monthOfBirth = v2.monthOfBirth
        v3.dayOfBirth = v2.dayOfBirth
        v3.ticketHolder = v2.ticketHolder
        v3.passengerType = v2.passengerType.map { convertPassengerTypeV2($0) }
        v3.passengerWithReducedMobility = v2.passengerWithReducedMobility
        v3.countryOfResidence = v2.countryOfResidence
        v3.countryOfPassport = v2.countryOfPassport
        v3.countryOfIdCard = v2.countryOfIdCard
        v3.status = v2.status?.map { convertCustomerStatusTypeV2($0) }
        return v3
    }

    private static func convertCustomerStatusTypeV2(_ v2: CustomerStatusTypeV2) -> CustomerStatusType {
        var v3 = CustomerStatusType()
        v3.statusProviderNum = v2.statusProviderNum
        v3.statusProviderIA5 = v2.statusProviderIA5
        v3.customerStatus = v2.customerStatus
        v3.customerStatusDescr = v2.customerStatusDescr
        return v3
    }

    private static func convertDocumentDataV2(_ v2: DocumentDataV2) -> DocumentData {
        var v3 = DocumentData()
        v3.token = v2.token.map { convertTokenTypeV2($0) }
        v3.ticket = convertTicketDetailDataV2(v2.ticket)
        return v3
    }

    private static func convertTokenTypeV2(_ v2: TokenTypeV2) -> TokenType {
        var v3 = TokenType()
        v3.tokenProviderNum = v2.tokenProviderNum
        v3.tokenProviderIA5 = v2.tokenProviderIA5
        v3.tokenSpecification = v2.tokenSpecification
        v3.token = v2.token
        return v3
    }

    private static func convertTicketDetailDataV2(_ v2: TicketDetailDataV2) -> TicketDetailData {
        var v3 = TicketDetailData()
        if let tt = v2.ticketType {
            switch tt {
            case .reservation(let d): v3.ticketType = .reservation(convertReservationDataV2(d))
            case .carCarriageReservation(let d): v3.ticketType = .carCarriageReservation(convertCarCarriageReservationDataV2(d))
            case .openTicket(let d): v3.ticketType = .openTicket(convertOpenTicketDataV2(d))
            case .pass(let d): v3.ticketType = .pass(convertPassDataV2(d))
            case .voucher(let d): v3.ticketType = .voucher(convertVoucherDataV2(d))
            case .customerCard(let d): v3.ticketType = .customerCard(convertCustomerCardDataV2(d))
            case .countermark(let d): v3.ticketType = .countermark(convertCountermarkDataV2(d))
            case .parkingGround(let d): v3.ticketType = .parkingGround(convertParkingGroundDataV2(d))
            case .fipTicket(let d): v3.ticketType = .fipTicket(convertFIPTicketDataV2(d))
            case .stationPassage(let d): v3.ticketType = .stationPassage(convertStationPassageDataV2(d))
            case .ticketExtension(let d): v3.ticketType = .ticketExtension(convertExtensionDataV2(d))
            case .delayConfirmation(let d): v3.ticketType = .delayConfirmation(convertDelayConfirmationV2(d))
            case .unknown(let d): v3.ticketType = .unknown(d)
            }
        }
        return v3
    }

    private static func convertControlDataV2(_ v2: ControlDataV2) -> ControlData {
        var v3 = ControlData()
        v3.identificationByCardReference = v2.identificationByCardReference?.map { convertCardReferenceTypeV2($0) }
        v3.identificationByIdCard = v2.identificationByIdCard
        v3.identificationByPassportId = v2.identificationByPassportId
        v3.identificationItem = v2.identificationItem
        v3.passportValidationRequired = v2.passportValidationRequired
        v3.onlineValidationRequired = v2.onlineValidationRequired
        v3.randomDetailedValidationRequired = v2.randomDetailedValidationRequired
        v3.ageCheckRequired = v2.ageCheckRequired
        v3.reductionCardCheckRequired = v2.reductionCardCheckRequired
        v3.infoText = v2.infoText
        v3.includedTickets = v2.includedTickets?.map { convertTicketLinkTypeV2($0) }
        v3.extensionData = v2.extensionData.map { convertExtensionDataV2($0) }
        return v3
    }

    private static func convertExtensionDataV2(_ v2: ExtensionDataV2) -> ExtensionData {
        var v3 = ExtensionData()
        v3.extensionId = v2.extensionId
        v3.extensionData = v2.extensionData
        return v3
    }

    private static func convertGeoCoordinateV2(_ v2: GeoCoordinateTypeV2) -> GeoCoordinateType {
        var v3 = GeoCoordinateType()
        v3.geoUnit = v2.geoUnit.map { GeoUnitType(rawValue: $0.rawValue) ?? .milliDegree }
        v3.coordinateSystem = v2.coordinateSystem.map { GeoCoordinateSystemType(rawValue: $0.rawValue) ?? .wgs84 }
        v3.hemisphereLongitude = v2.hemisphereLongitude.map { HemisphereLongitudeType(rawValue: $0.rawValue) ?? .east }
        v3.hemisphereLatitude = v2.hemisphereLatitude.map { HemisphereLatitudeType(rawValue: $0.rawValue) ?? .north }
        v3.longitude = v2.longitude
        v3.latitude = v2.latitude
        v3.accuracy = v2.accuracy.map { GeoUnitType(rawValue: $0.rawValue) ?? .milliDegree }
        return v3
    }

    private static func convertCardReferenceTypeV2(_ v2: CardReferenceTypeV2) -> CardReferenceType {
        var v3 = CardReferenceType()
        v3.cardIssuerNum = v2.cardIssuerNum
        v3.cardIssuerIA5 = v2.cardIssuerIA5
        v3.cardIdNum = v2.cardIdNum
        v3.cardIdIA5 = v2.cardIdIA5
        v3.cardName = v2.cardName
        v3.cardType = v2.cardType
        v3.leadingCardIdNum = v2.leadingCardIdNum
        v3.leadingCardIdIA5 = v2.leadingCardIdIA5
        v3.trailingCardIdNum = v2.trailingCardIdNum
        v3.trailingCardIdIA5 = v2.trailingCardIdIA5
        return v3
    }

    private static func convertTicketLinkTypeV2(_ v2: TicketLinkTypeV2) -> TicketLinkType {
        var v3 = TicketLinkType()
        v3.referenceIA5 = v2.referenceIA5
        v3.referenceNum = v2.referenceNum
        v3.issuerName = v2.issuerName
        v3.issuerPNR = v2.issuerPNR
        v3.productOwnerNum = v2.productOwnerNum
        v3.productOwnerIA5 = v2.productOwnerIA5
        v3.ticketType = v2.ticketType.map { TicketType(rawValue: $0.rawValue) ?? .openTicket }
        v3.linkMode = v2.linkMode.map { LinkMode(rawValue: $0.rawValue) ?? .issuedTogether }
        return v3
    }

    // MARK: - V2 Ticket Type Conversions

    private static func convertReservationDataV2(_ v2: ReservationDataV2) -> ReservationData {
        var v3 = ReservationData()
        v3.trainNum = v2.trainNum
        v3.trainIA5 = v2.trainIA5
        v3.departureDate = v2.departureDate
        v3.referenceIA5 = v2.referenceIA5
        v3.referenceNum = v2.referenceNum
        v3.productOwnerNum = v2.productOwnerNum
        v3.productOwnerIA5 = v2.productOwnerIA5
        v3.productIdNum = v2.productIdNum
        v3.productIdIA5 = v2.productIdIA5
        v3.serviceBrand = v2.serviceBrand
        v3.serviceBrandAbrUTF8 = v2.serviceBrandAbrUTF8
        v3.serviceBrandNameUTF8 = v2.serviceBrandNameUTF8
        v3.service = v2.service.map { ServiceType(rawValue: $0.rawValue) ?? .seat }
        v3.stationCodeTable = v2.stationCodeTable.map { convertCodeTableV2($0) }
        v3.fromStationNum = v2.fromStationNum
        v3.fromStationIA5 = v2.fromStationIA5
        v3.fromStationNameUTF8 = v2.fromStationNameUTF8
        v3.toStationNum = v2.toStationNum
        v3.toStationIA5 = v2.toStationIA5
        v3.toStationNameUTF8 = v2.toStationNameUTF8
        v3.departureTime = v2.departureTime
        v3.departureUTCOffset = v2.departureUTCOffset
        v3.arrivalDate = v2.arrivalDate
        v3.arrivalTime = v2.arrivalTime
        v3.arrivalUTCOffset = v2.arrivalUTCOffset
        v3.carrierNum = v2.carrierNum
        v3.carrierIA5 = v2.carrierIA5
        v3.classCode = v2.classCode.map { convertTravelClassV2($0) }
        v3.serviceLevel = v2.serviceLevel
        v3.places = v2.places.map { convertPlacesTypeV2($0) }
        v3.additionalPlaces = v2.additionalPlaces.map { convertPlacesTypeV2($0) }
        v3.bicyclePlaces = v2.bicyclePlaces.map { convertPlacesTypeV2($0) }
        v3.compartmentDetails = v2.compartmentDetails.map { convertCompartmentDetailsTypeV2($0) }
        v3.numberOfOverbooked = v2.numberOfOverbooked
        v3.berth = v2.berth?.map { convertBerthDetailDataV2($0) }
        v3.tariff = v2.tariff?.map { convertTariffTypeV2($0) }
        v3.priceType = v2.priceType.map { PriceTypeType(rawValue: $0.rawValue) ?? .travelPrice }
        v3.price = v2.price
        v3.vatDetails = v2.vatDetail?.map { convertVatDetailTypeV2($0) }
        v3.typeOfSupplement = v2.typeOfSupplement
        v3.numberOfSupplements = v2.numberOfSupplements
        v3.luggage = v2.luggage.map { convertLuggageRestrictionTypeV2($0) }
        v3.infoText = v2.infoText
        v3.extensionData = v2.extensionData.map { convertExtensionDataV2($0) }
        return v3
    }

    private static func convertOpenTicketDataV2(_ v2: OpenTicketDataV2) -> OpenTicketData {
        var v3 = OpenTicketData()
        v3.referenceIA5 = v2.referenceIA5
        v3.referenceNum = v2.referenceNum
        v3.productOwnerNum = v2.productOwnerNum
        v3.productOwnerIA5 = v2.productOwnerIA5
        v3.productIdNum = v2.productIdNum
        v3.productIdIA5 = v2.productIdIA5
        v3.externalIssuerId = v2.extIssuerId
        v3.issuerAutorizationId = v2.issuerAuthorizationId
        v3.returnIncluded = v2.returnIncluded
        v3.stationCodeTable = v2.stationCodeTable.map { convertCodeTableV2($0) }
        v3.fromStationNum = v2.fromStationNum
        v3.fromStationIA5 = v2.fromStationIA5
        v3.toStationNum = v2.toStationNum
        v3.toStationIA5 = v2.toStationIA5
        v3.fromStationNameUTF8 = v2.fromStationNameUTF8
        v3.toStationNameUTF8 = v2.toStationNameUTF8
        v3.validRegionDesc = v2.validRegionDesc
        v3.validRegion = v2.validRegion?.map { convertRegionalValidityTypeV2($0) }
        v3.returnDescription = v2.returnDescription.map { convertReturnRouteDescriptionTypeV2($0) }
        v3.validFromDay = v2.validFromDay
        v3.validFromTime = v2.validFromTime
        v3.validFromUTCOffset = v2.validFromUTCOffset
        v3.validUntilDay = v2.validUntilDay
        v3.validUntilTime = v2.validUntilTime
        v3.validUntilUTCOffset = v2.validUntilUTCOffset
        v3.activatedDay = v2.activatedDay
        v3.classCode = v2.classCode.map { convertTravelClassV2($0) }
        v3.serviceLevel = v2.serviceLevel
        v3.carrierNum = v2.carrierNum
        v3.carrierIA5 = v2.carrierIA5
        v3.includedServiceBrands = v2.includedServiceBrands
        v3.excludedServiceBrands = v2.excludedServiceBrands
        v3.includedTransportTypes = v2.includedTransportTypes
        v3.excludedTransportTypes = v2.excludedTransportTypes
        v3.tariffs = v2.tariffs?.map { convertTariffTypeV2($0) }
        v3.price = v2.price
        v3.vatDetails = v2.vatDetail?.map { convertVatDetailTypeV2($0) }
        v3.infoText = v2.infoText
        v3.includedAddOns = v2.includedAddOns?.map { convertIncludedOpenTicketTypeV2($0) }
        v3.luggage = v2.luggage.map { convertLuggageRestrictionTypeV2($0) }
        v3.extensionData = v2.extensionData.map { convertExtensionDataV2($0) }
        return v3
    }

    private static func convertPassDataV2(_ v2: PassDataV2) -> PassData {
        var v3 = PassData()
        v3.referenceIA5 = v2.referenceIA5
        v3.referenceNum = v2.referenceNum
        v3.productOwnerNum = v2.productOwnerNum
        v3.productOwnerIA5 = v2.productOwnerIA5
        v3.productIdNum = v2.productIdNum
        v3.productIdIA5 = v2.productIdIA5
        v3.passType = v2.passType
        v3.passDescription = v2.passDescription
        v3.classCode = v2.classCode.map { convertTravelClassV2($0) }
        v3.validFromDay = v2.validFromDay
        v3.validFromTime = v2.validFromTime
        v3.validFromUTCOffset = v2.validFromUTCOffset
        v3.validUntilDay = v2.validUntilDay
        v3.validUntilTime = v2.validUntilTime
        v3.validUntilUTCOffset = v2.validUntilUTCOffset
        v3.validityPeriodDetails = v2.validityPeriodDetails.map { convertValidityPeriodDetailTypeV2($0) }
        v3.numberOfValidityDays = v2.numberOfValidityDays
        v3.numberOfPossibleTrips = v2.numberOfPossibleTrips
        v3.numberOfDaysOfTravel = v2.numberOfDaysOfTravel
        v3.activatedDay = v2.activatedDay
        v3.countries = v2.countries
        v3.includedCarrierNum = v2.includedCarrierNum
        v3.includedCarrierIA5 = v2.includedCarrierIA5
        v3.excludedCarrierNum = v2.excludedCarrierNum
        v3.excludedCarrierIA5 = v2.excludedCarrierIA5
        v3.includedServiceBrands = v2.includedServiceBrands
        v3.excludedServiceBrands = v2.excludedServiceBrands
        v3.validRegion = v2.validRegion?.map { convertRegionalValidityTypeV2($0) }
        v3.tariffs = v2.tariffs?.map { convertTariffTypeV2($0) }
        v3.price = v2.price
        v3.vatDetails = v2.vatDetail?.map { convertVatDetailTypeV2($0) }
        v3.infoText = v2.infoText
        v3.extensionData = v2.extensionData.map { convertExtensionDataV2($0) }
        // V2 has no trainValidity
        return v3
    }

    private static func convertCarCarriageReservationDataV2(_ v2: CarCarriageReservationDataV2) -> CarCarriageReservationData {
        var v3 = CarCarriageReservationData()
        v3.trainNum = v2.trainNum
        v3.trainIA5 = v2.trainIA5
        v3.beginLoadingDate = v2.beginLoadingDate
        v3.beginLoadingTime = v2.beginLoadingTime
        v3.endLoadingTime = v2.endLoadingTime
        v3.loadingUTCOffset = v2.loadingUTCOffset
        v3.referenceIA5 = v2.referenceIA5
        v3.referenceNum = v2.referenceNum
        v3.productOwnerNum = v2.productOwnerNum
        v3.productOwnerIA5 = v2.productOwnerIA5
        v3.productIdNum = v2.productIdNum
        v3.productIdIA5 = v2.productIdIA5
        v3.serviceBrand = v2.serviceBrand
        v3.serviceBrandAbrUTF8 = v2.serviceBrandAbrUTF8
        v3.serviceBrandNameUTF8 = v2.serviceBrandNameUTF8
        v3.stationCodeTable = v2.stationCodeTable.map { convertCodeTableV2($0) }
        v3.fromStationNum = v2.fromStationNum
        v3.fromStationIA5 = v2.fromStationIA5
        v3.toStationNum = v2.toStationNum
        v3.toStationIA5 = v2.toStationIA5
        v3.fromStationNameUTF8 = v2.fromStationNameUTF8
        v3.toStationNameUTF8 = v2.toStationNameUTF8
        v3.coach = v2.coach
        v3.place = v2.place
        v3.compartmentDetails = v2.compartmentDetails.map { convertCompartmentDetailsTypeV2($0) }
        v3.numberPlate = v2.numberPlate
        v3.trailerPlate = v2.trailerPlate
        v3.carCategory = v2.carCategory
        v3.boatCategory = v2.boatCategory
        v3.textileRoof = v2.textileRoof
        v3.roofRackType = v2.roofRackType.map { RoofRackType(rawValue: $0.rawValue) ?? .norack }
        v3.roofRackHeight = v2.roofRackHeight
        v3.attachedBoats = v2.attachedBoats
        v3.attachedBicycles = v2.attachedBicycles
        v3.attachedSurfboards = v2.attachedSurfboards
        v3.loadingListEntry = v2.loadingListEntry
        v3.loadingDeck = v2.loadingDeck.map { LoadingDeckType(rawValue: $0.rawValue) ?? .upper }
        v3.carrierNum = v2.carrierNum
        v3.carrierIA5 = v2.carrierIA5
        v3.tariff = convertTariffTypeV2(v2.tariff)
        v3.priceType = v2.priceType.map { PriceTypeType(rawValue: $0.rawValue) ?? .travelPrice }
        v3.price = v2.price
        v3.vatDetails = v2.vatDetail?.map { convertVatDetailTypeV2($0) }
        v3.infoText = v2.infoText
        v3.extensionData = v2.extensionData.map { convertExtensionDataV2($0) }
        return v3
    }

    private static func convertCountermarkDataV2(_ v2: CountermarkDataV2) -> CountermarkData {
        var v3 = CountermarkData()
        v3.referenceIA5 = v2.referenceIA5
        v3.referenceNum = v2.referenceNum
        v3.productOwnerNum = v2.productOwnerNum
        v3.productOwnerIA5 = v2.productOwnerIA5
        v3.productIdNum = v2.productIdNum
        v3.productIdIA5 = v2.productIdIA5
        v3.ticketReferenceIA5 = v2.ticketReferenceIA5
        v3.ticketReferenceNum = v2.ticketReferenceNum
        v3.numberOfCountermark = v2.numberOfCountermark
        v3.totalOfCountermarks = v2.totalOfCountermarks
        v3.groupName = v2.groupName
        v3.stationCodeTable = v2.stationCodeTable.map { convertCodeTableV2($0) }
        v3.fromStationNum = v2.fromStationNum
        v3.fromStationIA5 = v2.fromStationIA5
        v3.fromStationNameUTF8 = v2.fromStationNameUTF8
        v3.toStationNum = v2.toStationNum
        v3.toStationIA5 = v2.toStationIA5
        v3.toStationNameUTF8 = v2.toStationNameUTF8
        v3.validRegionDesc = v2.validRegionDesc
        v3.validRegion = v2.validRegion?.map { convertRegionalValidityTypeV2($0) }
        v3.returnIncluded = v2.returnIncluded
        v3.returnDescription = v2.returnDescription.map { convertReturnRouteDescriptionTypeV2($0) }
        v3.validFromDay = v2.validFromDay
        v3.validFromTime = v2.validFromTime
        v3.validFromUTCOffset = v2.validFromUTCOffset
        v3.validUntilDay = v2.validUntilDay
        v3.validUntilTime = v2.validUntilTime
        v3.validUntilUTCOffset = v2.validUntilUTCOffset
        v3.classCode = v2.classCode.map { convertTravelClassV2($0) }
        v3.carrierNum = v2.carrierNum
        v3.carrierIA5 = v2.carrierIA5
        v3.includedServiceBrands = v2.includedServiceBrands
        v3.excludedServiceBrands = v2.excludedServiceBrands
        v3.infoText = v2.infoText
        v3.extensionData = v2.extensionData.map { convertExtensionDataV2($0) }
        return v3
    }

    private static func convertVoucherDataV2(_ v2: VoucherDataV2) -> VoucherData {
        var v3 = VoucherData()
        v3.referenceIA5 = v2.referenceIA5
        v3.referenceNum = v2.referenceNum
        v3.productOwnerNum = v2.productOwnerNum
        v3.productOwnerIA5 = v2.productOwnerIA5
        v3.productIdNum = v2.productIdNum
        v3.productIdIA5 = v2.productIdIA5
        v3.validFromYear = v2.validFromYear
        v3.validFromDay = v2.validFromDay
        v3.validUntilYear = v2.validUntilYear
        v3.validUntilDay = v2.validUntilDay
        v3.value = v2.value
        v3.voucherType = v2.type
        v3.infoText = v2.infoText
        v3.extensionData = v2.extensionData.map { convertExtensionDataV2($0) }
        return v3
    }

    private static func convertCustomerCardDataV2(_ v2: CustomerCardDataV2) -> CustomerCardData {
        var v3 = CustomerCardData()
        v3.customer = v2.customer.map { convertTravelerTypeV2($0) }
        v3.cardIdIA5 = v2.cardIdIA5
        v3.cardIdNum = v2.cardIdNum
        v3.validFromYear = v2.validFromYear ?? 0
        v3.validFromDay = v2.validFromDay
        v3.validUntilYear = v2.validUntilYear
        v3.validUntilDay = v2.validUntilDay
        v3.classCode = v2.classCode.map { convertTravelClassV2($0) }
        v3.cardType = v2.cardType
        v3.cardTypeDescr = v2.cardTypeDescr
        v3.customerStatus = v2.customerStatus
        v3.customerStatusDescr = v2.customerStatusDescr
        v3.includedServices = v2.includedServices
        v3.extensionData = v2.extensionData.map { convertExtensionDataV2($0) }
        return v3
    }

    private static func convertParkingGroundDataV2(_ v2: ParkingGroundDataV2) -> ParkingGroundData {
        var v3 = ParkingGroundData()
        v3.referenceIA5 = v2.referenceIA5
        v3.referenceNum = v2.referenceNum
        v3.parkingGroundId = v2.parkingGroundId
        v3.fromParkingDate = v2.fromParkingDate
        v3.toParkingDate = v2.toParkingDate
        v3.productOwnerNum = v2.productOwnerNum
        v3.productOwnerIA5 = v2.productOwnerIA5
        v3.productIdNum = v2.productIdNum
        v3.productIdIA5 = v2.productIdIA5
        v3.accessCode = v2.accessCode
        v3.location = v2.location
        v3.stationCodeTable = v2.stationCodeTable.map { convertCodeTableV2($0) }
        v3.stationNum = v2.stationNum
        v3.stationIA5 = v2.stationIA5
        v3.specialInformation = v2.specialInformation
        v3.entryTrack = v2.entryTrack
        v3.numberPlate = v2.numberPlate
        v3.price = v2.price
        v3.vatDetails = v2.vatDetail?.map { convertVatDetailTypeV2($0) }
        v3.extensionData = v2.extensionData.map { convertExtensionDataV2($0) }
        return v3
    }

    private static func convertFIPTicketDataV2(_ v2: FIPTicketDataV2) -> FIPTicketData {
        var v3 = FIPTicketData()
        v3.referenceIA5 = v2.referenceIA5
        v3.referenceNum = v2.referenceNum
        v3.productOwnerNum = v2.productOwnerNum
        v3.productOwnerIA5 = v2.productOwnerIA5
        v3.productIdNum = v2.productIdNum
        v3.productIdIA5 = v2.productIdIA5
        v3.validFromDay = v2.validFromDay
        v3.validUntilDay = v2.validUntilDay
        v3.activatedDay = v2.activatedDay
        v3.carrierNum = v2.carrierNum
        v3.carrierIA5 = v2.carrierIA5
        v3.numberOfTravelDays = v2.numberOfTravelDays
        v3.includesSupplements = v2.includesSupplements
        v3.classCode = v2.classCode.map { convertTravelClassV2($0) }
        v3.extensionData = v2.extensionData.map { convertExtensionDataV2($0) }
        return v3
    }

    private static func convertStationPassageDataV2(_ v2: StationPassageDataV2) -> StationPassageData {
        var v3 = StationPassageData()
        v3.referenceIA5 = v2.referenceIA5
        v3.referenceNum = v2.referenceNum
        v3.productOwnerNum = v2.productOwnerNum
        v3.productOwnerIA5 = v2.productOwnerIA5
        v3.productIdNum = v2.productIdNum
        v3.productIdIA5 = v2.productIdIA5
        v3.productName = v2.productName
        v3.stationCodeTable = v2.stationCodeTable.map { convertCodeTableV2($0) }
        v3.stationNum = v2.stationNum?.map { $0 }
        v3.stationIA5 = v2.stationIA5
        v3.stationNameUTF8 = v2.stationNameUTF8
        v3.areaCodeNum = v2.areaCodeNum?.map { $0 }
        v3.areaCodeIA5 = v2.areaCodeIA5
        v3.areaNameUTF8 = v2.areaNameUTF8
        v3.validFromDay = v2.validFromDay
        v3.validFromTime = v2.validFromTime
        v3.validFromUTCOffset = v2.validFromUTCOffset
        v3.validUntilDay = v2.validUntilDay
        v3.validUntilTime = v2.validUntilTime
        v3.validUntilUTCOffset = v2.validUntilUTCOffset
        v3.numberOfDaysValid = v2.numberOfDaysValid
        v3.extensionData = v2.extensionData.map { convertExtensionDataV2($0) }
        return v3
    }

    private static func convertDelayConfirmationV2(_ v2: DelayConfirmationV2) -> DelayConfirmation {
        var v3 = DelayConfirmation()
        v3.referenceIA5 = v2.referenceIA5
        v3.referenceNum = v2.referenceNum
        v3.trainNum = v2.trainNum
        v3.trainIA5 = v2.trainIA5
        v3.plannedArrivalYear = v2.plannedArrivalYear
        v3.plannedArrivalDay = v2.plannedArrivalDay
        v3.plannedArrivalTime = v2.plannedArrivalTime
        v3.departureUTCOffset = v2.departureUTCOffset
        v3.stationCodeTable = v2.stationCodeTable.map { convertCodeTableV2($0) }
        v3.stationNum = v2.stationNum
        v3.stationIA5 = v2.stationIA5
        v3.delay = v2.delay
        v3.trainCancelled = v2.trainCancelled
        v3.confirmationType = v2.confirmationType.map { ConfirmationTypeType(rawValue: $0.rawValue) ?? .trainDelayConfirmation }
        v3.affectedTickets = v2.affectedTickets?.map { convertTicketLinkTypeV2($0) }
        v3.infoText = v2.infoText
        v3.extensionData = v2.extensionData.map { convertExtensionDataV2($0) }
        return v3
    }

    // MARK: - V2 Supporting Type Conversions

    private static func convertPlacesTypeV2(_ v2: PlacesTypeV2) -> PlacesType {
        var v3 = PlacesType()
        v3.coach = v2.coach
        v3.placeString = v2.placeString
        v3.placeDescription = v2.placeDescription
        v3.placeIA5 = v2.placeIA5
        v3.placeNum = v2.placeNum?.map { $0 }
        return v3
    }

    private static func convertCompartmentDetailsTypeV2(_ v2: CompartmentDetailsTypeV2) -> CompartmentDetailsType {
        var v3 = CompartmentDetailsType()
        v3.coachType = v2.coachType
        v3.compartmentType = v2.compartmentType
        v3.specialAllocation = v2.specialAllocation
        v3.coachTypeDescr = v2.coachTypeDescr
        v3.compartmentTypeDescr = v2.compartmentTypeDescr
        v3.specialAllocationDescr = v2.specialAllocationDescr
        v3.position = v2.position.map { CompartmentPositionType(rawValue: $0.rawValue) ?? .unspecified }
        return v3
    }

    private static func convertBerthDetailDataV2(_ v2: BerthDetailDataV2) -> BerthDetailData {
        var v3 = BerthDetailData()
        v3.berthType = BerthTypeType(rawValue: v2.berthType.rawValue)
        v3.numberOfBerths = v2.numberOfBerths
        v3.gender = v2.gender.map { CompartmentGenderType(rawValue: $0.rawValue) ?? .unspecified }
        return v3
    }

    private static func convertTariffTypeV2(_ v2: TariffTypeV2) -> TariffType {
        var v3 = TariffType()
        v3.numberOfPassengers = v2.numberOfPassengers
        v3.passengerType = v2.passengerType.map { PassengerType(rawValue: $0.rawValue) ?? .adult }
        v3.ageBelow = v2.ageBelow
        v3.ageAbove = v2.ageAbove
        v3.travelerid = v2.travelerid?.map { $0 }
        v3.restrictedToCountryOfResidence = v2.restrictedToCountryOfResidence
        v3.restrictedToRouteSection = v2.restrictedToRouteSection.map { convertRouteSectionTypeV2($0) }
        v3.seriesDataDetails = v2.seriesDataDetails.map { convertSeriesDetailTypeV2($0) }
        v3.tariffIdNum = v2.tariffIdNum
        v3.tariffIdIA5 = v2.tariffIdIA5
        v3.tariffDesc = v2.tariffDesc
        v3.reductionCard = v2.reductionCard?.map { convertCardReferenceTypeV2($0) }
        return v3
    }

    private static func convertVatDetailTypeV2(_ v2: VatDetailTypeV2) -> VatDetailType {
        var v3 = VatDetailType()
        v3.country = v2.country
        v3.percentage = v2.percentage
        v3.amount = v2.amount
        v3.vatId = v2.vatId
        return v3
    }

    private static func convertRegionalValidityTypeV2(_ v2: RegionalValidityTypeV2) -> RegionalValidityType {
        var v3 = RegionalValidityType()
        guard let rt = v2.validity else { return v3 }
        switch rt {
        case .trainLink(let d): v3.validity = .trainLink(convertTrainLinkTypeV2(d))
        case .viaStations(let d): v3.validity = .viaStations(convertViaStationTypeV2(d))
        case .zone(let d): v3.validity = .zone(convertZoneTypeV2(d))
        case .line(let d): v3.validity = .line(convertLineTypeV2(d))
        case .polygone(let d): v3.validity = .polygone(convertPolygoneTypeV2(d))
        }
        return v3
    }

    private static func convertTrainLinkTypeV2(_ v2: TrainLinkTypeV2) -> TrainLinkType {
        var v3 = TrainLinkType()
        v3.trainNum = v2.trainNum
        v3.trainIA5 = v2.trainIA5
        v3.travelDate = v2.travelDate
        v3.departureTime = v2.departureTime
        v3.departureUTCOffset = v2.departureUTCOffset
        v3.fromStationNum = v2.fromStationNum
        v3.fromStationIA5 = v2.fromStationIA5
        v3.fromStationNameUTF8 = v2.fromStationNameUTF8
        v3.toStationNum = v2.toStationNum
        v3.toStationIA5 = v2.toStationIA5
        v3.toStationNameUTF8 = v2.toStationNameUTF8
        return v3
    }

    private static func convertViaStationTypeV2(_ v2: ViaStationTypeV2) -> ViaStationType {
        var v3 = ViaStationType()
        v3.stationCodeTable = v2.stationCodeTable.map { convertCodeTableV2($0) }
        v3.stationNum = v2.stationNum
        v3.stationIA5 = v2.stationIA5
        v3.alternativeRoutes = v2.alternativeRoutes?.map { convertViaStationTypeV2($0) }
        v3.route = v2.route?.map { convertViaStationTypeV2($0) }
        v3.border = v2.border
        v3.carriersNum = v2.carriersNum
        v3.carriersIA5 = v2.carriersIA5
        v3.seriesId = v2.seriesId
        v3.routeId = v2.routeId
        return v3
    }

    private static func convertZoneTypeV2(_ v2: ZoneTypeV2) -> ZoneType {
        var v3 = ZoneType()
        v3.carrierNum = v2.carrierNum
        v3.carrierIA5 = v2.carrierIA5
        v3.stationCodeTable = v2.stationCodeTable.map { convertCodeTableV2($0) }
        v3.entryStationNum = v2.entryStationNum
        v3.entryStationIA5 = v2.entryStationIA5
        v3.terminatingStationNum = v2.terminatingStationNum
        v3.terminatingStationIA5 = v2.terminatingStationIA5
        v3.city = v2.city
        v3.zoneId = v2.zoneId?.map { $0 }
        v3.binaryZoneId = v2.binaryZoneId
        v3.nutsCode = v2.nutsCode
        return v3
    }

    private static func convertLineTypeV2(_ v2: LineTypeV2) -> LineType {
        var v3 = LineType()
        v3.carrierNum = v2.carrierNum
        v3.carrierIA5 = v2.carrierIA5
        v3.lineId = v2.lineId?.map { $0 }
        v3.stationCodeTable = v2.stationCodeTable.map { convertCodeTableV2($0) }
        v3.entryStationNum = v2.entryStationNum
        v3.entryStationIA5 = v2.entryStationIA5
        v3.terminatingStationNum = v2.terminatingStationNum
        v3.terminatingStationIA5 = v2.terminatingStationIA5
        v3.city = v2.city
        return v3
    }

    private static func convertPolygoneTypeV2(_ v2: PolygoneTypeV2) -> PolygoneType {
        var v3 = PolygoneType()
        v3.firstEdge = convertGeoCoordinateV2(v2.firstEdge)
        v3.edges = v2.edges.map { convertDeltaCoordinatesV2($0) }
        return v3
    }

    private static func convertDeltaCoordinatesV2(_ v2: DeltaCoordinatesV2) -> DeltaCoordinates {
        var v3 = DeltaCoordinates()
        v3.longitude = v2.longitude
        v3.latitude = v2.latitude
        return v3
    }

    private static func convertRouteSectionTypeV2(_ v2: RouteSectionTypeV2) -> RouteSectionType {
        var v3 = RouteSectionType()
        v3.stationCodeTable = v2.stationCodeTable.map { convertCodeTableV2($0) }
        v3.fromStationNum = v2.fromStationNum
        v3.fromStationIA5 = v2.fromStationIA5
        v3.fromStationNameUTF8 = v2.fromStationNameUTF8
        v3.toStationNum = v2.toStationNum
        v3.toStationIA5 = v2.toStationIA5
        v3.toStationNameUTF8 = v2.toStationNameUTF8
        return v3
    }

    private static func convertSeriesDetailTypeV2(_ v2: SeriesDetailTypeV2) -> SeriesDetailType {
        var v3 = SeriesDetailType()
        v3.supplyingCarrier = v2.supplyingCarrier
        v3.offerIdentification = v2.offerIdentification
        v3.series = v2.series
        return v3
    }

    private static func convertValidityPeriodDetailTypeV2(_ v2: ValidityPeriodDetailTypeV2) -> ValidityPeriodDetailType {
        var v3 = ValidityPeriodDetailType()
        v3.validityPeriod = v2.validityPeriod?.map { convertValidityPeriodTypeV2($0) }
        v3.excludedTimeRange = v2.excludedTimeRange?.map { convertTimeRangeTypeV2($0) }
        return v3
    }

    private static func convertValidityPeriodTypeV2(_ v2: ValidityPeriodTypeV2) -> ValidityPeriodType {
        var v3 = ValidityPeriodType()
        v3.validFromDay = v2.validFromDay
        v3.validFromTime = v2.validFromTime
        v3.validFromUTCOffset = v2.validFromUTCOffset
        v3.validUntilDay = v2.validUntilDay
        v3.validUntilTime = v2.validUntilTime
        v3.validUntilUTCOffset = v2.validUntilUTCOffset
        return v3
    }

    private static func convertTimeRangeTypeV2(_ v2: TimeRangeTypeV2) -> TimeRangeType {
        var v3 = TimeRangeType()
        v3.fromTime = v2.fromTime
        v3.untilTime = v2.untilTime
        return v3
    }

    private static func convertReturnRouteDescriptionTypeV2(_ v2: ReturnRouteDescriptionTypeV2) -> ReturnRouteDescriptionType {
        var v3 = ReturnRouteDescriptionType()
        v3.fromStationNum = v2.fromStationNum
        v3.fromStationIA5 = v2.fromStationIA5
        v3.toStationNum = v2.toStationNum
        v3.toStationIA5 = v2.toStationIA5
        v3.fromStationNameUTF8 = v2.fromStationNameUTF8
        v3.toStationNameUTF8 = v2.toStationNameUTF8
        v3.validReturnRegionDesc = v2.validReturnRegionDesc
        v3.validReturnRegion = v2.validReturnRegion?.map { convertRegionalValidityTypeV2($0) }
        return v3
    }

    private static func convertIncludedOpenTicketTypeV2(_ v2: IncludedOpenTicketTypeV2) -> IncludedOpenTicketType {
        var v3 = IncludedOpenTicketType()
        v3.productOwnerNum = v2.productOwnerNum
        v3.productOwnerIA5 = v2.productOwnerIA5
        v3.productIdNum = v2.productIdNum
        v3.productIdIA5 = v2.productIdIA5
        v3.externalIssuerId = v2.externalIssuerId
        v3.issuerAutorizationId = v2.issuerAuthorizationId
        v3.stationCodeTable = v2.stationCodeTable.map { convertCodeTableV2($0) }
        v3.validRegion = v2.validRegion?.map { convertRegionalValidityTypeV2($0) }
        v3.validFromDay = v2.validFromDay
        v3.validFromTime = v2.validFromTime
        v3.validFromUTCOffset = v2.validFromUTCOffset
        v3.validUntilDay = v2.validUntilDay
        v3.validUntilTime = v2.validUntilTime
        v3.validUntilUTCOffset = v2.validUntilUTCOffset
        v3.classCode = v2.classCode.map { convertTravelClassV2($0) }
        v3.serviceLevel = v2.serviceLevel
        v3.carrierNum = v2.carrierNum
        v3.carrierIA5 = v2.carrierIA5
        v3.includedServiceBrands = v2.includedServiceBrands
        v3.excludedServiceBrands = v2.excludedServiceBrands
        v3.includedTransportTypes = v2.includedTransportTypes
        v3.excludedTransportTypes = v2.excludedTransportTypes
        v3.tariffs = v2.tariffs?.map { convertTariffTypeV2($0) }
        v3.infoText = v2.infoText
        v3.extensionData = v2.extensionData.map { convertExtensionDataV2($0) }
        return v3
    }

    private static func convertLuggageRestrictionTypeV2(_ v2: LuggageRestrictionTypeV2) -> LuggageRestrictionType {
        var v3 = LuggageRestrictionType()
        v3.maxHandLuggagePieces = v2.maxHandLuggagePieces
        v3.maxNonHandLuggagePieces = v2.maxNonHandLuggagePieces
        v3.registeredLuggage = v2.registeredLuggage?.map { convertRegisteredLuggageTypeV2($0) }
        return v3
    }

    private static func convertRegisteredLuggageTypeV2(_ v2: RegisteredLuggageTypeV2) -> RegisteredLuggageType {
        var v3 = RegisteredLuggageType()
        v3.registrationId = v2.registrationId
        v3.maxWeight = v2.maxWeight
        v3.maxSize = v2.maxSize
        return v3
    }

    // MARK: - V2 Enum Conversions

    private static func convertTravelClassV2(_ v2: TravelClassTypeV2) -> TravelClassType {
        return TravelClassType(rawValue: v2.rawValue) ?? .second
    }

    private static func convertCodeTableV2(_ v2: CodeTableTypeV2) -> CodeTableType {
        return CodeTableType(rawValue: v2.rawValue) ?? .stationUIC
    }

    private static func convertGenderV2(_ v2: GenderTypeV2) -> GenderType {
        return GenderType(rawValue: v2.rawValue) ?? .unspecified
    }

    private static func convertPassengerTypeV2(_ v2: PassengerTypeV2) -> PassengerType {
        return PassengerType(rawValue: v2.rawValue) ?? .adult
    }
}
