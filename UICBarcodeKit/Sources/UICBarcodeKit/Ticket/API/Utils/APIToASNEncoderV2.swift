import Foundation

/// Converts version-independent API objects back to V2 ASN.1 model objects.
/// This is the inverse of ASNToAPIDecoderV2.
enum APIToASNEncoderV2 {

    /// Convert a version-independent API ticket to a V2 UicRailTicketDataV2
    static func encode(_ api: UicRailTicket) -> UicRailTicketDataV2 {
        var ticket = UicRailTicketDataV2()

        if let issuing = api.issuingDetail {
            ticket.issuingDetail = convertIssuingDetail(issuing)
        }

        if let traveler = api.travelerDetail {
            ticket.travelerDetail = convertTravelerDetail(traveler)
        }

        if let control = api.controlDetail {
            ticket.controlDetail = convertControlDetail(control)
        }

        if !api.documents.isEmpty {
            let issuingDate = api.issuingDetail?.issuingDate
            ticket.transportDocument = api.documents.compactMap { convertDocument($0, issuingDate: issuingDate) }
        }

        if !api.extensions.isEmpty {
            ticket.extensionData = api.extensions.map { convertExtension($0) }
        }

        return ticket
    }

    // MARK: - Issuing Detail

    static func convertIssuingDetail(_ api: IssuingDetail) -> IssuingDataV2 {
        var asn = IssuingDataV2()

        asn.specimen = api.specimen
        asn.activated = api.activated
        asn.securePaperTicket = api.securePaperTicket

        if let provider = api.securityProvider {
            let (num, ia5) = splitNumIA5(provider)
            asn.securityProviderNum = num
            asn.securityProviderIA5 = ia5
        }

        if let issuer = api.issuer {
            let (num, ia5) = splitNumIA5(issuer)
            asn.issuerNum = num
            asn.issuerIA5 = ia5
        }

        asn.issuerName = api.issuerName
        asn.issuerPNR = api.issuerPNR

        if let date = api.issuingDate {
            let cal = Calendar(identifier: .gregorian)
            let utc = TimeZone(identifier: "UTC")!
            let components = cal.dateComponents(in: utc, from: date)
            asn.issuingYear = components.year ?? 2024
            var utcCal = cal; utcCal.timeZone = utc
            asn.issuingDay = utcCal.ordinality(of: .day, in: .year, for: date) ?? 1
            let minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
            if minutes > 0 {
                asn.issuingTime = minutes
            }
        }

        if let train = api.issuedOnTrain {
            let (num, ia5) = splitNumIA5(train)
            asn.issuedOnTrainNum = num
            asn.issuedOnTrainIA5 = ia5
        }

        asn.issuedOnLine = api.issuedOnLine
        asn.currency = api.currency
        asn.currencyFract = api.currencyFraction

        if let gps = api.pointOfSale {
            asn.pointOfSale = convertGeoCoordinate(gps)
        }

        if let ext = api.extensionData {
            asn.extensionData = convertExtension(ext)
        }

        return asn
    }

    // MARK: - Traveler Detail

    static func convertTravelerDetail(_ api: TravelerDetail) -> TravelerDataV2 {
        var asn = TravelerDataV2()

        asn.preferedLanguage = api.preferedLanguage
        asn.groupName = api.groupName

        if !api.travelers.isEmpty {
            asn.traveler = api.travelers.map { convertTraveler($0) }
        }

        return asn
    }

    static func convertTraveler(_ api: Traveler) -> TravelerTypeV2 {
        var asn = TravelerTypeV2()

        asn.firstName = api.firstName
        asn.secondName = api.secondName
        asn.lastName = api.lastName
        asn.idCard = api.idCard
        asn.passportId = api.passportId
        asn.title = api.title
        if let g = api.gender { asn.gender = GenderTypeV2(rawValue: g.rawValue) }
        asn.ticketHolder = api.ticketHolder
        if let pt = api.passengerType { asn.passengerType = PassengerTypeV2(rawValue: pt.rawValue) }
        asn.passengerWithReducedMobility = api.passengerWithReducedMobility
        asn.countryOfResidence = api.countryOfResidence
        asn.countryOfPassport = api.passportCountry
        asn.countryOfIdCard = api.idCardCountry

        if let id = api.customerId {
            let (num, ia5) = splitNumIA5(id)
            asn.customerIdNum = num
            asn.customerIdIA5 = ia5
        }

        if let dob = api.dateOfBirth {
            let cal = Calendar(identifier: .gregorian)
            let utc = TimeZone(identifier: "UTC")!
            let components = cal.dateComponents(in: utc, from: dob)
            asn.yearOfBirth = components.year
            asn.monthOfBirth = components.month
            asn.dayOfBirth = components.day
        }

        if !api.status.isEmpty {
            asn.status = api.status.map { s in
                var cs = CustomerStatusTypeV2()
                cs.statusProviderNum = s.statusProviderNum
                cs.statusProviderIA5 = s.statusProviderIA5
                cs.customerStatus = s.customerStatus
                cs.customerStatusDescr = s.customerStatusDescr
                return cs
            }
        }

        return asn
    }

    // MARK: - Control Detail

    static func convertControlDetail(_ api: ControlDetail) -> ControlDataV2 {
        var asn = ControlDataV2()

        asn.identificationByIdCard = api.identificationByIdCard
        asn.identificationByPassportId = api.identificationByPassportId
        asn.passportValidationRequired = api.passportValidationRequired
        asn.onlineValidationRequired = api.onlineValidationRequired
        asn.ageCheckRequired = api.ageCheckRequired
        asn.reductionCardCheckRequired = api.reductionCardCheckRequired
        asn.infoText = api.infoText

        if !api.identificationByCardReference.isEmpty {
            asn.identificationByCardReference = api.identificationByCardReference.map { convertCardReference($0) }
        }

        if !api.includedTickets.isEmpty {
            asn.includedTickets = api.includedTickets.map { convertTicketLink($0) }
        }

        if let ext = api.extensionData {
            asn.extensionData = convertExtension(ext)
        }

        return asn
    }

    // MARK: - Document Conversion

    static func convertDocument(_ api: APIDocumentData, issuingDate: Date?) -> DocumentDataV2? {
        var doc = DocumentDataV2()
        var detail = TicketDetailDataV2()

        switch api {
        case .reservation(let r):
            detail.ticketType = .reservation(convertReservation(r, issuingDate: issuingDate))
            doc.token = convertToken(r.token)
        case .openTicket(let o):
            detail.ticketType = .openTicket(convertOpenTicket(o, issuingDate: issuingDate))
            doc.token = convertToken(o.token)
        case .pass(let p):
            detail.ticketType = .pass(convertPass(p, issuingDate: issuingDate))
            doc.token = convertToken(p.token)
        case .carCarriageReservation(let c):
            detail.ticketType = .carCarriageReservation(convertCarCarriageReservation(c, issuingDate: issuingDate))
            doc.token = convertToken(c.token)
        case .customerCard(let c):
            detail.ticketType = .customerCard(convertCustomerCard(c, issuingDate: issuingDate))
            doc.token = convertToken(c.token)
        case .counterMark(let c):
            detail.ticketType = .countermark(convertCounterMark(c, issuingDate: issuingDate))
            doc.token = convertToken(c.token)
        case .parkingGround(let p):
            detail.ticketType = .parkingGround(convertParkingGround(p, issuingDate: issuingDate))
            doc.token = convertToken(p.token)
        case .fipTicket(let f):
            detail.ticketType = .fipTicket(convertFIPTicket(f, issuingDate: issuingDate))
            doc.token = convertToken(f.token)
        case .stationPassage(let s):
            detail.ticketType = .stationPassage(convertStationPassage(s, issuingDate: issuingDate))
            doc.token = convertToken(s.token)
        case .delayConfirmation(let d):
            detail.ticketType = .delayConfirmation(convertDelayConfirmation(d, issuingDate: issuingDate))
            doc.token = convertToken(d.token)
        case .voucher(let v):
            detail.ticketType = .voucher(convertVoucher(v, issuingDate: issuingDate))
            doc.token = convertToken(v.token)
        case .documentExtension(let e):
            detail.ticketType = .ticketExtension(convertDocumentExtension(e))
        }

        doc.ticket = detail
        return doc
    }

    // MARK: - Reservation

    static func convertReservation(_ api: Reservation, issuingDate: Date?) -> ReservationDataV2 {
        var asn = ReservationDataV2()

        if let ref = api.reference { splitNumIA5(ref, num: &asn.referenceNum, ia5: &asn.referenceIA5) }
        if let pid = api.productId { splitNumIA5Constrained(pid, max: 65535, num: &asn.productIdNum, ia5: &asn.productIdIA5) }
        if let po = api.productOwner { splitNumIA5Constrained(po, max: 32000, num: &asn.productOwnerNum, ia5: &asn.productOwnerIA5) }
        if let train = api.train { splitNumIA5(train, num: &asn.trainNum, ia5: &asn.trainIA5) }

        if let ct = api.stationCodeTable { asn.stationCodeTable = CodeTableTypeV2(rawValue: ct.rawValue) }
        if let s = api.fromStation { splitNumIA5Station(s, num: &asn.fromStationNum, ia5: &asn.fromStationIA5) }
        if let s = api.toStation { splitNumIA5Station(s, num: &asn.toStationNum, ia5: &asn.toStationIA5) }
        asn.fromStationNameUTF8 = api.fromStationName
        asn.toStationNameUTF8 = api.toStationName

        if let cc = api.classCode { asn.classCode = TravelClassTypeV2(rawValue: cc.rawValue) }
        asn.serviceLevel = api.serviceLevel
        if let svc = api.service { asn.service = ServiceTypeV2(rawValue: svc.rawValue) }
        if api.numberOfOverbooked != 0 { asn.numberOfOverbooked = api.numberOfOverbooked }
        if api.typeOfSupplement != 0 { asn.typeOfSupplement = api.typeOfSupplement }
        if api.numberOfSupplements != 0 { asn.numberOfSupplements = api.numberOfSupplements }
        asn.infoText = api.infoText
        if let pt = api.priceType { asn.priceType = PriceTypeTypeV2(rawValue: pt.rawValue) }
        asn.price = api.price

        if let sb = api.serviceBrand {
            asn.serviceBrand = sb.serviceBrandNum
            asn.serviceBrandAbrUTF8 = sb.serviceBrandAbrUTF8
            asn.serviceBrandNameUTF8 = sb.serviceBrandNameUTF8
        }

        if !api.carriers.isEmpty {
            let (nums, ia5s) = splitNumIA5List(api.carriers)
            asn.carrierNum = nums.isEmpty ? nil : nums
            asn.carrierIA5 = ia5s.isEmpty ? nil : ia5s
        }

        if let p = api.places { asn.places = convertPlaces(p) }
        if let p = api.additionalPlaces { asn.additionalPlaces = convertPlaces(p) }
        if let p = api.bicyclePlaces { asn.bicyclePlaces = convertPlaces(p) }
        if let c = api.compartmentDetails { asn.compartmentDetails = convertCompartmentDetails(c) }

        if !api.berths.isEmpty { asn.berth = api.berths.map { convertBerth($0) } }
        if !api.tariffs.isEmpty { asn.tariff = api.tariffs.map { convertTariff($0) } }
        if !api.vatDetails.isEmpty { asn.vatDetail = api.vatDetails.map { convertVatDetail($0) } }
        if let l = api.luggageRestriction { asn.luggage = convertLuggageRestriction(l) }
        if let ext = api.extensionData { asn.extensionData = convertExtension(ext) }

        asn.departureUTCOffset = api.departureUTCoffset
        asn.arrivalUTCOffset = api.arrivalUTCoffset

        // Date offsets
        if let depDate = api.departureDate, let issuingDate {
            asn.departureDate = DateTimeUtils.getDateDifference(issuingDate, depDate)
            asn.departureTime = DateTimeUtils.getTime(depDate) ?? 0
        }
        if let arrDate = api.arrivalDate, let depDate = api.departureDate {
            asn.arrivalDate = DateTimeUtils.getDateDifference(depDate, arrDate)
            asn.arrivalTime = DateTimeUtils.getTime(arrDate)
        }

        return asn
    }

    // MARK: - Open Ticket

    static func convertOpenTicket(_ api: OpenTicket, issuingDate: Date?) -> OpenTicketDataV2 {
        var asn = OpenTicketDataV2()

        if let ref = api.reference { splitNumIA5(ref, num: &asn.referenceNum, ia5: &asn.referenceIA5) }
        if let pid = api.productId { splitNumIA5Constrained(pid, max: 65535, num: &asn.productIdNum, ia5: &asn.productIdIA5) }
        if let po = api.productOwner { splitNumIA5Constrained(po, max: 32000, num: &asn.productOwnerNum, ia5: &asn.productOwnerIA5) }
        asn.extIssuerId = api.externalIssuer
        asn.issuerAuthorizationId = api.authorizationCode
        asn.returnIncluded = api.returnIncluded

        if let ct = api.stationCodeTable { asn.stationCodeTable = CodeTableTypeV2(rawValue: ct.rawValue) }
        if let s = api.fromStation { splitNumIA5Station(s, num: &asn.fromStationNum, ia5: &asn.fromStationIA5) }
        if let s = api.toStation { splitNumIA5Station(s, num: &asn.toStationNum, ia5: &asn.toStationIA5) }
        asn.fromStationNameUTF8 = api.fromStationName
        asn.toStationNameUTF8 = api.toStationName
        asn.validRegionDesc = api.validRegionDesc

        if let cc = api.classCode { asn.classCode = TravelClassTypeV2(rawValue: cc.rawValue) }
        asn.serviceLevel = api.serviceLevel
        asn.infoText = api.infoText
        asn.price = api.price

        if !api.includedCarriers.isEmpty {
            let (nums, ia5s) = splitNumIA5List(api.includedCarriers)
            asn.carrierNum = nums.isEmpty ? nil : nums
            asn.carrierIA5 = ia5s.isEmpty ? nil : ia5s
        }

        if !api.includedServiceBrands.isEmpty { asn.includedServiceBrands = api.includedServiceBrands }
        if !api.excludedServiceBrands.isEmpty { asn.excludedServiceBrands = api.excludedServiceBrands }
        if !api.includedTransportTypes.isEmpty { asn.includedTransportTypes = api.includedTransportTypes }
        if !api.excludedTransportTypes.isEmpty { asn.excludedTransportTypes = api.excludedTransportTypes }

        if !api.validRegionList.isEmpty {
            asn.validRegion = api.validRegionList.compactMap { convertRegionalValidity($0) }
        }

        if let ret = api.returnDescription {
            asn.returnDescription = convertReturnRouteDescription(ret)
        }

        if !api.tariffs.isEmpty { asn.tariffs = api.tariffs.map { convertTariff($0) } }
        if !api.vatDetails.isEmpty { asn.vatDetail = api.vatDetails.map { convertVatDetail($0) } }
        if !api.includedAddOns.isEmpty { asn.includedAddOns = api.includedAddOns.map { convertIncludedOpenTicket($0) } }
        if let l = api.luggageRestriction { asn.luggage = convertLuggageRestriction(l) }
        if let ext = api.extensionData { asn.extensionData = convertExtension(ext) }

        asn.validFromUTCOffset = api.validFromUTCoffset
        asn.validUntilUTCOffset = api.validUntilUTCoffset

        // Date offsets
        if let validFrom = api.validFrom, let issuingDate {
            asn.validFromDay = DateTimeUtils.getDateDifference(issuingDate, validFrom)
            asn.validFromTime = DateTimeUtils.getTime(validFrom)
        }
        if let validUntil = api.validUntil, let validFrom = api.validFrom {
            asn.validUntilDay = DateTimeUtils.getDateDifference(validFrom, validUntil)
            asn.validUntilTime = DateTimeUtils.getTime(validUntil)
        }

        return asn
    }

    // MARK: - Pass

    static func convertPass(_ api: Pass, issuingDate: Date?) -> PassDataV2 {
        var asn = PassDataV2()

        if let ref = api.reference { splitNumIA5(ref, num: &asn.referenceNum, ia5: &asn.referenceIA5) }
        if let pid = api.productId { splitNumIA5Constrained(pid, max: 65535, num: &asn.productIdNum, ia5: &asn.productIdIA5) }
        if let po = api.productOwner { splitNumIA5Constrained(po, max: 32000, num: &asn.productOwnerNum, ia5: &asn.productOwnerIA5) }

        if api.passType != 0 { asn.passType = api.passType }
        asn.passDescription = api.passDescription
        if let cc = api.classCode { asn.classCode = TravelClassTypeV2(rawValue: cc.rawValue) }
        if api.numberOfValidityDays != 0 { asn.numberOfValidityDays = api.numberOfValidityDays }
        if api.numberOfPossibleTrips != 0 { asn.numberOfPossibleTrips = api.numberOfPossibleTrips }
        if api.numberOfDaysOfTravel != 0 { asn.numberOfDaysOfTravel = api.numberOfDaysOfTravel }
        asn.infoText = api.infoText
        asn.price = api.price

        if !api.countries.isEmpty { asn.countries = api.countries }

        if !api.includedCarriers.isEmpty {
            let (nums, ia5s) = splitNumIA5List(api.includedCarriers)
            asn.includedCarrierNum = nums.isEmpty ? nil : nums
            asn.includedCarrierIA5 = ia5s.isEmpty ? nil : ia5s
        }
        if !api.excludedCarriers.isEmpty {
            let (nums, ia5s) = splitNumIA5List(api.excludedCarriers)
            asn.excludedCarrierNum = nums.isEmpty ? nil : nums
            asn.excludedCarrierIA5 = ia5s.isEmpty ? nil : ia5s
        }

        if !api.includedServiceBrands.isEmpty { asn.includedServiceBrands = api.includedServiceBrands }
        if !api.excludedServiceBrands.isEmpty { asn.excludedServiceBrands = api.excludedServiceBrands }

        if !api.validRegionList.isEmpty {
            asn.validRegion = api.validRegionList.compactMap { convertRegionalValidity($0) }
        }

        if !api.tariffs.isEmpty { asn.tariffs = api.tariffs.map { convertTariff($0) } }
        if !api.vatDetails.isEmpty { asn.vatDetail = api.vatDetails.map { convertVatDetail($0) } }

        if let vpd = api.validityDetails { asn.validityPeriodDetails = convertValidityDetails(vpd) }
        // V2: no trainValidity field

        if let ext = api.extensionData { asn.extensionData = convertExtension(ext) }

        asn.validFromUTCOffset = api.validFromUTCoffset
        asn.validUntilUTCOffset = api.validUntilUTCoffset

        // Date offsets
        if let validFrom = api.validFrom, let issuingDate {
            asn.validFromDay = DateTimeUtils.getDateDifference(issuingDate, validFrom)
            asn.validFromTime = DateTimeUtils.getTime(validFrom)
        }
        if let validUntil = api.validUntil, let validFrom = api.validFrom {
            asn.validUntilDay = DateTimeUtils.getDateDifference(validFrom, validUntil)
            asn.validUntilTime = DateTimeUtils.getTime(validUntil)
        }

        if !api.activatedDays.isEmpty, let validFrom = api.validFrom {
            asn.activatedDay = DateTimeUtils.getActivatedDays(referenceDate: validFrom, dates: api.activatedDays)
        }

        return asn
    }

    // MARK: - Car Carriage Reservation

    static func convertCarCarriageReservation(_ api: CarCarriageReservationAPI, issuingDate: Date?) -> CarCarriageReservationDataV2 {
        var asn = CarCarriageReservationDataV2()

        if let ref = api.reference { splitNumIA5(ref, num: &asn.referenceNum, ia5: &asn.referenceIA5) }
        if let pid = api.productId { splitNumIA5Constrained(pid, max: 65535, num: &asn.productIdNum, ia5: &asn.productIdIA5) }
        if let po = api.productOwner { splitNumIA5Constrained(po, max: 32000, num: &asn.productOwnerNum, ia5: &asn.productOwnerIA5) }
        if let train = api.train { splitNumIA5(train, num: &asn.trainNum, ia5: &asn.trainIA5) }

        if let ct = api.stationCodeTable { asn.stationCodeTable = CodeTableTypeV2(rawValue: ct.rawValue) }
        if let s = api.fromStation { splitNumIA5Station(s, num: &asn.fromStationNum, ia5: &asn.fromStationIA5) }
        if let s = api.toStation { splitNumIA5Station(s, num: &asn.toStationNum, ia5: &asn.toStationIA5) }
        asn.fromStationNameUTF8 = api.fromStationName
        asn.toStationNameUTF8 = api.toStationName
        asn.coach = api.coachNumber
        asn.place = api.placeNumber
        if let rr = api.roofRackType { asn.roofRackType = RoofRackTypeV2(rawValue: rr.rawValue) }
        if let ld = api.loadingDeck { asn.loadingDeck = LoadingDeckTypeV2(rawValue: ld.rawValue) }
        asn.loadingListEntry = api.loadingListEntry
        if let pt = api.priceType { asn.priceType = PriceTypeTypeV2(rawValue: pt.rawValue) }
        asn.price = api.price
        asn.infoText = api.infoText
        if api.numberOfBoats != 0 { asn.attachedBoats = api.numberOfBoats }

        if let sb = api.serviceBrand {
            asn.serviceBrand = sb.serviceBrandNum
            asn.serviceBrandAbrUTF8 = sb.serviceBrandAbrUTF8
            asn.serviceBrandNameUTF8 = sb.serviceBrandNameUTF8
        }

        if !api.carriers.isEmpty {
            let (nums, ia5s) = splitNumIA5List(api.carriers)
            asn.carrierNum = nums.isEmpty ? nil : nums
            asn.carrierIA5 = ia5s.isEmpty ? nil : ia5s
        }

        // V2: tariff is non-optional (single TariffTypeV2, not array)
        if let firstTariff = api.tariffs.first {
            asn.tariff = convertTariff(firstTariff)
        }
        if !api.vatDetails.isEmpty { asn.vatDetail = api.vatDetails.map { convertVatDetail($0) } }
        if let ext = api.extensionData { asn.extensionData = convertExtension(ext) }

        // Date offsets
        if let depDate = api.departureDate, let issuingDate {
            asn.beginLoadingDate = DateTimeUtils.getDateDifference(issuingDate, depDate)
            asn.beginLoadingTime = DateTimeUtils.getTime(depDate)
        }
        if let arrDate = api.arrivalDate {
            asn.endLoadingTime = DateTimeUtils.getTime(arrDate)
        }

        return asn
    }

    // MARK: - Customer Card

    static func convertCustomerCard(_ api: CustomerCardAPI, issuingDate: Date?) -> CustomerCardDataV2 {
        var asn = CustomerCardDataV2()

        asn.cardIdNum = api.cardIdNum
        asn.cardIdIA5 = api.cardIdIA5

        // If reference is set but individual fields aren't, split the reference
        if api.cardIdNum == nil && api.cardIdIA5 == nil, let ref = api.reference {
            let (num, ia5) = splitNumIA5(ref)
            asn.cardIdNum = num
            asn.cardIdIA5 = ia5
        }

        asn.cardType = api.cardType
        asn.cardTypeDescr = api.cardTypeDescr
        if let cc = api.classCode { asn.classCode = TravelClassTypeV2(rawValue: cc.rawValue) }

        // V2: CustomerCardData uses absolute year + day-of-year, NOT day-offsets
        if let validFrom = api.validFrom {
            let cal = Calendar(identifier: .gregorian)
            let utc = TimeZone(identifier: "UTC")!
            let components = cal.dateComponents(in: utc, from: validFrom)
            asn.validFromYear = components.year ?? 2016
            var utcCal = cal; utcCal.timeZone = utc
            asn.validFromDay = utcCal.ordinality(of: .day, in: .year, for: validFrom)
        }
        if let validUntil = api.validUntil {
            let cal = Calendar(identifier: .gregorian)
            let utc = TimeZone(identifier: "UTC")!
            let components = cal.dateComponents(in: utc, from: validUntil)
            let untilYear = components.year ?? 2016
            asn.validUntilYear = untilYear - (asn.validFromYear ?? 2016)
            var utcCal = cal; utcCal.timeZone = utc
            asn.validUntilDay = utcCal.ordinality(of: .day, in: .year, for: validUntil)
        }

        if let ext = api.extensionData { asn.extensionData = convertExtension(ext) }
        return asn
    }

    // MARK: - Counter Mark

    static func convertCounterMark(_ api: CounterMarkAPI, issuingDate: Date?) -> CountermarkDataV2 {
        var asn = CountermarkDataV2()

        if let ref = api.reference { splitNumIA5(ref, num: &asn.referenceNum, ia5: &asn.referenceIA5) }
        if let pid = api.productId { splitNumIA5Constrained(pid, max: 65535, num: &asn.productIdNum, ia5: &asn.productIdIA5) }
        if let po = api.productOwner { splitNumIA5Constrained(po, max: 32000, num: &asn.productOwnerNum, ia5: &asn.productOwnerIA5) }

        if let ct = api.stationCodeTable { asn.stationCodeTable = CodeTableTypeV2(rawValue: ct.rawValue) }
        if let s = api.fromStation { splitNumIA5Station(s, num: &asn.fromStationNum, ia5: &asn.fromStationIA5) }
        if let s = api.toStation { splitNumIA5Station(s, num: &asn.toStationNum, ia5: &asn.toStationIA5) }
        asn.fromStationNameUTF8 = api.fromStationName
        asn.toStationNameUTF8 = api.toStationName
        asn.validRegionDesc = api.validRegionDesc
        if let cc = api.classCode { asn.classCode = TravelClassTypeV2(rawValue: cc.rawValue) }
        // V2: non-optional fields
        asn.numberOfCountermark = api.numberOfCountermark
        asn.totalOfCountermarks = api.totalOfCountermarks
        asn.groupName = api.groupName ?? ""
        asn.infoText = api.infoText

        if !api.carriers.isEmpty {
            let (nums, ia5s) = splitNumIA5List(api.carriers)
            asn.carrierNum = nums.isEmpty ? nil : nums
            asn.carrierIA5 = ia5s.isEmpty ? nil : ia5s
        }

        if !api.includedServiceBrands.isEmpty { asn.includedServiceBrands = api.includedServiceBrands }
        if !api.excludedServiceBrands.isEmpty { asn.excludedServiceBrands = api.excludedServiceBrands }

        if !api.validRegionList.isEmpty {
            asn.validRegion = api.validRegionList.compactMap { convertRegionalValidity($0) }
        }
        if let ret = api.returnDescription {
            asn.returnDescription = convertReturnRouteDescription(ret)
        }
        if let ext = api.extensionData { asn.extensionData = convertExtension(ext) }

        // Date offsets -- V2: validFromDay/validUntilDay are optional (no defaults)
        if let validFrom = api.validFrom, let issuingDate {
            asn.validFromDay = DateTimeUtils.getDateDifference(issuingDate, validFrom)
            asn.validFromTime = DateTimeUtils.getTime(validFrom)
        }
        if let validUntil = api.validUntil, let validFrom = api.validFrom {
            asn.validUntilDay = DateTimeUtils.getDateDifference(validFrom, validUntil)
            asn.validUntilTime = DateTimeUtils.getTime(validUntil)
        }

        return asn
    }

    // MARK: - Parking Ground

    static func convertParkingGround(_ api: ParkingGroundAPI, issuingDate: Date?) -> ParkingGroundDataV2 {
        var asn = ParkingGroundDataV2()

        if let ref = api.reference { splitNumIA5(ref, num: &asn.referenceNum, ia5: &asn.referenceIA5) }
        asn.parkingGroundId = api.parkingGroundId ?? ""
        if let ct = api.stationCodeTable { asn.stationCodeTable = CodeTableTypeV2(rawValue: ct.rawValue) }
        asn.stationNum = api.stationNum
        asn.stationIA5 = api.stationIA5
        asn.specialInformation = api.specialInformation
        asn.price = api.price

        if let po = api.productOwner { splitNumIA5Constrained(po, max: 32000, num: &asn.productOwnerNum, ia5: &asn.productOwnerIA5) }

        if !api.vatDetails.isEmpty { asn.vatDetail = api.vatDetails.map { convertVatDetail($0) } }
        if let ext = api.extensionData { asn.extensionData = convertExtension(ext) }

        // Date offsets
        if let fromDate = api.fromParkingDate, let issuingDate {
            asn.fromParkingDate = DateTimeUtils.getDateDifference(issuingDate, fromDate) ?? 0
        }
        if let toDate = api.toParkingDate, let fromDate = api.fromParkingDate {
            asn.toParkingDate = DateTimeUtils.getDateDifference(fromDate, toDate) ?? 0
        }

        return asn
    }

    // MARK: - FIP Ticket

    static func convertFIPTicket(_ api: FIPTicketAPI, issuingDate: Date?) -> FIPTicketDataV2 {
        var asn = FIPTicketDataV2()

        if let ref = api.reference { splitNumIA5(ref, num: &asn.referenceNum, ia5: &asn.referenceIA5) }
        if let pid = api.productId { splitNumIA5Constrained(pid, max: 65535, num: &asn.productIdNum, ia5: &asn.productIdIA5) }
        if let po = api.productOwner { splitNumIA5Constrained(po, max: 32000, num: &asn.productOwnerNum, ia5: &asn.productOwnerIA5) }

        if let cc = api.classCode { asn.classCode = TravelClassTypeV2(rawValue: cc.rawValue) }
        // V2: non-optional fields
        asn.numberOfTravelDays = api.numberOfTravelDays
        asn.includesSupplements = api.includesSupplements

        if !api.carriers.isEmpty {
            let (nums, ia5s) = splitNumIA5List(api.carriers)
            asn.carrierNum = nums.isEmpty ? nil : nums
            asn.carrierIA5 = ia5s.isEmpty ? nil : ia5s
        }

        if let ext = api.extensionData { asn.extensionData = convertExtension(ext) }

        // Date offsets -- V2: validFromDay/validUntilDay are optional (no defaults)
        // V2 constraint: validFromDay -1..700, validUntilDay 0..370
        if let validFrom = api.validFrom, let issuingDate {
            let diff = DateTimeUtils.getDateDifference(issuingDate, validFrom)
            asn.validFromDay = diff.map { max(-1, min(700, $0)) }
        }
        if let validUntil = api.validUntil, let validFrom = api.validFrom {
            let diff = DateTimeUtils.getDateDifference(validFrom, validUntil)
            asn.validUntilDay = diff.map { max(0, min(370, $0)) }
        }

        if !api.activatedDays.isEmpty, let validFrom = api.validFrom {
            asn.activatedDay = DateTimeUtils.getActivatedDays(referenceDate: validFrom, dates: api.activatedDays)
        }

        return asn
    }

    // MARK: - Station Passage

    static func convertStationPassage(_ api: StationPassageAPI, issuingDate: Date?) -> StationPassageDataV2 {
        var asn = StationPassageDataV2()

        if let ref = api.reference { splitNumIA5(ref, num: &asn.referenceNum, ia5: &asn.referenceIA5) }
        if let pid = api.productId { splitNumIA5Constrained(pid, max: 65535, num: &asn.productIdNum, ia5: &asn.productIdIA5) }
        if let po = api.productOwner { splitNumIA5Constrained(po, max: 32000, num: &asn.productOwnerNum, ia5: &asn.productOwnerIA5) }

        if let ct = api.stationCodeTable { asn.stationCodeTable = CodeTableTypeV2(rawValue: ct.rawValue) }
        if !api.stationNameUTF8.isEmpty { asn.stationNameUTF8 = api.stationNameUTF8 }
        if !api.stationNum.isEmpty { asn.stationNum = api.stationNum }
        if !api.stationIA5.isEmpty { asn.stationIA5 = api.stationIA5 }
        if api.numberOfDaysValid != 0 { asn.numberOfDaysValid = api.numberOfDaysValid }

        if let ext = api.extensionData { asn.extensionData = convertExtension(ext) }

        // Date offsets
        if let validFrom = api.validFrom, let issuingDate {
            asn.validFromDay = DateTimeUtils.getDateDifference(issuingDate, validFrom) ?? 0
            asn.validFromTime = DateTimeUtils.getTime(validFrom)
        }
        if let validUntil = api.validUntil, let validFrom = api.validFrom {
            asn.validUntilDay = DateTimeUtils.getDateDifference(validFrom, validUntil)
            asn.validUntilTime = DateTimeUtils.getTime(validUntil)
        }

        return asn
    }

    // MARK: - Delay Confirmation

    static func convertDelayConfirmation(_ api: DelayConfirmationAPI, issuingDate: Date?) -> DelayConfirmationV2 {
        var asn = DelayConfirmationV2()

        if let ref = api.reference { splitNumIA5(ref, num: &asn.referenceNum, ia5: &asn.referenceIA5) }
        if let train = api.train { splitNumIA5(train, num: &asn.trainNum, ia5: &asn.trainIA5) }

        asn.delay = api.delay
        if let ct = api.stationCodeTable { asn.stationCodeTable = CodeTableTypeV2(rawValue: ct.rawValue) }
        asn.stationNum = api.stationNum
        asn.stationIA5 = api.stationIA5
        if let ct = api.confirmationType { asn.confirmationType = ConfirmationTypeTypeV2(rawValue: ct.rawValue) }
        asn.infoText = api.infoText

        if !api.affectedTickets.isEmpty {
            asn.affectedTickets = api.affectedTickets.map { convertTicketLink($0) }
        }

        if let ext = api.extensionData { asn.extensionData = convertExtension(ext) }

        // Date offsets -- uses year + day-of-year pattern
        if let arrDate = api.plannedArrivalDate {
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = TimeZone(identifier: "UTC")!
            asn.plannedArrivalYear = cal.component(.year, from: arrDate)
            asn.plannedArrivalDay = cal.ordinality(of: .day, in: .year, for: arrDate) ?? 1
            asn.plannedArrivalTime = DateTimeUtils.getTime(arrDate)
        }

        return asn
    }

    // MARK: - Voucher

    static func convertVoucher(_ api: VoucherAPI, issuingDate: Date?) -> VoucherDataV2 {
        var asn = VoucherDataV2()

        if let ref = api.reference { splitNumIA5(ref, num: &asn.referenceNum, ia5: &asn.referenceIA5) }
        if let pid = api.productId { splitNumIA5Constrained(pid, max: 65535, num: &asn.productIdNum, ia5: &asn.productIdIA5) }
        if let po = api.productOwner { splitNumIA5Constrained(po, max: 32000, num: &asn.productOwnerNum, ia5: &asn.productOwnerIA5) }

        if api.amount != 0 { asn.value = api.amount }
        // V2: field is `type` (not `voucherType`)
        if api.type != 0 { asn.type = api.type }
        asn.infoText = api.infoText

        if let ext = api.extensionData { asn.extensionData = convertExtension(ext) }

        // Date offsets -- VoucherDataV2 uses year + day-of-year pattern
        if let validFrom = api.validFrom {
            let cal = Calendar(identifier: .gregorian)
            let utc = TimeZone(identifier: "UTC")!
            let components = cal.dateComponents(in: utc, from: validFrom)
            asn.validFromYear = components.year ?? 2016
            var utcCal = cal; utcCal.timeZone = utc
            asn.validFromDay = utcCal.ordinality(of: .day, in: .year, for: validFrom) ?? 1
        }
        if let validUntil = api.validUntil {
            let cal = Calendar(identifier: .gregorian)
            let utc = TimeZone(identifier: "UTC")!
            let components = cal.dateComponents(in: utc, from: validUntil)
            asn.validUntilYear = components.year ?? 2016
            var utcCal = cal; utcCal.timeZone = utc
            asn.validUntilDay = utcCal.ordinality(of: .day, in: .year, for: validUntil) ?? 1
        }

        return asn
    }

    // MARK: - Document Extension

    static func convertDocumentExtension(_ api: DocumentExtensionAPI) -> ExtensionDataV2 {
        var ext = ExtensionDataV2()
        ext.extensionId = api.extensionId ?? ""
        ext.extensionData = api.extensionData ?? Data()
        return ext
    }

    // MARK: - Supporting Type Conversions

    static func convertToken(_ api: TokenAPI?) -> TokenTypeV2? {
        guard let api else { return nil }
        var t = TokenTypeV2()
        t.tokenProviderIA5 = api.tokenProviderIA5
        t.tokenProviderNum = api.tokenProviderNum
        t.tokenSpecification = api.tokenSpecification
        t.token = api.token ?? Data()
        return t
    }

    static func convertExtension(_ api: TicketExtension) -> ExtensionDataV2 {
        var ext = ExtensionDataV2()
        ext.extensionId = api.extensionId ?? ""
        ext.extensionData = api.extensionData ?? Data()
        return ext
    }

    static func convertGeoCoordinate(_ api: GeoCoordinateAPI) -> GeoCoordinateTypeV2 {
        var g = GeoCoordinateTypeV2()
        g.longitude = Int(api.longitude)
        g.latitude = Int(api.latitude)
        g.coordinateSystem = GeoCoordinateSystemTypeV2(rawValue: api.coordinateSystem.rawValue)
        g.geoUnit = GeoUnitTypeV2(rawValue: api.accuracy.rawValue)
        g.hemisphereLongitude = HemisphereLongitudeTypeV2(rawValue: api.hemisphereLongitude.rawValue)
        g.hemisphereLatitude = HemisphereLatitudeTypeV2(rawValue: api.hemisphereLatitude.rawValue)
        return g
    }

    static func convertCardReference(_ api: CardReferenceAPI) -> CardReferenceTypeV2 {
        var c = CardReferenceTypeV2()
        c.cardIssuerNum = api.cardIssuerNum
        c.cardIssuerIA5 = api.cardIssuerIA5
        c.cardIdNum = api.cardIdNum
        c.cardIdIA5 = api.cardIdIA5
        c.cardName = api.cardName
        c.cardType = api.cardType
        c.leadingCardIdNum = api.leadingCardIdNum
        c.leadingCardIdIA5 = api.leadingCardIdIA5
        c.trailingCardIdNum = api.trailingCardIdNum
        c.trailingCardIdIA5 = api.trailingCardIdIA5
        return c
    }

    static func convertTicketLink(_ api: TicketLinkAPI) -> TicketLinkTypeV2 {
        var t = TicketLinkTypeV2()
        t.referenceIA5 = api.referenceIA5
        t.referenceNum = api.referenceNum
        t.issuerName = api.issuerName
        t.issuerPNR = api.issuerPNR
        t.productOwnerNum = api.productOwnerNum
        t.productOwnerIA5 = api.productOwnerIA5
        if let tt = api.ticketType { t.ticketType = TicketTypeV2(rawValue: tt.rawValue) }
        if let lm = api.linkMode { t.linkMode = LinkModeV2(rawValue: lm.rawValue) }
        return t
    }

    static func convertPlaces(_ api: PlacesAPI) -> PlacesTypeV2 {
        var p = PlacesTypeV2()
        p.coach = api.coach
        p.placeString = api.placeString
        if !api.placeNum.isEmpty { p.placeNum = api.placeNum }
        p.placeDescription = api.placeDescription
        return p
    }

    static func convertCompartmentDetails(_ api: CompartmentDetailsAPI) -> CompartmentDetailsTypeV2 {
        var c = CompartmentDetailsTypeV2()
        c.coachType = api.coachType
        c.compartmentType = api.compartmentType
        c.specialAllocation = api.specialAllocation
        c.coachTypeDescr = api.coachTypeDescr
        c.compartmentTypeDescr = api.compartmentTypeDescr
        c.specialAllocationDescr = api.specialAllocationDescr
        if let pos = api.position { c.position = CompartmentPositionTypeV2(rawValue: pos.rawValue) }
        return c
    }

    static func convertBerth(_ api: BerthAPI) -> BerthDetailDataV2 {
        var b = BerthDetailDataV2()
        // V2: berthType is non-optional
        if let bt = api.berthType { b.berthType = BerthTypeTypeV2(rawValue: bt.rawValue) ?? .single }
        b.numberOfBerths = api.numberOfBerths
        if let g = api.gender { b.gender = CompartmentGenderTypeV2(rawValue: g.rawValue) }
        return b
    }

    static func convertTariff(_ api: TariffAPI) -> TariffTypeV2 {
        var t = TariffTypeV2()
        if api.numberOfPassengers != 1 { t.numberOfPassengers = api.numberOfPassengers }
        if let pt = api.passengerType { t.passengerType = PassengerTypeV2(rawValue: pt.rawValue) }
        t.ageBelow = api.ageBelow
        t.ageAbove = api.ageAbove
        t.tariffIdNum = api.tariffIdNum
        t.tariffIdIA5 = api.tariffIdIA5
        t.tariffDesc = api.tariffDesc
        if !api.reductionCard.isEmpty {
            t.reductionCard = api.reductionCard.map { convertCardReference($0) }
        }
        if let series = api.seriesDataDetails {
            t.seriesDataDetails = convertSeriesDetail(series)
        }
        return t
    }

    static func convertSeriesDetail(_ api: SeriesDetailAPI) -> SeriesDetailTypeV2 {
        var s = SeriesDetailTypeV2()
        s.supplyingCarrier = api.supplyingCarrier
        s.offerIdentification = api.offerIdentification
        s.series = api.series
        return s
    }

    static func convertVatDetail(_ api: VatDetailAPI) -> VatDetailTypeV2 {
        var v = VatDetailTypeV2()
        v.country = api.country ?? 0
        v.percentage = api.percentage ?? 0
        v.amount = api.amount
        v.vatId = api.vatId
        return v
    }

    static func convertLuggageRestriction(_ api: LuggageRestrictionAPI) -> LuggageRestrictionTypeV2 {
        var l = LuggageRestrictionTypeV2()
        l.maxHandLuggagePieces = api.maxHandLuggagePieces
        l.maxNonHandLuggagePieces = api.maxNonHandLuggagePieces
        if !api.registeredLuggage.isEmpty {
            l.registeredLuggage = api.registeredLuggage.map { rl in
                var r = RegisteredLuggageTypeV2()
                r.maxWeight = rl.maxWeight
                r.maxSize = rl.maxSize
                r.registrationId = rl.registrationId
                return r
            }
        }
        return l
    }

    static func convertRegionalValidity(_ api: RegionalValidityAPI) -> RegionalValidityTypeV2? {
        var r = RegionalValidityTypeV2()
        switch api {
        case .trainLink(let trainLink):
            r.validity = .trainLink(convertTrainLink(trainLink))
        case .viaStations(let via):
            r.validity = .viaStations(convertViaStation(via))
        case .zone(let zone):
            r.validity = .zone(convertZone(zone))
        case .line(let line):
            r.validity = .line(convertLine(line))
        case .polygone(let poly):
            r.validity = .polygone(convertPolygone(poly))
        }
        return r
    }

    static func convertTrainLink(_ api: TrainLinkAPI) -> TrainLinkTypeV2 {
        var t = TrainLinkTypeV2()
        t.trainNum = api.trainNum
        t.trainIA5 = api.trainIA5
        t.departureTime = api.departureTime ?? 0
        if let s = api.fromStation { splitNumIA5Station(s, num: &t.fromStationNum, ia5: &t.fromStationIA5) }
        if let s = api.toStation { splitNumIA5Station(s, num: &t.toStationNum, ia5: &t.toStationIA5) }
        t.fromStationNameUTF8 = api.fromStationName
        t.toStationNameUTF8 = api.toStationName
        return t
    }

    static func convertViaStation(_ api: ViaStationAPI) -> ViaStationTypeV2 {
        var v = ViaStationTypeV2()
        if let ct = api.stationCodeTable { v.stationCodeTable = CodeTableTypeV2(rawValue: ct.rawValue) }
        v.stationNum = api.stationNum
        v.stationIA5 = api.stationIA5
        if !api.carriersNum.isEmpty { v.carriersNum = api.carriersNum }
        if !api.carriersIA5.isEmpty { v.carriersIA5 = api.carriersIA5 }
        v.border = api.border
        v.seriesId = api.seriesId
        v.routeId = api.routeId
        if !api.route.isEmpty { v.route = api.route.map { convertViaStation($0) } }
        // V2: alternativeRoutes is [ViaStationTypeV2]? (flat), API has [[ViaStationAPI]] (nested)
        if !api.alternativeRoutes.isEmpty {
            v.alternativeRoutes = api.alternativeRoutes.flatMap { $0 }.map { convertViaStation($0) }
        }
        return v
    }

    static func convertZone(_ api: ZoneAPI) -> ZoneTypeV2 {
        var z = ZoneTypeV2()
        if let ct = api.stationCodeTable { z.stationCodeTable = CodeTableTypeV2(rawValue: ct.rawValue) }
        z.carrierNum = api.carrierNum
        z.carrierIA5 = api.carrierIA5
        if !api.zoneId.isEmpty { z.zoneId = api.zoneId }
        z.city = api.city
        z.binaryZoneId = api.binaryZoneId
        z.nutsCode = api.nutsCode
        return z
    }

    static func convertLine(_ api: LineAPI) -> LineTypeV2 {
        var l = LineTypeV2()
        if let ct = api.stationCodeTable { l.stationCodeTable = CodeTableTypeV2(rawValue: ct.rawValue) }
        l.carrierNum = api.carrierNum
        l.carrierIA5 = api.carrierIA5
        if !api.lineId.isEmpty { l.lineId = api.lineId }
        return l
    }

    static func convertPolygone(_ api: PolygoneAPI) -> PolygoneTypeV2 {
        var firstEdge = GeoCoordinateTypeV2()
        if let fe = api.firstEdge { firstEdge = convertGeoCoordinate(fe) }
        let edges = api.edges.map { edge in
            var d = DeltaCoordinatesV2()
            d.longitude = edge.longitude
            d.latitude = edge.latitude
            return d
        }
        return PolygoneTypeV2(firstEdge: firstEdge, edges: edges)
    }

    static func convertReturnRouteDescription(_ api: ReturnRouteDescriptionAPI) -> ReturnRouteDescriptionTypeV2 {
        var r = ReturnRouteDescriptionTypeV2()
        if let s = api.fromStation { splitNumIA5Station(s, num: &r.fromStationNum, ia5: &r.fromStationIA5) }
        if let s = api.toStation { splitNumIA5Station(s, num: &r.toStationNum, ia5: &r.toStationIA5) }
        r.fromStationNameUTF8 = api.fromStationName
        r.toStationNameUTF8 = api.toStationName
        r.validReturnRegionDesc = api.validRegionDesc
        if !api.validRegionList.isEmpty {
            r.validReturnRegion = api.validRegionList.compactMap { convertRegionalValidity($0) }
        }
        return r
    }

    static func convertIncludedOpenTicket(_ api: IncludedOpenTicketAPI) -> IncludedOpenTicketTypeV2 {
        var i = IncludedOpenTicketTypeV2()
        i.productOwnerNum = api.productOwnerNum
        i.productOwnerIA5 = api.productOwnerIA5
        i.productIdNum = api.productIdNum
        i.productIdIA5 = api.productIdIA5
        // V2: uses `externalIssuerId` and `issuerAuthorizationId`
        i.externalIssuerId = api.externalIssuerId
        i.issuerAuthorizationId = api.authorizationCode
        if let ct = api.stationCodeTable { i.stationCodeTable = CodeTableTypeV2(rawValue: ct.rawValue) }
        if let cc = api.classCode { i.classCode = TravelClassTypeV2(rawValue: cc.rawValue) }
        i.serviceLevel = api.serviceLevel
        i.infoText = api.infoText

        if !api.includedCarriers.isEmpty {
            let (nums, ia5s) = splitNumIA5List(api.includedCarriers)
            i.carrierNum = nums.isEmpty ? nil : nums
            i.carrierIA5 = ia5s.isEmpty ? nil : ia5s
        }

        if !api.includedServiceBrands.isEmpty { i.includedServiceBrands = api.includedServiceBrands }
        if !api.excludedServiceBrands.isEmpty { i.excludedServiceBrands = api.excludedServiceBrands }
        if !api.includedTransportTypes.isEmpty { i.includedTransportTypes = api.includedTransportTypes }
        if !api.excludedTransportTypes.isEmpty { i.excludedTransportTypes = api.excludedTransportTypes }

        if !api.validRegionList.isEmpty {
            i.validRegion = api.validRegionList.compactMap { convertRegionalValidity($0) }
        }
        if !api.tariffs.isEmpty { i.tariffs = api.tariffs.map { convertTariff($0) } }
        if let ext = api.extensionData { i.extensionData = convertExtension(ext) }
        return i
    }

    static func convertValidityDetails(_ api: ValidityDetailsAPI) -> ValidityPeriodDetailTypeV2 {
        var vpd = ValidityPeriodDetailTypeV2()
        if !api.validityPeriods.isEmpty {
            vpd.validityPeriod = api.validityPeriods.map { _ in
                ValidityPeriodTypeV2()
            }
        }
        if !api.excludedTimeRanges.isEmpty {
            vpd.excludedTimeRange = api.excludedTimeRanges.map { range in
                TimeRangeTypeV2(fromTime: range.fromTime ?? 0, untilTime: range.untilTime ?? 0)
            }
        }
        return vpd
    }

    // MARK: - Num/IA5 Splitting Utilities

    /// Split a string into numeric and IA5 parts.
    /// If the string is purely numeric, only num is set. Otherwise, only IA5 is set.
    static func splitNumIA5(_ value: String) -> (num: Int?, ia5: String?) {
        if let num = Int(value) {
            return (num, nil)
        }
        return (nil, value)
    }

    /// Split into num/ia5 using inout parameters
    static func splitNumIA5(_ value: String, num: inout Int?, ia5: inout String?) {
        if let n = Int(value) {
            num = n
        } else {
            ia5 = value
        }
    }

    /// Split with constraint: only set num if value fits within [0, max]
    static func splitNumIA5Constrained(_ value: String, max: Int, num: inout Int?, ia5: inout String?) {
        if let n = Int(value), n >= 0, n <= max {
            num = n
        } else {
            ia5 = value
        }
    }

    /// Split with constraint, returning tuple
    static func splitNumIA5Constrained(_ value: String, max: Int) -> (num: Int?, ia5: String?) {
        if let n = Int(value), n >= 0, n <= max {
            return (n, nil)
        }
        return (nil, value)
    }

    /// Split station string (constraint: 1..9999999)
    static func splitNumIA5Station(_ value: String, num: inout Int?, ia5: inout String?) {
        if let n = Int(value), n >= 1, n <= 9999999 {
            num = n
        } else {
            ia5 = value
        }
    }

    /// Split a list of strings into numeric and IA5 lists.
    /// Each element goes to either the num list or the IA5 list.
    static func splitNumIA5List(_ values: [String]) -> (nums: [Int], ia5s: [String]) {
        var nums = [Int]()
        var ia5s = [String]()
        for value in values {
            if let n = Int(value) {
                nums.append(n)
            } else {
                ia5s.append(value)
            }
        }
        return (nums, ia5s)
    }
}
