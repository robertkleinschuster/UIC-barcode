import Foundation

/// Converts V2 ASN.1 model objects to version-independent API objects
enum ASNToAPIDecoderV2 {

    /// Convert a V2 UicRailTicketData to the version-independent API representation
    static func decode(_ asn: UicRailTicketDataV2) -> SimpleUicRailTicket {
        let ticket = SimpleUicRailTicket()

        ticket.issuingDetail = convertIssuingDetail(asn.issuingDetail)
        let issuingDate = ticket.issuingDetail?.issuingDate

        if let travelerData = asn.travelerDetail {
            ticket.travelerDetail = convertTravelerDetail(travelerData)
        }

        if let controlData = asn.controlDetail {
            ticket.controlDetail = convertControlDetail(controlData)
        }

        if let documents = asn.transportDocument {
            for doc in documents {
                if let apiDoc = convertDocument(doc, issuingDate: issuingDate) {
                    ticket.addDocument(apiDoc)
                }
            }
        }

        if let extensions = asn.extensionData {
            for ext in extensions {
                ticket.extensions.append(convertExtension(ext))
            }
        }

        return ticket
    }

    // MARK: - Issuing Detail

    static func convertIssuingDetail(_ asn: IssuingDataV2) -> SimpleIssuingDetail {
        let detail = SimpleIssuingDetail()

        detail.specimen = asn.specimen
        detail.activated = asn.activated
        detail.securePaperTicket = asn.securePaperTicket

        if let ia5 = asn.securityProviderIA5 {
            detail.securityProvider = ia5
        } else if let num = asn.securityProviderNum {
            detail.securityProvider = String(num)
        }

        if let ia5 = asn.issuerIA5 {
            detail.issuer = ia5
        } else if let num = asn.issuerNum {
            detail.issuer = String(num)
        }

        detail.issuerName = asn.issuerName
        detail.issuerPNR = asn.issuerPNR

        detail.issuingDate = dateFromDayOfYear(year: asn.issuingYear, day: asn.issuingDay, time: asn.issuingTime)

        if let ia5 = asn.issuedOnTrainIA5 {
            detail.issuedOnTrain = ia5
        } else if let num = asn.issuedOnTrainNum {
            detail.issuedOnTrain = String(num)
        }

        detail.issuedOnLine = asn.issuedOnLine
        detail.currency = asn.currency
        detail.currencyFraction = asn.currencyFract

        if let gps = asn.pointOfSale {
            detail.pointOfSale = convertGeoCoordinate(gps)
        }

        if let ext = asn.extensionData {
            detail.extensionData = convertExtension(ext)
        }

        return detail
    }

    // MARK: - Traveler Detail

    static func convertTravelerDetail(_ asn: TravelerDataV2) -> SimpleTravelerDetail {
        let detail = SimpleTravelerDetail()

        detail.preferedLanguage = asn.preferedLanguage
        detail.groupName = asn.groupName

        if let travelers = asn.traveler {
            for t in travelers {
                detail.travelers.append(convertTraveler(t))
            }
        }

        return detail
    }

    static func convertTraveler(_ asn: TravelerTypeV2) -> SimpleTraveler {
        let t = SimpleTraveler()

        t.firstName = asn.firstName
        t.secondName = asn.secondName
        t.lastName = asn.lastName
        t.idCard = asn.idCard
        t.passportId = asn.passportId
        t.title = asn.title
        if let g = asn.gender { t.gender = GenderType(rawValue: g.rawValue) }
        t.ticketHolder = asn.ticketHolder
        if let pt = asn.passengerType { t.passengerType = PassengerType(rawValue: pt.rawValue) }
        t.passengerWithReducedMobility = asn.passengerWithReducedMobility
        t.countryOfResidence = asn.countryOfResidence
        t.passportCountry = asn.countryOfPassport
        t.idCardCountry = asn.countryOfIdCard

        if let ia5 = asn.customerIdIA5 {
            t.customerId = ia5
        } else if let num = asn.customerIdNum {
            t.customerId = String(num)
        }

        if let year = asn.yearOfBirth {
            var components = DateComponents()
            components.year = year
            components.month = asn.monthOfBirth ?? 1
            components.day = asn.dayOfBirth ?? 1
            components.timeZone = TimeZone(identifier: "UTC")
            t.dateOfBirth = Calendar(identifier: .gregorian).date(from: components)
        }

        if let statuses = asn.status {
            for s in statuses {
                var desc = CustomerStatusDescription()
                desc.statusProviderNum = s.statusProviderNum
                desc.statusProviderIA5 = s.statusProviderIA5
                desc.customerStatus = s.customerStatus
                desc.customerStatusDescr = s.customerStatusDescr
                t.status.append(desc)
            }
        }

        return t
    }

    // MARK: - Control Detail

    static func convertControlDetail(_ asn: ControlDataV2) -> SimpleControlDetail {
        let detail = SimpleControlDetail()

        detail.identificationByIdCard = asn.identificationByIdCard
        detail.identificationByPassportId = asn.identificationByPassportId
        detail.passportValidationRequired = asn.passportValidationRequired
        detail.onlineValidationRequired = asn.onlineValidationRequired
        detail.ageCheckRequired = asn.ageCheckRequired
        detail.reductionCardCheckRequired = asn.reductionCardCheckRequired
        detail.infoText = asn.infoText

        if let cards = asn.identificationByCardReference {
            for card in cards {
                detail.identificationByCardReference.append(convertCardReference(card))
            }
        }

        if let tickets = asn.includedTickets {
            for ticket in tickets {
                detail.includedTickets.append(convertTicketLink(ticket))
            }
        }

        if let ext = asn.extensionData {
            detail.extensionData = convertExtension(ext)
        }

        return detail
    }

    // MARK: - Document Conversion

    static func convertDocument(_ asn: DocumentDataV2, issuingDate: Date?) -> APIDocumentData? {
        guard let ticketType = asn.ticket.ticketType else { return nil }

        switch ticketType {
        case .reservation(let res):
            return .reservation(convertReservation(res, token: asn.token, issuingDate: issuingDate))
        case .openTicket(let open):
            return .openTicket(convertOpenTicket(open, token: asn.token, issuingDate: issuingDate))
        case .pass(let pass):
            return .pass(convertPass(pass, token: asn.token, issuingDate: issuingDate))
        case .carCarriageReservation(let car):
            return .carCarriageReservation(convertCarCarriageReservation(car, token: asn.token, issuingDate: issuingDate))
        case .customerCard(let card):
            return .customerCard(convertCustomerCard(card, token: asn.token))
        case .countermark(let counter):
            return .counterMark(convertCounterMark(counter, token: asn.token, issuingDate: issuingDate))
        case .parkingGround(let parking):
            return .parkingGround(convertParkingGround(parking, token: asn.token, issuingDate: issuingDate))
        case .fipTicket(let fip):
            return .fipTicket(convertFIPTicket(fip, token: asn.token, issuingDate: issuingDate))
        case .stationPassage(let passage):
            return .stationPassage(convertStationPassage(passage, token: asn.token, issuingDate: issuingDate))
        case .delayConfirmation(let delay):
            return .delayConfirmation(convertDelayConfirmation(delay, token: asn.token))
        case .voucher(let voucher):
            return .voucher(convertVoucher(voucher, token: asn.token))
        case .ticketExtension(let ext):
            return .documentExtension(convertDocumentExtension(ext))
        case .unknown:
            return nil
        }
    }

    // MARK: - Reservation

    static func convertReservation(_ asn: ReservationDataV2, token: TokenTypeV2?, issuingDate: Date? = nil) -> Reservation {
        let r = Reservation()
        r.token = convertToken(token)

        r.departureDate = DateTimeUtils.getDate(issuingDate: issuingDate, dayOffset: asn.departureDate ?? 0, time: asn.departureTime)
        r.arrivalDate = DateTimeUtils.getDate(issuingDate: issuingDate, dayOffset: (asn.departureDate ?? 0) + (asn.arrivalDate ?? 0), time: asn.arrivalTime)

        r.reference = asn.referenceIA5 ?? (asn.referenceNum.map { String($0) })
        r.productId = asn.productIdIA5 ?? (asn.productIdNum.map { String($0) })
        r.productOwner = asn.productOwnerIA5 ?? (asn.productOwnerNum.map { String($0) })
        r.train = asn.trainIA5 ?? (asn.trainNum.map { String($0) })

        if let ct = asn.stationCodeTable { r.stationCodeTable = CodeTableType(rawValue: ct.rawValue) }
        r.fromStation = asn.fromStationIA5 ?? (asn.fromStationNum.map { String($0) })
        r.toStation = asn.toStationIA5 ?? (asn.toStationNum.map { String($0) })
        r.fromStationName = asn.fromStationNameUTF8
        r.toStationName = asn.toStationNameUTF8

        if let cc = asn.classCode { r.classCode = TravelClassType(rawValue: cc.rawValue) }
        r.serviceLevel = asn.serviceLevel
        if let svc = asn.service { r.service = ServiceType(rawValue: svc.rawValue) }
        r.numberOfOverbooked = asn.numberOfOverbooked ?? 0
        r.typeOfSupplement = asn.typeOfSupplement ?? 0
        r.numberOfSupplements = asn.numberOfSupplements ?? 0
        r.infoText = asn.infoText
        if let pt = asn.priceType { r.priceType = PriceTypeType(rawValue: pt.rawValue) }
        r.price = asn.price

        if let num = asn.serviceBrand {
            var sb = ServiceBrandAPI()
            sb.serviceBrandNum = num
            sb.serviceBrandAbrUTF8 = asn.serviceBrandAbrUTF8
            sb.serviceBrandNameUTF8 = asn.serviceBrandNameUTF8
            r.serviceBrand = sb
        }

        if let carriersIA5 = asn.carrierIA5 {
            r.carriers = carriersIA5
        } else if let carriers = asn.carrierNum {
            r.carriers = carriers.map { String($0) }
        }

        if let p = asn.places { r.places = convertPlaces(p) }
        if let p = asn.additionalPlaces { r.additionalPlaces = convertPlaces(p) }
        if let p = asn.bicyclePlaces { r.bicyclePlaces = convertPlaces(p) }
        if let c = asn.compartmentDetails { r.compartmentDetails = convertCompartmentDetails(c) }

        if let berths = asn.berth {
            r.berths = berths.map { convertBerth($0) }
        }

        if let tariffs = asn.tariff {
            r.tariffs = tariffs.map { convertTariff($0) }
        }

        if let vats = asn.vatDetail {
            r.vatDetails = vats.map { convertVatDetail($0) }
        }

        if let luggage = asn.luggage { r.luggageRestriction = convertLuggageRestriction(luggage) }
        if let ext = asn.extensionData { r.extensionData = convertExtension(ext) }

        r.departureUTCoffset = asn.departureUTCOffset
        r.arrivalUTCoffset = asn.arrivalUTCOffset

        return r
    }

    // MARK: - Open Ticket

    static func convertOpenTicket(_ asn: OpenTicketDataV2, token: TokenTypeV2?, issuingDate: Date? = nil) -> OpenTicket {
        let o = OpenTicket()
        o.token = convertToken(token)

        o.validFrom = DateTimeUtils.getDate(issuingDate: issuingDate, dayOffset: asn.validFromDay ?? 0, time: asn.validFromTime)
        o.validUntil = DateTimeUtils.getDate(issuingDate: issuingDate, dayOffset: (asn.validFromDay ?? 0) + (asn.validUntilDay ?? 0), time: asn.validUntilTime ?? 1439)
        if let activatedDay = asn.activatedDay {
            o.activatedDays = activatedDay.compactMap { DateTimeUtils.getDate(issuingDate: o.validFrom, dayOffset: $0, time: nil) }
        }

        o.reference = asn.referenceIA5 ?? (asn.referenceNum.map { String($0) })
        o.productId = asn.productIdIA5 ?? (asn.productIdNum.map { String($0) })
        o.productOwner = asn.productOwnerIA5 ?? (asn.productOwnerNum.map { String($0) })
        o.externalIssuer = asn.extIssuerId
        o.authorizationCode = asn.issuerAuthorizationId
        o.returnIncluded = asn.returnIncluded

        if let ct = asn.stationCodeTable { o.stationCodeTable = CodeTableType(rawValue: ct.rawValue) }
        o.fromStation = asn.fromStationIA5 ?? (asn.fromStationNum.map { String($0) })
        o.toStation = asn.toStationIA5 ?? (asn.toStationNum.map { String($0) })
        o.fromStationName = asn.fromStationNameUTF8
        o.toStationName = asn.toStationNameUTF8
        o.validRegionDesc = asn.validRegionDesc

        if let cc = asn.classCode { o.classCode = TravelClassType(rawValue: cc.rawValue) }
        o.serviceLevel = asn.serviceLevel
        o.infoText = asn.infoText
        o.price = asn.price

        if let carriersIA5 = asn.carrierIA5 {
            o.includedCarriers = carriersIA5
        } else if let carriers = asn.carrierNum {
            o.includedCarriers = carriers.map { String($0) }
        }

        o.includedServiceBrands = asn.includedServiceBrands ?? []
        o.excludedServiceBrands = asn.excludedServiceBrands ?? []
        o.includedTransportTypes = asn.includedTransportTypes ?? []
        o.excludedTransportTypes = asn.excludedTransportTypes ?? []

        if let region = asn.validRegion {
            o.validRegionList = region.compactMap { convertRegionalValidity($0) }
        }

        if let ret = asn.returnDescription {
            o.returnDescription = convertReturnRouteDescription(ret)
        }

        if let tariffs = asn.tariffs {
            o.tariffs = tariffs.map { convertTariff($0) }
        }

        if let vats = asn.vatDetail {
            o.vatDetails = vats.map { convertVatDetail($0) }
        }

        if let addOns = asn.includedAddOns {
            o.includedAddOns = addOns.map { convertIncludedOpenTicket($0) }
        }

        if let luggage = asn.luggage { o.luggageRestriction = convertLuggageRestriction(luggage) }
        if let ext = asn.extensionData { o.extensionData = convertExtension(ext) }

        o.validFromUTCoffset = asn.validFromUTCOffset
        o.validUntilUTCoffset = asn.validUntilUTCOffset

        return o
    }

    // MARK: - Pass

    static func convertPass(_ asn: PassDataV2, token: TokenTypeV2?, issuingDate: Date? = nil) -> Pass {
        let p = Pass()
        p.token = convertToken(token)

        p.validFrom = DateTimeUtils.getDate(issuingDate: issuingDate, dayOffset: asn.validFromDay ?? 0, time: asn.validFromTime)
        p.validUntil = DateTimeUtils.getDate(issuingDate: issuingDate, dayOffset: (asn.validFromDay ?? 0) + (asn.validUntilDay ?? 0), time: asn.validUntilTime ?? 1439)
        if let activatedDay = asn.activatedDay {
            p.activatedDays = activatedDay.compactMap { DateTimeUtils.getDate(issuingDate: p.validFrom, dayOffset: $0, time: nil) }
        }

        p.reference = asn.referenceIA5 ?? (asn.referenceNum.map { String($0) })
        p.productId = asn.productIdIA5 ?? (asn.productIdNum.map { String($0) })
        p.productOwner = asn.productOwnerIA5 ?? (asn.productOwnerNum.map { String($0) })

        p.passType = asn.passType ?? 0
        p.passDescription = asn.passDescription
        if let cc = asn.classCode { p.classCode = TravelClassType(rawValue: cc.rawValue) }
        p.numberOfValidityDays = asn.numberOfValidityDays ?? 0
        p.numberOfPossibleTrips = asn.numberOfPossibleTrips ?? 0
        p.numberOfDaysOfTravel = asn.numberOfDaysOfTravel ?? 0
        p.infoText = asn.infoText
        p.price = asn.price

        p.countries = asn.countries ?? []

        if let carriersIA5 = asn.includedCarrierIA5 {
            p.includedCarriers = carriersIA5
        } else if let carriers = asn.includedCarrierNum {
            p.includedCarriers = carriers.map { String($0) }
        }
        if let carriersIA5 = asn.excludedCarrierIA5 {
            p.excludedCarriers = carriersIA5
        } else if let carriers = asn.excludedCarrierNum {
            p.excludedCarriers = carriers.map { String($0) }
        }

        p.includedServiceBrands = asn.includedServiceBrands ?? []
        p.excludedServiceBrands = asn.excludedServiceBrands ?? []

        if let region = asn.validRegion {
            p.validRegionList = region.compactMap { convertRegionalValidity($0) }
        }

        if let tariffs = asn.tariffs {
            p.tariffs = tariffs.map { convertTariff($0) }
        }

        if let vats = asn.vatDetail {
            p.vatDetails = vats.map { convertVatDetail($0) }
        }

        if let vpd = asn.validityPeriodDetails {
            p.validityDetails = convertValidityDetails(vpd)
        }

        if let ext = asn.extensionData { p.extensionData = convertExtension(ext) }

        p.validFromUTCoffset = asn.validFromUTCOffset
        p.validUntilUTCoffset = asn.validUntilUTCOffset

        return p
    }

    // MARK: - Car Carriage Reservation

    static func convertCarCarriageReservation(_ asn: CarCarriageReservationDataV2, token: TokenTypeV2?, issuingDate: Date? = nil) -> CarCarriageReservationAPI {
        let c = CarCarriageReservationAPI()
        c.token = convertToken(token)

        c.departureDate = DateTimeUtils.getDate(issuingDate: issuingDate, dayOffset: asn.beginLoadingDate ?? 0, time: asn.beginLoadingTime)
        c.arrivalDate = DateTimeUtils.getDate(issuingDate: issuingDate, dayOffset: asn.beginLoadingDate ?? 0, time: asn.endLoadingTime)

        c.reference = asn.referenceIA5 ?? (asn.referenceNum.map { String($0) })
        c.productId = asn.productIdIA5 ?? (asn.productIdNum.map { String($0) })
        c.productOwner = asn.productOwnerIA5 ?? (asn.productOwnerNum.map { String($0) })
        c.train = asn.trainIA5 ?? (asn.trainNum.map { String($0) })
        if let ct = asn.stationCodeTable { c.stationCodeTable = CodeTableType(rawValue: ct.rawValue) }
        c.fromStation = asn.fromStationIA5 ?? (asn.fromStationNum.map { String($0) })
        c.toStation = asn.toStationIA5 ?? (asn.toStationNum.map { String($0) })
        c.fromStationName = asn.fromStationNameUTF8
        c.toStationName = asn.toStationNameUTF8
        c.coachNumber = asn.coach
        c.placeNumber = asn.place
        if let rr = asn.roofRackType { c.roofRackType = RoofRackType(rawValue: rr.rawValue) }
        if let ld = asn.loadingDeck { c.loadingDeck = LoadingDeckType(rawValue: ld.rawValue) }
        c.loadingListEntry = asn.loadingListEntry
        if let pt = asn.priceType { c.priceType = PriceTypeType(rawValue: pt.rawValue) }
        c.price = asn.price
        c.infoText = asn.infoText
        c.numberOfBoats = asn.attachedBoats ?? 0

        if let num = asn.serviceBrand {
            var sb = ServiceBrandAPI()
            sb.serviceBrandNum = num
            sb.serviceBrandAbrUTF8 = asn.serviceBrandAbrUTF8
            sb.serviceBrandNameUTF8 = asn.serviceBrandNameUTF8
            c.serviceBrand = sb
        }

        if let carriersIA5 = asn.carrierIA5 {
            c.carriers = carriersIA5
        } else if let carriers = asn.carrierNum {
            c.carriers = carriers.map { String($0) }
        }

        // V2: tariff is NON-OPTIONAL
        c.tariffs = [convertTariff(asn.tariff)]
        if let vats = asn.vatDetail {
            c.vatDetails = vats.map { convertVatDetail($0) }
        }
        if let ext = asn.extensionData { c.extensionData = convertExtension(ext) }

        return c
    }

    // MARK: - Customer Card

    static func convertCustomerCard(_ asn: CustomerCardDataV2, token: TokenTypeV2?) -> CustomerCardAPI {
        let c = CustomerCardAPI()
        c.token = convertToken(token)

        c.validFrom = dateFromDayOfYear(year: asn.validFromYear ?? 2016, day: asn.validFromDay ?? 0, time: nil)
        c.validUntil = dateFromDayOfYear(year: (asn.validFromYear ?? 2016) + (asn.validUntilYear ?? 0), day: asn.validUntilDay ?? 0, time: nil)

        c.cardIdNum = asn.cardIdNum
        c.cardIdIA5 = asn.cardIdIA5
        c.reference = asn.cardIdIA5 ?? (asn.cardIdNum.map { String($0) })
        c.cardType = asn.cardType
        c.cardTypeDescr = asn.cardTypeDescr
        if let cc = asn.classCode { c.classCode = TravelClassType(rawValue: cc.rawValue) }
        if let ext = asn.extensionData { c.extensionData = convertExtension(ext) }
        return c
    }

    // MARK: - Counter Mark

    static func convertCounterMark(_ asn: CountermarkDataV2, token: TokenTypeV2?, issuingDate: Date? = nil) -> CounterMarkAPI {
        let c = CounterMarkAPI()
        c.token = convertToken(token)

        c.validFrom = DateTimeUtils.getDate(issuingDate: issuingDate, dayOffset: asn.validFromDay ?? 0, time: asn.validFromTime)
        c.validUntil = DateTimeUtils.getDate(issuingDate: issuingDate, dayOffset: (asn.validFromDay ?? 0) + (asn.validUntilDay ?? 0), time: asn.validUntilTime ?? 1439)

        c.reference = asn.referenceIA5 ?? (asn.referenceNum.map { String($0) })
        c.productId = asn.productIdIA5 ?? (asn.productIdNum.map { String($0) })
        c.productOwner = asn.productOwnerIA5 ?? (asn.productOwnerNum.map { String($0) })
        if let ct = asn.stationCodeTable { c.stationCodeTable = CodeTableType(rawValue: ct.rawValue) }
        c.fromStation = asn.fromStationIA5 ?? (asn.fromStationNum.map { String($0) })
        c.toStation = asn.toStationIA5 ?? (asn.toStationNum.map { String($0) })
        c.fromStationName = asn.fromStationNameUTF8
        c.toStationName = asn.toStationNameUTF8
        c.validRegionDesc = asn.validRegionDesc
        if let cc = asn.classCode { c.classCode = TravelClassType(rawValue: cc.rawValue) }
        // V2: numberOfCountermark and totalOfCountermarks are non-optional Int
        c.numberOfCountermark = asn.numberOfCountermark
        c.totalOfCountermarks = asn.totalOfCountermarks
        // V2: groupName is non-optional String
        c.groupName = asn.groupName
        c.infoText = asn.infoText

        if let carriersIA5 = asn.carrierIA5 {
            c.carriers = carriersIA5
        } else if let carriers = asn.carrierNum {
            c.carriers = carriers.map { String($0) }
        }

        c.includedServiceBrands = asn.includedServiceBrands ?? []
        c.excludedServiceBrands = asn.excludedServiceBrands ?? []

        if let region = asn.validRegion {
            c.validRegionList = region.compactMap { convertRegionalValidity($0) }
        }
        if let ret = asn.returnDescription {
            c.returnDescription = convertReturnRouteDescription(ret)
        }
        if let ext = asn.extensionData { c.extensionData = convertExtension(ext) }
        return c
    }

    // MARK: - Parking Ground

    static func convertParkingGround(_ asn: ParkingGroundDataV2, token: TokenTypeV2?, issuingDate: Date? = nil) -> ParkingGroundAPI {
        let p = ParkingGroundAPI()
        p.token = convertToken(token)

        p.fromParkingDate = DateTimeUtils.getDate(issuingDate: issuingDate, dayOffset: asn.fromParkingDate ?? 0, time: nil)
        p.toParkingDate = DateTimeUtils.getDate(issuingDate: issuingDate, dayOffset: (asn.fromParkingDate ?? 0) + (asn.toParkingDate ?? 0), time: nil)

        p.reference = asn.referenceIA5 ?? (asn.referenceNum.map { String($0) })
        p.parkingGroundId = asn.parkingGroundId
        if let ct = asn.stationCodeTable { p.stationCodeTable = CodeTableType(rawValue: ct.rawValue) }
        p.stationNum = asn.stationNum
        p.stationIA5 = asn.stationIA5
        p.specialInformation = asn.specialInformation
        p.price = asn.price
        p.productOwner = asn.productOwnerIA5 ?? (asn.productOwnerNum.map { String($0) })
        if let vats = asn.vatDetail {
            p.vatDetails = vats.map { convertVatDetail($0) }
        }
        if let ext = asn.extensionData { p.extensionData = convertExtension(ext) }
        return p
    }

    // MARK: - FIP Ticket

    static func convertFIPTicket(_ asn: FIPTicketDataV2, token: TokenTypeV2?, issuingDate: Date? = nil) -> FIPTicketAPI {
        let f = FIPTicketAPI()
        f.token = convertToken(token)

        f.validFrom = DateTimeUtils.getDate(issuingDate: issuingDate, dayOffset: asn.validFromDay ?? 0, time: nil)
        f.validUntil = DateTimeUtils.getDate(issuingDate: issuingDate, dayOffset: (asn.validFromDay ?? 0) + (asn.validUntilDay ?? 0), time: nil)
        if let activatedDay = asn.activatedDay {
            f.activatedDays = activatedDay.compactMap { DateTimeUtils.getDate(issuingDate: f.validFrom, dayOffset: $0, time: nil) }
        }

        f.reference = asn.referenceIA5 ?? (asn.referenceNum.map { String($0) })
        f.productId = asn.productIdIA5 ?? (asn.productIdNum.map { String($0) })
        f.productOwner = asn.productOwnerIA5 ?? (asn.productOwnerNum.map { String($0) })
        if let cc = asn.classCode { f.classCode = TravelClassType(rawValue: cc.rawValue) }
        // V2: numberOfTravelDays is non-optional Int
        f.numberOfTravelDays = asn.numberOfTravelDays
        // V2: includesSupplements is non-optional Bool
        f.includesSupplements = asn.includesSupplements
        if let carriersIA5 = asn.carrierIA5 {
            f.carriers = carriersIA5
        } else if let carriers = asn.carrierNum {
            f.carriers = carriers.map { String($0) }
        }
        if let ext = asn.extensionData { f.extensionData = convertExtension(ext) }
        return f
    }

    // MARK: - Station Passage

    static func convertStationPassage(_ asn: StationPassageDataV2, token: TokenTypeV2?, issuingDate: Date? = nil) -> StationPassageAPI {
        let s = StationPassageAPI()
        s.token = convertToken(token)

        s.validFrom = DateTimeUtils.getDate(issuingDate: issuingDate, dayOffset: asn.validFromDay ?? 0, time: asn.validFromTime)
        s.validUntil = DateTimeUtils.getDate(issuingDate: issuingDate, dayOffset: (asn.validFromDay ?? 0) + (asn.validUntilDay ?? 0), time: asn.validUntilTime ?? 1440)

        s.reference = asn.referenceIA5 ?? (asn.referenceNum.map { String($0) })
        s.productId = asn.productIdIA5 ?? (asn.productIdNum.map { String($0) })
        s.productOwner = asn.productOwnerIA5 ?? (asn.productOwnerNum.map { String($0) })
        if let ct = asn.stationCodeTable { s.stationCodeTable = CodeTableType(rawValue: ct.rawValue) }
        s.stationNameUTF8 = asn.stationNameUTF8 ?? []
        s.stationNum = asn.stationNum ?? []
        s.stationIA5 = asn.stationIA5 ?? []
        s.numberOfDaysValid = asn.numberOfDaysValid ?? 0
        if let ext = asn.extensionData { s.extensionData = convertExtension(ext) }
        return s
    }

    // MARK: - Delay Confirmation

    static func convertDelayConfirmation(_ asn: DelayConfirmationV2, token: TokenTypeV2?) -> DelayConfirmationAPI {
        let d = DelayConfirmationAPI()
        d.token = convertToken(token)

        d.plannedArrivalDate = dateFromDayOfYear(year: asn.plannedArrivalYear ?? 0, day: asn.plannedArrivalDay ?? 0, time: asn.plannedArrivalTime)

        d.reference = asn.referenceIA5 ?? (asn.referenceNum.map { String($0) })
        d.train = asn.trainIA5 ?? (asn.trainNum.map { String($0) })
        d.delay = asn.delay
        if let ct = asn.stationCodeTable { d.stationCodeTable = CodeTableType(rawValue: ct.rawValue) }
        d.stationNum = asn.stationNum
        d.stationIA5 = asn.stationIA5
        if let ct = asn.confirmationType { d.confirmationType = ConfirmationTypeType(rawValue: ct.rawValue) }
        d.infoText = asn.infoText
        if let tickets = asn.affectedTickets {
            d.affectedTickets = tickets.map { convertTicketLink($0) }
        }
        if let ext = asn.extensionData { d.extensionData = convertExtension(ext) }
        return d
    }

    // MARK: - Voucher

    static func convertVoucher(_ asn: VoucherDataV2, token: TokenTypeV2?) -> VoucherAPI {
        let v = VoucherAPI()
        v.token = convertToken(token)

        v.validFrom = dateFromDayOfYear(year: asn.validFromYear ?? 0, day: asn.validFromDay ?? 0, time: nil)
        v.validUntil = dateFromDayOfYear(year: asn.validUntilYear ?? 0, day: asn.validUntilDay ?? 0, time: nil)

        v.reference = asn.referenceIA5 ?? (asn.referenceNum.map { String($0) })
        v.productId = asn.productIdIA5 ?? (asn.productIdNum.map { String($0) })
        v.productOwner = asn.productOwnerIA5 ?? (asn.productOwnerNum.map { String($0) })
        v.amount = asn.value ?? 0
        // V2: field is `type` (not `voucherType`)
        v.type = asn.type ?? 0
        v.infoText = asn.infoText
        if let ext = asn.extensionData { v.extensionData = convertExtension(ext) }
        return v
    }

    // MARK: - Document Extension

    static func convertDocumentExtension(_ asn: ExtensionDataV2) -> DocumentExtensionAPI {
        var d = DocumentExtensionAPI()
        d.extensionId = asn.extensionId
        d.extensionData = asn.extensionData
        return d
    }

    // MARK: - Supporting Type Conversions

    static func convertToken(_ asn: TokenTypeV2?) -> TokenAPI? {
        guard let asn = asn else { return nil }
        var t = TokenAPI()
        t.tokenProviderIA5 = asn.tokenProviderIA5
        t.tokenProviderNum = asn.tokenProviderNum
        t.tokenSpecification = asn.tokenSpecification
        t.token = asn.token
        return t
    }

    static func convertExtension(_ asn: ExtensionDataV2) -> TicketExtension {
        var ext = TicketExtension()
        ext.extensionId = asn.extensionId
        ext.extensionData = asn.extensionData
        return ext
    }

    static func convertGeoCoordinate(_ asn: GeoCoordinateTypeV2) -> GeoCoordinateAPI {
        var g = GeoCoordinateAPI()
        g.longitude = Double(asn.longitude)
        g.latitude = Double(asn.latitude)
        if let sys = asn.coordinateSystem { g.coordinateSystem = GeoCoordinateSystemType(rawValue: sys.rawValue) ?? .wgs84 }
        if let unit = asn.geoUnit { g.accuracy = GeoUnitType(rawValue: unit.rawValue) ?? .milliDegree }
        if let h = asn.hemisphereLongitude { g.hemisphereLongitude = HemisphereLongitudeType(rawValue: h.rawValue) ?? .east }
        if let h = asn.hemisphereLatitude { g.hemisphereLatitude = HemisphereLatitudeType(rawValue: h.rawValue) ?? .north }
        return g
    }

    static func convertCardReference(_ asn: CardReferenceTypeV2) -> CardReferenceAPI {
        var c = CardReferenceAPI()
        c.cardIssuerNum = asn.cardIssuerNum
        c.cardIssuerIA5 = asn.cardIssuerIA5
        c.cardIdNum = asn.cardIdNum
        c.cardIdIA5 = asn.cardIdIA5
        c.cardName = asn.cardName
        c.cardType = asn.cardType
        c.leadingCardIdNum = asn.leadingCardIdNum
        c.leadingCardIdIA5 = asn.leadingCardIdIA5
        c.trailingCardIdNum = asn.trailingCardIdNum
        c.trailingCardIdIA5 = asn.trailingCardIdIA5
        return c
    }

    static func convertTicketLink(_ asn: TicketLinkTypeV2) -> TicketLinkAPI {
        var t = TicketLinkAPI()
        t.referenceIA5 = asn.referenceIA5
        t.referenceNum = asn.referenceNum
        t.issuerName = asn.issuerName
        t.issuerPNR = asn.issuerPNR
        t.productOwnerNum = asn.productOwnerNum
        t.productOwnerIA5 = asn.productOwnerIA5
        if let tt = asn.ticketType { t.ticketType = TicketType(rawValue: tt.rawValue) }
        if let lm = asn.linkMode { t.linkMode = LinkMode(rawValue: lm.rawValue) }
        return t
    }

    static func convertPlaces(_ asn: PlacesTypeV2) -> PlacesAPI {
        var p = PlacesAPI()
        p.coach = asn.coach
        p.placeString = asn.placeString
        p.placeNum = asn.placeNum ?? []
        p.placeDescription = asn.placeDescription
        return p
    }

    static func convertCompartmentDetails(_ asn: CompartmentDetailsTypeV2) -> CompartmentDetailsAPI {
        var c = CompartmentDetailsAPI()
        c.coachType = asn.coachType
        c.compartmentType = asn.compartmentType
        c.specialAllocation = asn.specialAllocation
        c.coachTypeDescr = asn.coachTypeDescr
        c.compartmentTypeDescr = asn.compartmentTypeDescr
        c.specialAllocationDescr = asn.specialAllocationDescr
        if let pos = asn.position { c.position = CompartmentPositionType(rawValue: pos.rawValue) }
        return c
    }

    static func convertBerth(_ asn: BerthDetailDataV2) -> BerthAPI {
        var b = BerthAPI()
        // V2: berthType is non-optional BerthTypeTypeV2
        b.berthType = BerthTypeType(rawValue: asn.berthType.rawValue)
        // V2: numberOfBerths is non-optional Int
        b.numberOfBerths = asn.numberOfBerths
        if let g = asn.gender { b.gender = CompartmentGenderType(rawValue: g.rawValue) }
        return b
    }

    static func convertTariff(_ asn: TariffTypeV2) -> TariffAPI {
        var t = TariffAPI()
        t.numberOfPassengers = asn.numberOfPassengers ?? 1
        if let pt = asn.passengerType { t.passengerType = PassengerType(rawValue: pt.rawValue) }
        t.ageBelow = asn.ageBelow
        t.ageAbove = asn.ageAbove
        t.tariffIdNum = asn.tariffIdNum
        t.tariffIdIA5 = asn.tariffIdIA5
        t.tariffDesc = asn.tariffDesc
        if let cards = asn.reductionCard {
            t.reductionCard = cards.map { convertCardReference($0) }
        }
        if let series = asn.seriesDataDetails {
            t.seriesDataDetails = convertSeriesDetail(series)
        }
        return t
    }

    static func convertSeriesDetail(_ asn: SeriesDetailTypeV2) -> SeriesDetailAPI {
        var s = SeriesDetailAPI()
        s.supplyingCarrier = asn.supplyingCarrier
        s.offerIdentification = asn.offerIdentification
        s.series = asn.series
        return s
    }

    static func convertVatDetail(_ asn: VatDetailTypeV2) -> VatDetailAPI {
        var v = VatDetailAPI()
        v.country = asn.country
        v.percentage = asn.percentage
        v.amount = asn.amount
        v.vatId = asn.vatId
        return v
    }

    static func convertLuggageRestriction(_ asn: LuggageRestrictionTypeV2) -> LuggageRestrictionAPI {
        var l = LuggageRestrictionAPI()
        l.maxHandLuggagePieces = asn.maxHandLuggagePieces
        l.maxNonHandLuggagePieces = asn.maxNonHandLuggagePieces
        if let registered = asn.registeredLuggage {
            l.registeredLuggage = registered.map { rl in
                var r = RegisteredLuggageAPI()
                r.maxWeight = rl.maxWeight
                r.maxSize = rl.maxSize
                r.registrationId = rl.registrationId
                return r
            }
        }
        return l
    }

    static func convertRegionalValidity(_ asn: RegionalValidityTypeV2) -> RegionalValidityAPI? {
        guard let validity = asn.validity else { return nil }
        switch validity {
        case .trainLink(let trainLink):
            return .trainLink(convertTrainLink(trainLink))
        case .viaStations(let via):
            return .viaStations(convertViaStation(via))
        case .zone(let zone):
            return .zone(convertZone(zone))
        case .line(let line):
            return .line(convertLine(line))
        case .polygone(let poly):
            return .polygone(convertPolygone(poly))
        }
    }

    static func convertTrainLink(_ asn: TrainLinkTypeV2) -> TrainLinkAPI {
        var t = TrainLinkAPI()
        t.trainNum = asn.trainNum
        t.trainIA5 = asn.trainIA5
        t.departureTime = asn.departureTime
        t.fromStation = asn.fromStationIA5 ?? (asn.fromStationNum.map { String($0) })
        t.toStation = asn.toStationIA5 ?? (asn.toStationNum.map { String($0) })
        t.fromStationName = asn.fromStationNameUTF8
        t.toStationName = asn.toStationNameUTF8
        return t
    }

    static func convertViaStation(_ asn: ViaStationTypeV2) -> ViaStationAPI {
        var v = ViaStationAPI()
        if let ct = asn.stationCodeTable { v.stationCodeTable = CodeTableType(rawValue: ct.rawValue) }
        v.stationNum = asn.stationNum
        v.stationIA5 = asn.stationIA5
        v.carriersNum = asn.carriersNum ?? []
        v.carriersIA5 = asn.carriersIA5 ?? []
        v.border = asn.border
        v.seriesId = asn.seriesId
        v.routeId = asn.routeId
        if let route = asn.route {
            v.route = route.map { convertViaStation($0) }
        }
        if let altRoutes = asn.alternativeRoutes {
            // V2 alternativeRoutes is [ViaStationTypeV2] (each is an alternative route)
            // API alternativeRoutes is [[ViaStationAPI]] (each is a list of via stations)
            v.alternativeRoutes = altRoutes.map { [convertViaStation($0)] }
        }
        return v
    }

    static func convertZone(_ asn: ZoneTypeV2) -> ZoneAPI {
        var z = ZoneAPI()
        if let ct = asn.stationCodeTable { z.stationCodeTable = CodeTableType(rawValue: ct.rawValue) }
        z.carrierNum = asn.carrierNum
        z.carrierIA5 = asn.carrierIA5
        z.zoneId = asn.zoneId ?? []
        z.city = asn.city
        z.binaryZoneId = asn.binaryZoneId
        z.nutsCode = asn.nutsCode
        return z
    }

    static func convertLine(_ asn: LineTypeV2) -> LineAPI {
        var l = LineAPI()
        if let ct = asn.stationCodeTable { l.stationCodeTable = CodeTableType(rawValue: ct.rawValue) }
        l.carrierNum = asn.carrierNum
        l.carrierIA5 = asn.carrierIA5
        l.lineId = asn.lineId ?? []
        return l
    }

    static func convertPolygone(_ asn: PolygoneTypeV2) -> PolygoneAPI {
        var p = PolygoneAPI()
        p.firstEdge = convertGeoCoordinate(asn.firstEdge)
        p.edges = asn.edges.map { edge in
            var d = DeltaCoordinateAPI()
            d.longitude = edge.longitude
            d.latitude = edge.latitude
            return d
        }
        return p
    }

    static func convertReturnRouteDescription(_ asn: ReturnRouteDescriptionTypeV2) -> ReturnRouteDescriptionAPI {
        var r = ReturnRouteDescriptionAPI()
        r.fromStation = asn.fromStationIA5 ?? (asn.fromStationNum.map { String($0) })
        r.toStation = asn.toStationIA5 ?? (asn.toStationNum.map { String($0) })
        r.fromStationName = asn.fromStationNameUTF8
        r.toStationName = asn.toStationNameUTF8
        r.validRegionDesc = asn.validReturnRegionDesc
        if let region = asn.validReturnRegion {
            r.validRegionList = region.compactMap { convertRegionalValidity($0) }
        }
        return r
    }

    static func convertIncludedOpenTicket(_ asn: IncludedOpenTicketTypeV2) -> IncludedOpenTicketAPI {
        var i = IncludedOpenTicketAPI()
        i.productOwnerNum = asn.productOwnerNum
        i.productOwnerIA5 = asn.productOwnerIA5
        i.productIdNum = asn.productIdNum
        i.productIdIA5 = asn.productIdIA5
        // V2: uses `externalIssuerId` and `issuerAuthorizationId`
        i.externalIssuerId = asn.externalIssuerId
        i.authorizationCode = asn.issuerAuthorizationId
        if let ct = asn.stationCodeTable { i.stationCodeTable = CodeTableType(rawValue: ct.rawValue) }
        if let cc = asn.classCode { i.classCode = TravelClassType(rawValue: cc.rawValue) }
        i.serviceLevel = asn.serviceLevel
        i.infoText = asn.infoText

        if let carriersIA5 = asn.carrierIA5 {
            i.includedCarriers = carriersIA5
        } else if let carriers = asn.carrierNum {
            i.includedCarriers = carriers.map { String($0) }
        }

        i.includedServiceBrands = asn.includedServiceBrands ?? []
        i.excludedServiceBrands = asn.excludedServiceBrands ?? []
        i.includedTransportTypes = asn.includedTransportTypes ?? []
        i.excludedTransportTypes = asn.excludedTransportTypes ?? []

        if let region = asn.validRegion {
            i.validRegionList = region.compactMap { convertRegionalValidity($0) }
        }
        if let tariffs = asn.tariffs {
            i.tariffs = tariffs.map { convertTariff($0) }
        }
        if let ext = asn.extensionData { i.extensionData = convertExtension(ext) }
        return i
    }

    static func convertValidityDetails(_ asn: ValidityPeriodDetailTypeV2) -> ValidityDetailsAPI {
        var v = ValidityDetailsAPI()
        if let periods = asn.validityPeriod {
            v.validityPeriods = periods.map { period in
                let vp = ValidityPeriodAPI()
                // These are day/time offsets, not absolute dates - store as-is for now
                return vp
            }
        }
        if let ranges = asn.excludedTimeRange {
            v.excludedTimeRanges = ranges.map { range in
                var tr = TimeRangeAPI()
                tr.fromTime = range.fromTime
                tr.untilTime = range.untilTime
                return tr
            }
        }
        return v
    }

    // MARK: - Date Utilities

    static func dateFromDayOfYear(year: Int, day: Int, time: Int? = nil) -> Date? {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        guard let jan1 = cal.date(from: DateComponents(timeZone: cal.timeZone, year: year, month: 1, day: 1)) else {
            return nil
        }
        guard var result = cal.date(byAdding: .day, value: day - 1, to: jan1) else {
            return nil
        }

        if let time = time {
            let startOfDay = cal.startOfDay(for: result)
            result = cal.date(byAdding: .minute, value: time, to: startOfDay) ?? result
        }

        return result
    }
}
