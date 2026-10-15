import XCTest
@testable import UICBarcodeKit

/// All Elements V1 Tests
/// Translated from Java: AllElementsTestTicketV1.java
/// Decodes V1 UPER data via FCBVersionDecoder (converts to V3 UicRailTicketData)
final class AllElementsTestsV1: XCTestCase {

    private var ticket: UicRailTicketData!

    override func setUpWithError() throws {
        let data = TestTicketsV1.allElementsData
        ticket = try FCBVersionDecoder.decode(data: data, version: 1)
    }

    // MARK: - Top-Level Structure

    func testTopLevelStructure() {
        XCTAssertNotNil(ticket.issuingDetail)
        XCTAssertNotNil(ticket.travelerDetail)
        XCTAssertNotNil(ticket.transportDocument)
        XCTAssertNotNil(ticket.controlDetail)
        XCTAssertNotNil(ticket.extensionData)
        XCTAssertEqual(ticket.transportDocument?.count, 12)
        XCTAssertEqual(ticket.extensionData?.count, 2)
    }

    // MARK: - IssuingData

    func testIssuingData() {
        let id = ticket.issuingDetail
        XCTAssertEqual(id.securityProviderNum, 1)
        XCTAssertEqual(id.securityProviderIA5, "1")
        XCTAssertEqual(id.issuerNum, 15000)
        XCTAssertEqual(id.issuerIA5, "1")
        XCTAssertEqual(id.issuingYear, 2018)
        XCTAssertEqual(id.issuingDay, 1)
        // V1 issuingTime is optional; converted as-is (600)
        XCTAssertEqual(id.issuingTime, 600)
        XCTAssertEqual(id.issuerName, "name")
        XCTAssertEqual(id.specimen, true)
        XCTAssertEqual(id.securePaperTicket, false)
        XCTAssertEqual(id.activated, true)
        XCTAssertEqual(id.currency, "SRF")
        XCTAssertEqual(id.currencyFract, 3)
        XCTAssertEqual(id.issuerPNR, "issuerTestPNR")
        XCTAssertEqual(id.issuedOnTrainNum, 123)
        XCTAssertEqual(id.issuedOnTrainIA5, "123")
        XCTAssertEqual(id.issuedOnLine, 12)
    }

    // MARK: - TravelerData

    func testTravelerData() {
        let td = ticket.travelerDetail
        XCTAssertNotNil(td)
        XCTAssertEqual(td?.groupName, "myGroup")
        XCTAssertEqual(td?.preferedLanguage, "EN")

        let t = td?.traveler?.first
        XCTAssertNotNil(t)
        XCTAssertEqual(t?.firstName, "John")
        XCTAssertEqual(t?.secondName, "Little")
        XCTAssertEqual(t?.lastName, "Dow")
        XCTAssertEqual(t?.idCard, "12345")
        XCTAssertEqual(t?.passportId, "JDTS")
        XCTAssertEqual(t?.title, "PhD")
        XCTAssertEqual(t?.gender, .male)
        XCTAssertEqual(t?.customerIdIA5, "DZE5gT")
        XCTAssertEqual(t?.customerIdNum, 12345)
        XCTAssertEqual(t?.yearOfBirth, 1901)
        XCTAssertEqual(t?.dayOfBirth, 31)
        XCTAssertEqual(t?.ticketHolder, true)
        XCTAssertEqual(t?.passengerType, .senior)
        XCTAssertEqual(t?.passengerWithReducedMobility, false)
        XCTAssertEqual(t?.countryOfResidence, 101)
        XCTAssertEqual(t?.countryOfPassport, 102)
        XCTAssertEqual(t?.countryOfIdCard, 103)

        // CustomerStatusType
        XCTAssertEqual(t?.status?.count, 1)
        XCTAssertEqual(t?.status?.first?.customerStatus, 1)
        XCTAssertEqual(t?.status?.first?.customerStatusDescr, "senior")
    }

    // MARK: - Reservation (doc 0)

    func testReservation() throws {
        let doc = try XCTUnwrap(ticket.transportDocument?[0])
        guard case .reservation(let r) = doc.ticket.ticketType else {
            XCTFail("Expected reservation"); return
        }

        XCTAssertEqual(r.trainNum, 12345)
        XCTAssertEqual(r.trainIA5, "12345")
        XCTAssertEqual(r.departureDate, 2)
        XCTAssertEqual(r.referenceIA5, "810123456789")
        XCTAssertEqual(r.referenceNum, 80123456789)
        XCTAssertEqual(r.productOwnerNum, 23456)
        XCTAssertEqual(r.productOwnerIA5, "23456")
        XCTAssertEqual(r.productIdNum, 15535)
        XCTAssertEqual(r.productIdIA5, "23456")
        XCTAssertEqual(r.serviceBrand, 12)
        XCTAssertEqual(r.serviceBrandAbrUTF8, "TGV")
        XCTAssertEqual(r.serviceBrandNameUTF8, "Lyria")
        XCTAssertEqual(r.service, .couchette)
        XCTAssertEqual(r.stationCodeTable, .stationUIC)
        XCTAssertEqual(r.fromStationNum, 8100001)
        XCTAssertEqual(r.fromStationIA5, "8100001")
        XCTAssertEqual(r.toStationNum, 8000002)
        XCTAssertEqual(r.toStationIA5, "8100002")
        XCTAssertEqual(r.fromStationNameUTF8, "A-STATION")
        XCTAssertEqual(r.toStationNameUTF8, "B-STATION")
        XCTAssertEqual(r.departureTime, 1439)
        XCTAssertEqual(r.departureUTCOffset, -60)
        XCTAssertEqual(r.arrivalDate, 20)
        XCTAssertEqual(r.arrivalTime, 0)
        XCTAssertEqual(r.arrivalUTCOffset, 10)
        XCTAssertEqual(r.carrierNum, [1080, 1181])
        XCTAssertEqual(r.carrierIA5, ["1080", "1181"])
        XCTAssertEqual(r.classCode, .first)
        XCTAssertEqual(r.serviceLevel, "A")
        XCTAssertEqual(r.price, 12345)
        XCTAssertEqual(r.priceType, .travelPrice)
        XCTAssertEqual(r.typeOfSupplement, 9)
        XCTAssertEqual(r.numberOfSupplements, 2)
        XCTAssertEqual(r.numberOfOverbooked, 200)
        XCTAssertEqual(r.infoText, "reservation")

        // Places
        XCTAssertEqual(r.places?.coach, "31A")
        XCTAssertEqual(r.places?.placeString, "31-47")
        XCTAssertEqual(r.places?.placeDescription, "Window")
        XCTAssertEqual(r.places?.placeNum, [31, 32])
        XCTAssertEqual(r.places?.placeIA5, ["31A", "31B"])

        // Berth
        XCTAssertEqual(r.berth?.count, 1)
        XCTAssertEqual(r.berth?.first?.berthType, .single)
        XCTAssertEqual(r.berth?.first?.gender, .female)
        XCTAssertEqual(r.berth?.first?.numberOfBerths, 999)

        // Tariff
        XCTAssertEqual(r.tariff?.count, 1)
        XCTAssertEqual(r.tariff?.first?.numberOfPassengers, 1)
        XCTAssertEqual(r.tariff?.first?.passengerType, .senior)
        XCTAssertEqual(r.tariff?.first?.tariffIdNum, 72)
        XCTAssertEqual(r.tariff?.first?.tariffDesc, "Leasure Fare")

        // VAT
        XCTAssertEqual(r.vatDetails?.count, 1)
        XCTAssertEqual(r.vatDetails?.first?.country, 80)
        XCTAssertEqual(r.vatDetails?.first?.percentage, 70)
        XCTAssertEqual(r.vatDetails?.first?.amount, 10)
        XCTAssertEqual(r.vatDetails?.first?.vatId, "IUDGTE")

        // Luggage
        XCTAssertEqual(r.luggage?.maxHandLuggagePieces, 2)
        XCTAssertEqual(r.luggage?.maxNonHandLuggagePieces, 1)
        XCTAssertEqual(r.luggage?.registeredLuggage?.count, 2)
    }

    // MARK: - CarCarriageReservation (doc 1)

    func testCarCarriageReservation() throws {
        let doc = try XCTUnwrap(ticket.transportDocument?[1])

        // Token
        XCTAssertNotNil(doc.token)
        XCTAssertEqual(doc.token?.tokenProviderIA5, "VDV")
        XCTAssertEqual(doc.token?.tokenProviderNum, 123)

        guard case .carCarriageReservation(let r) = doc.ticket.ticketType else {
            XCTFail("Expected carCarriageReservation"); return
        }
        XCTAssertEqual(r.trainNum, 123)
        XCTAssertEqual(r.trainIA5, "123")
        XCTAssertEqual(r.productOwnerNum, 23456)
        XCTAssertEqual(r.productIdNum, 15535)
        XCTAssertEqual(r.serviceBrand, 100)
        XCTAssertEqual(r.serviceBrandAbrUTF8, "AZ")
        XCTAssertEqual(r.serviceBrandNameUTF8, "special train")
        XCTAssertEqual(r.beginLoadingDate, 10)
        XCTAssertEqual(r.beginLoadingTime, 0)
        XCTAssertEqual(r.endLoadingTime, 500)
        XCTAssertEqual(r.loadingUTCOffset, 30)
        XCTAssertEqual(r.fromStationNum, 8100001)
        XCTAssertEqual(r.toStationNum, 8000002)
        XCTAssertEqual(r.coach, "21")
        XCTAssertEqual(r.place, "41")
        XCTAssertEqual(r.numberPlate, "AD-DE-123")
        XCTAssertEqual(r.trailerPlate, "DX-AB-123")
        XCTAssertEqual(r.carCategory, 3)
        XCTAssertEqual(r.boatCategory, 5)
        XCTAssertEqual(r.textileRoof, false)
        XCTAssertEqual(r.roofRackType, .bicycleRack)
        XCTAssertEqual(r.roofRackHeight, 20)
        XCTAssertEqual(r.loadingDeck, .upper)
        XCTAssertEqual(r.price, 12345)
        XCTAssertEqual(r.infoText, "car carriage")
    }

    // MARK: - OpenTicket (doc 2)

    func testOpenTicket() throws {
        let doc = try XCTUnwrap(ticket.transportDocument?[2])
        guard case .openTicket(let o) = doc.ticket.ticketType else {
            XCTFail("Expected openTicket"); return
        }

        XCTAssertEqual(o.referenceIA5, "810123456789")
        XCTAssertEqual(o.productOwnerNum, 23456)
        XCTAssertEqual(o.productIdNum, 15535)
        XCTAssertEqual(o.returnIncluded, false)
        XCTAssertEqual(o.stationCodeTable, .stationERA)
        XCTAssertEqual(o.fromStationNum, 8100001)
        XCTAssertEqual(o.toStationNum, 8000002)
        XCTAssertEqual(o.fromStationNameUTF8, "A-STATION")
        XCTAssertEqual(o.toStationNameUTF8, "B-STATION")
        XCTAssertEqual(o.validRegionDesc, "From A to B via C")
        XCTAssertEqual(o.validFromDay, 700)
        XCTAssertEqual(o.validFromTime, 0)
        XCTAssertEqual(o.validUntilDay, 370)
        XCTAssertEqual(o.validUntilTime, 1439)
        XCTAssertEqual(o.classCode, .first)
        XCTAssertEqual(o.serviceLevel, "A")
        XCTAssertEqual(o.price, 12345)
        XCTAssertEqual(o.infoText, "openTicketInfo")

        // Valid regions: viaStations, zones, lines, trainLink, polygone
        XCTAssertEqual(o.validRegion?.count, 5)

        // Included add-ons
        XCTAssertEqual(o.includedAddOns?.count, 1)
        XCTAssertEqual(o.includedAddOns?.first?.productOwnerNum, 23456)
        XCTAssertEqual(o.includedAddOns?.first?.classCode, .second)
        XCTAssertEqual(o.includedAddOns?.first?.infoText, "included ticket")

        // Luggage
        XCTAssertEqual(o.luggage?.maxHandLuggagePieces, 2)
        XCTAssertEqual(o.luggage?.maxNonHandLuggagePieces, 1)

        // Activated days
        XCTAssertEqual(o.activatedDay, [1, 2])

        // Carriers
        XCTAssertEqual(o.carrierNum, [1080, 1181])

        // VAT
        XCTAssertEqual(o.vatDetails?.count, 1)
        XCTAssertEqual(o.vatDetails?.first?.country, 80)
        XCTAssertEqual(o.vatDetails?.first?.percentage, 70)

        // Tariffs
        XCTAssertEqual(o.tariffs?.count, 1)
        XCTAssertEqual(o.tariffs?.first?.tariffIdNum, 72)
        XCTAssertEqual(o.tariffs?.first?.tariffDesc, "Large Car Full Fare")
    }

    // MARK: - Pass (doc 3)

    func testPass() throws {
        let doc = try XCTUnwrap(ticket.transportDocument?[3])
        guard case .pass(let p) = doc.ticket.ticketType else {
            XCTFail("Expected pass"); return
        }

        XCTAssertEqual(p.referenceIA5, "810123456789")
        XCTAssertEqual(p.productOwnerNum, 23456)
        XCTAssertEqual(p.productIdNum, 15535)
        XCTAssertEqual(p.passType, 2)
        XCTAssertEqual(p.passDescription, "Eurail FlexPass")
        XCTAssertEqual(p.classCode, .first)
        XCTAssertEqual(p.validFromDay, 0)
        XCTAssertEqual(p.validFromTime, 1000)
        XCTAssertEqual(p.validUntilDay, 1)
        XCTAssertEqual(p.validUntilTime, 1000)
        XCTAssertEqual(p.numberOfValidityDays, 5)
        XCTAssertEqual(p.numberOfPossibleTrips, 3)
        XCTAssertEqual(p.numberOfDaysOfTravel, 10)
        XCTAssertEqual(p.activatedDay, [200, 201])
        XCTAssertEqual(p.countries, [10, 20])
        XCTAssertEqual(p.price, 10000)
        XCTAssertEqual(p.infoText, "pass info")

        // Carriers
        XCTAssertEqual(p.includedCarrierNum, [1080, 1181])
        XCTAssertEqual(p.excludedCarrierNum, [1080, 1181])

        // Service brands
        XCTAssertEqual(p.includedServiceBrands, [108, 118])
        XCTAssertEqual(p.excludedServiceBrands, [108, 118])

        // Valid region (zone)
        XCTAssertEqual(p.validRegion?.count, 1)

        // Tariff
        XCTAssertEqual(p.tariffs?.count, 1)
        XCTAssertEqual(p.tariffs?.first?.tariffDesc, "Large Car Full Fare")

        // VAT
        XCTAssertEqual(p.vatDetails?.count, 1)
        XCTAssertEqual(p.vatDetails?.first?.vatId, "IUDGTE")

        // Validity period details
        XCTAssertNotNil(p.validityPeriodDetails)
        XCTAssertEqual(p.validityPeriodDetails?.validityPeriod?.count, 1)
        XCTAssertEqual(p.validityPeriodDetails?.excludedTimeRange?.count, 1)
    }

    // MARK: - Voucher (doc 4)

    func testVoucher() throws {
        let doc = try XCTUnwrap(ticket.transportDocument?[4])
        guard case .voucher(let v) = doc.ticket.ticketType else {
            XCTFail("Expected voucher"); return
        }

        XCTAssertEqual(v.referenceIA5, "810123456789")
        XCTAssertEqual(v.productOwnerNum, 23456)
        XCTAssertEqual(v.productOwnerIA5, "COFFEEMACHINE")
        XCTAssertEqual(v.productIdNum, 15535)
        XCTAssertEqual(v.validFromYear, 2022)
        XCTAssertEqual(v.validFromDay, 1)
        XCTAssertEqual(v.validUntilYear, 2022)
        XCTAssertEqual(v.validUntilDay, 1)
        XCTAssertEqual(v.value, 500)
        XCTAssertEqual(v.voucherType, 123)
        XCTAssertEqual(v.infoText, "coffee voucher")
    }

    // MARK: - CustomerCard (doc 5)

    func testCustomerCard() throws {
        let doc = try XCTUnwrap(ticket.transportDocument?[5])
        guard case .customerCard(let c) = doc.ticket.ticketType else {
            XCTFail("Expected customerCard"); return
        }

        XCTAssertEqual(c.cardIdIA5, "2345")
        XCTAssertEqual(c.cardIdNum, 123456)
        XCTAssertEqual(c.validFromYear, 2269)
        XCTAssertEqual(c.validFromDay, 2)
        XCTAssertEqual(c.validUntilYear, 1)
        XCTAssertEqual(c.validUntilDay, 5)
        XCTAssertEqual(c.classCode, .second)
        XCTAssertEqual(c.cardType, 15)
        XCTAssertEqual(c.cardTypeDescr, "RAILPLUS")
        XCTAssertEqual(c.customerStatus, 1)
        XCTAssertEqual(c.customerStatusDescr, "gold")
        XCTAssertEqual(c.includedServices, [1, 2])

        // Customer traveler
        XCTAssertNotNil(c.customer)
        XCTAssertEqual(c.customer?.customerIdIA5, "1234")
        XCTAssertEqual(c.customer?.ticketHolder, false)
        XCTAssertEqual(c.customer?.passengerType, .senior)
    }

    // MARK: - Countermark (doc 6)

    func testCountermark() throws {
        let doc = try XCTUnwrap(ticket.transportDocument?[6])
        guard case .countermark(let cm) = doc.ticket.ticketType else {
            XCTFail("Expected countermark"); return
        }

        XCTAssertEqual(cm.referenceIA5, "810123456789")
        XCTAssertEqual(cm.productOwnerNum, 23456)
        XCTAssertEqual(cm.productIdNum, 15535)
        XCTAssertEqual(cm.numberOfCountermark, 12)
        XCTAssertEqual(cm.totalOfCountermarks, 24)
        XCTAssertEqual(cm.groupName, "groupName")
        XCTAssertEqual(cm.returnIncluded, false)
        XCTAssertEqual(cm.stationCodeTable, .stationERA)
        XCTAssertEqual(cm.fromStationNum, 8100001)
        XCTAssertEqual(cm.toStationNum, 8000002)
        XCTAssertEqual(cm.validFromDay, 700)
        XCTAssertEqual(cm.validUntilDay, 370)
        XCTAssertEqual(cm.classCode, .first)
        XCTAssertEqual(cm.infoText, "counterMark")

        // Valid region
        XCTAssertEqual(cm.validRegion?.count, 1)

        // Carriers
        XCTAssertEqual(cm.carrierNum, [1080, 1181])
    }

    // MARK: - Parking (doc 7)

    func testParking() throws {
        let doc = try XCTUnwrap(ticket.transportDocument?[7])
        guard case .parkingGround(let p) = doc.ticket.ticketType else {
            XCTFail("Expected parkingGround"); return
        }

        XCTAssertEqual(p.referenceIA5, "810123456789")
        XCTAssertEqual(p.productOwnerNum, 23456)
        XCTAssertEqual(p.productIdNum, 15535)
        XCTAssertEqual(p.parkingGroundId, "IA5")
        XCTAssertEqual(p.fromParkingDate, 370)
        XCTAssertEqual(p.toParkingDate, 370)
        XCTAssertEqual(p.accessCode, "4ga")
        XCTAssertEqual(p.location, "Parking Frankfurt Main West")
        XCTAssertEqual(p.stationNum, 8000001)
        XCTAssertEqual(p.specialInformation, "outdoor parking")
        XCTAssertEqual(p.entryTrack, "left")
        XCTAssertEqual(p.numberPlate, "AA-DE-12345")
        XCTAssertEqual(p.price, 500)
    }

    // MARK: - FIP (doc 8)

    func testFIP() throws {
        let doc = try XCTUnwrap(ticket.transportDocument?[8])
        guard case .fipTicket(let f) = doc.ticket.ticketType else {
            XCTFail("Expected fipTicket"); return
        }

        XCTAssertEqual(f.referenceIA5, "810123456789")
        XCTAssertEqual(f.productOwnerNum, 23456)
        XCTAssertEqual(f.productIdNum, 15535)
        XCTAssertEqual(f.validFromDay, 2)
        XCTAssertEqual(f.validUntilDay, 5)
        XCTAssertEqual(f.activatedDay, [1, 13, 14, 15])
        XCTAssertEqual(f.carrierNum, [1080, 1181])
        XCTAssertEqual(f.numberOfTravelDays, 8)
        XCTAssertEqual(f.includesSupplements, true)
        XCTAssertEqual(f.classCode, .first)
    }

    // MARK: - StationPassage (doc 9)

    func testStationPassage() throws {
        let doc = try XCTUnwrap(ticket.transportDocument?[9])
        guard case .stationPassage(let s) = doc.ticket.ticketType else {
            XCTFail("Expected stationPassage"); return
        }

        XCTAssertEqual(s.referenceIA5, "810123456789")
        XCTAssertEqual(s.productOwnerNum, 23456)
        XCTAssertEqual(s.productIdNum, 15535)
        XCTAssertEqual(s.productName, "passage")
        XCTAssertEqual(s.stationCodeTable, .stationUIC)
        XCTAssertEqual(s.stationNum, [8200001])
        XCTAssertEqual(s.stationIA5, ["AMS"])
        XCTAssertEqual(s.stationNameUTF8, ["Amsterdam"])
        XCTAssertEqual(s.validFromDay, 5)
        XCTAssertEqual(s.validFromTime, 0)
        XCTAssertEqual(s.validUntilDay, 5)
        XCTAssertEqual(s.validUntilTime, 1000)
        XCTAssertEqual(s.numberOfDaysValid, 5)
    }

    // MARK: - Extension (doc 10)

    func testExtensionDocument() throws {
        let doc = try XCTUnwrap(ticket.transportDocument?[10])
        guard case .ticketExtension(let e) = doc.ticket.ticketType else {
            XCTFail("Expected ticketExtension"); return
        }

        XCTAssertEqual(e.extensionId, "1")
        XCTAssertEqual(e.extensionData, Data([0x82, 0xDA]))
    }

    // MARK: - DelayConfirmation (doc 11)

    func testDelayConfirmation() throws {
        let doc = try XCTUnwrap(ticket.transportDocument?[11])
        guard case .delayConfirmation(let dc) = doc.ticket.ticketType else {
            XCTFail("Expected delayConfirmation"); return
        }

        XCTAssertEqual(dc.trainNum, 100)
        XCTAssertEqual(dc.trainIA5, "100")
        // V1 fields mapped: departureYear/Day/Time → plannedArrivalYear/Day/Time
        XCTAssertEqual(dc.plannedArrivalYear, 2022)
        XCTAssertEqual(dc.plannedArrivalDay, 12)
        XCTAssertEqual(dc.plannedArrivalTime, 1000)
        XCTAssertEqual(dc.departureUTCOffset, 30)
        XCTAssertEqual(dc.referenceIA5, "ABDJ12345")
        XCTAssertEqual(dc.referenceNum, 12345)
        XCTAssertEqual(dc.stationCodeTable, .stationUIC)
        XCTAssertEqual(dc.stationNum, 8000001)
        XCTAssertEqual(dc.stationIA5, "DJE")
        XCTAssertEqual(dc.delay, 31)
        XCTAssertEqual(dc.trainCancelled, false)
        XCTAssertEqual(dc.confirmationType, .travelerDelayConfirmation)
        XCTAssertEqual(dc.infoText, "delay confirmation")

        // Affected tickets
        XCTAssertEqual(dc.affectedTickets?.count, 1)
        XCTAssertEqual(dc.affectedTickets?.first?.referenceIA5, "KDJET")
        XCTAssertEqual(dc.affectedTickets?.first?.issuerName, "XYZ")
    }

    // MARK: - ControlData

    func testControlData() throws {
        let cd = try XCTUnwrap(ticket.controlDetail)
        XCTAssertEqual(cd.infoText, "control")
        XCTAssertEqual(cd.ageCheckRequired, false)
        XCTAssertEqual(cd.identificationByIdCard, false)
        XCTAssertEqual(cd.onlineValidationRequired, false)
        XCTAssertEqual(cd.identificationItem, 12)
        XCTAssertEqual(cd.randomDetailedValidationRequired, 50)

        // Card references
        XCTAssertEqual(cd.identificationByCardReference?.count, 1)
        XCTAssertEqual(cd.identificationByCardReference?.first?.cardName, "testcard")
        XCTAssertEqual(cd.identificationByCardReference?.first?.cardType, 123)

        // Included tickets
        XCTAssertEqual(cd.includedTickets?.count, 1)
        XCTAssertEqual(cd.includedTickets?.first?.referenceIA5, "KDJET")
        XCTAssertEqual(cd.includedTickets?.first?.issuerName, "XYZ")
    }

    // MARK: - Extensions

    func testExtensions() throws {
        XCTAssertEqual(ticket.extensionData?.count, 2)
        XCTAssertEqual(ticket.extensionData?[0].extensionId, "1")
        XCTAssertEqual(ticket.extensionData?[0].extensionData, Data([0x82, 0xDA]))
        XCTAssertEqual(ticket.extensionData?[1].extensionId, "2")
        XCTAssertEqual(ticket.extensionData?[1].extensionData, Data([0x83, 0xDA]))
    }
}
