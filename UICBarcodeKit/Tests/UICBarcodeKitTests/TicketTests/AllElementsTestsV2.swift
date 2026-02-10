import XCTest
@testable import UICBarcodeKit

/// All Elements V2 Tests
/// Translated from Java: AllElementsTestTicketV2.java
/// Decodes V2 UPER data via FCBVersionDecoder (converts to V3 UicRailTicketData)
final class AllElementsTestsV2: XCTestCase {

    private var ticket: UicRailTicketData!

    override func setUpWithError() throws {
        let data = TestTicketsV2.allElementsData
        ticket = try FCBVersionDecoder.decode(data: data, version: 2)
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
        // V2 adds monthOfBirth = 11
        XCTAssertEqual(t?.monthOfBirth, 11)
        XCTAssertEqual(t?.dayOfBirth, 31)
        XCTAssertEqual(t?.ticketHolder, true)
        XCTAssertEqual(t?.passengerType, .senior)
        XCTAssertEqual(t?.passengerWithReducedMobility, false)
        XCTAssertEqual(t?.countryOfResidence, 101)
        XCTAssertEqual(t?.countryOfPassport, 102)
        XCTAssertEqual(t?.countryOfIdCard, 103)
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
        XCTAssertEqual(r.productOwnerNum, 23456)
        XCTAssertEqual(r.productIdNum, 15535)
        XCTAssertEqual(r.serviceBrand, 12)
        XCTAssertEqual(r.serviceBrandAbrUTF8, "TGV")
        XCTAssertEqual(r.serviceBrandNameUTF8, "Lyria")
        XCTAssertEqual(r.service, .couchette)
        XCTAssertEqual(r.stationCodeTable, .stationUIC)
        XCTAssertEqual(r.fromStationNum, 8100001)
        XCTAssertEqual(r.toStationNum, 8000002)
        XCTAssertEqual(r.departureTime, 1439)
        XCTAssertEqual(r.departureUTCOffset, -60)
        XCTAssertEqual(r.arrivalDate, 20)
        XCTAssertEqual(r.arrivalTime, 0)
        XCTAssertEqual(r.arrivalUTCOffset, 10)
        XCTAssertEqual(r.classCode, .first)
        XCTAssertEqual(r.price, 12345)
        XCTAssertEqual(r.infoText, "reservation")

        // Places
        XCTAssertEqual(r.places?.coach, "31A")
        XCTAssertEqual(r.places?.placeString, "31-47")
        XCTAssertEqual(r.places?.placeNum, [31, 32])

        // Berth
        XCTAssertEqual(r.berth?.count, 1)
        XCTAssertEqual(r.berth?.first?.berthType, .single)
        XCTAssertEqual(r.berth?.first?.gender, .female)
        XCTAssertEqual(r.berth?.first?.numberOfBerths, 999)

        // Tariff
        XCTAssertEqual(r.tariff?.count, 1)
        XCTAssertEqual(r.tariff?.first?.tariffIdNum, 72)

        // VAT
        XCTAssertEqual(r.vatDetails?.count, 1)
        XCTAssertEqual(r.vatDetails?.first?.country, 80)
        XCTAssertEqual(r.vatDetails?.first?.percentage, 70)
        XCTAssertEqual(r.vatDetails?.first?.amount, 10)
        XCTAssertEqual(r.vatDetails?.first?.vatId, "IUDGTE")
    }

    // MARK: - CarCarriageReservation (doc 1)

    func testCarCarriageReservation() throws {
        let doc = try XCTUnwrap(ticket.transportDocument?[1])
        guard case .carCarriageReservation(let r) = doc.ticket.ticketType else {
            XCTFail("Expected carCarriageReservation"); return
        }
        XCTAssertEqual(r.trainNum, 123)
        XCTAssertEqual(r.productOwnerNum, 23456)
        XCTAssertEqual(r.productIdNum, 15535)
        XCTAssertEqual(r.fromStationNum, 8100001)
        XCTAssertEqual(r.toStationNum, 8000002)
        XCTAssertEqual(r.roofRackType, .bicycleRack)
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

        XCTAssertEqual(o.productOwnerNum, 23456)
        XCTAssertEqual(o.productIdNum, 15535)
        XCTAssertEqual(o.returnIncluded, false)
        XCTAssertEqual(o.fromStationNum, 8100001)
        XCTAssertEqual(o.toStationNum, 8000002)
        XCTAssertEqual(o.validFromDay, 700)
        XCTAssertEqual(o.validUntilDay, 370)
        XCTAssertEqual(o.classCode, .first)
        XCTAssertEqual(o.price, 12345)
        XCTAssertEqual(o.infoText, "openTicketInfo")
        XCTAssertEqual(o.validRegion?.count, 5)
        XCTAssertEqual(o.includedAddOns?.count, 1)
        XCTAssertEqual(o.includedAddOns?.first?.infoText, "included ticket")
    }

    // MARK: - Pass (doc 3)

    func testPass() throws {
        let doc = try XCTUnwrap(ticket.transportDocument?[3])
        guard case .pass(let p) = doc.ticket.ticketType else {
            XCTFail("Expected pass"); return
        }

        XCTAssertEqual(p.productOwnerNum, 23456)
        XCTAssertEqual(p.productIdNum, 15535)
        XCTAssertEqual(p.passDescription, "Eurail FlexPass")
        XCTAssertEqual(p.classCode, .first)
        XCTAssertEqual(p.validFromDay, 0)
        XCTAssertEqual(p.validFromTime, 1000)
        XCTAssertEqual(p.validUntilDay, 1)
        XCTAssertEqual(p.validUntilTime, 1000)
        XCTAssertEqual(p.numberOfValidityDays, 5)
        XCTAssertEqual(p.numberOfDaysOfTravel, 10)
        XCTAssertEqual(p.activatedDay, [200, 201])
        XCTAssertEqual(p.countries, [10, 20])
        XCTAssertEqual(p.price, 10000)
        XCTAssertEqual(p.infoText, "pass info")
    }

    // MARK: - Voucher (doc 4)

    func testVoucher() throws {
        let doc = try XCTUnwrap(ticket.transportDocument?[4])
        guard case .voucher(let v) = doc.ticket.ticketType else {
            XCTFail("Expected voucher"); return
        }

        XCTAssertEqual(v.productOwnerIA5, "COFFEEMACHINE")
        XCTAssertEqual(v.validFromYear, 2022)
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
        XCTAssertEqual(c.classCode, .second)
        XCTAssertEqual(c.cardTypeDescr, "RAILPLUS")
        XCTAssertEqual(c.customerStatusDescr, "gold")
        XCTAssertEqual(c.customer?.customerIdIA5, "1234")
        XCTAssertEqual(c.customer?.passengerType, .senior)
    }

    // MARK: - Countermark (doc 6)

    func testCountermark() throws {
        let doc = try XCTUnwrap(ticket.transportDocument?[6])
        guard case .countermark(let cm) = doc.ticket.ticketType else {
            XCTFail("Expected countermark"); return
        }

        XCTAssertEqual(cm.productOwnerNum, 23456)
        XCTAssertEqual(cm.numberOfCountermark, 12)
        XCTAssertEqual(cm.totalOfCountermarks, 24)
        XCTAssertEqual(cm.groupName, "groupName")
        XCTAssertEqual(cm.fromStationNum, 8100001)
        XCTAssertEqual(cm.validFromDay, 700)
        XCTAssertEqual(cm.classCode, .first)
        XCTAssertEqual(cm.infoText, "counterMark")
    }

    // MARK: - Parking (doc 7)

    func testParking() throws {
        let doc = try XCTUnwrap(ticket.transportDocument?[7])
        guard case .parkingGround(let p) = doc.ticket.ticketType else {
            XCTFail("Expected parkingGround"); return
        }

        XCTAssertEqual(p.parkingGroundId, "IA5")
        XCTAssertEqual(p.fromParkingDate, 370)
        XCTAssertEqual(p.toParkingDate, 370)
        XCTAssertEqual(p.stationNum, 8000001)
        XCTAssertEqual(p.numberPlate, "AA-DE-12345")
        XCTAssertEqual(p.price, 500)
    }

    // MARK: - FIP (doc 8)

    func testFIP() throws {
        let doc = try XCTUnwrap(ticket.transportDocument?[8])
        guard case .fipTicket(let f) = doc.ticket.ticketType else {
            XCTFail("Expected fipTicket"); return
        }

        XCTAssertEqual(f.productOwnerNum, 23456)
        XCTAssertEqual(f.validFromDay, 2)
        XCTAssertEqual(f.validUntilDay, 5)
        XCTAssertEqual(f.activatedDay, [1, 13, 14, 15])
        XCTAssertEqual(f.carrierNum, [1080, 1181])
        XCTAssertEqual(f.numberOfTravelDays, 8)
        XCTAssertEqual(f.classCode, .first)
    }

    // MARK: - StationPassage (doc 9)

    func testStationPassage() throws {
        let doc = try XCTUnwrap(ticket.transportDocument?[9])
        guard case .stationPassage(let s) = doc.ticket.ticketType else {
            XCTFail("Expected stationPassage"); return
        }

        XCTAssertEqual(s.productName, "passage")
        XCTAssertEqual(s.stationNum, [8200001])
        XCTAssertEqual(s.stationNameUTF8, ["Amsterdam"])
        XCTAssertEqual(s.validFromDay, 5)
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
        XCTAssertEqual(dc.plannedArrivalYear, 2022)
        XCTAssertEqual(dc.plannedArrivalDay, 12)
        XCTAssertEqual(dc.plannedArrivalTime, 1000)
        XCTAssertEqual(dc.stationNum, 8000001)
        XCTAssertEqual(dc.delay, 31)
        XCTAssertEqual(dc.confirmationType, .travelerDelayConfirmation)
        XCTAssertEqual(dc.infoText, "delay confirmation")
    }

    // MARK: - ControlData

    func testControlData() throws {
        let cd = try XCTUnwrap(ticket.controlDetail)
        XCTAssertEqual(cd.infoText, "control")
        XCTAssertEqual(cd.identificationItem, 12)
        XCTAssertEqual(cd.identificationByCardReference?.count, 1)
        XCTAssertEqual(cd.includedTickets?.count, 1)
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
