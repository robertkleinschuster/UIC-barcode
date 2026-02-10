import XCTest
@testable import UICBarcodeKit

/// Tests for FCB (Flexible Content Barcode) ticket types
/// Based on SimpleUICTestTicket.java and ticket API tests
final class FCBTicketTests: XCTestCase {

    // MARK: - Enum Tests

    /// Test TravelClassType enum
    /// Matches Java: TravelClassType.java (omv3)
    func testTravelClassTypeEnum() {
        XCTAssertEqual(TravelClassType.notApplicable.rawValue, 0)  // Java: notApplicabel
        XCTAssertEqual(TravelClassType.first.rawValue, 1)
        XCTAssertEqual(TravelClassType.second.rawValue, 2)
        XCTAssertEqual(TravelClassType.tourist.rawValue, 3)
        XCTAssertEqual(TravelClassType.comfort.rawValue, 4)
        XCTAssertEqual(TravelClassType.premium.rawValue, 5)
        XCTAssertEqual(TravelClassType.business.rawValue, 6)
        XCTAssertEqual(TravelClassType.all.rawValue, 7)
        XCTAssertEqual(TravelClassType.premiumFirst.rawValue, 8)
        XCTAssertEqual(TravelClassType.standardFirst.rawValue, 9)
        XCTAssertEqual(TravelClassType.premiumSecond.rawValue, 10)
        XCTAssertEqual(TravelClassType.standardSecond.rawValue, 11)
    }

    /// Test GenderType enum
    func testGenderTypeEnum() {
        XCTAssertEqual(GenderType.unspecified.rawValue, 0)
        XCTAssertEqual(GenderType.female.rawValue, 1)
        XCTAssertEqual(GenderType.male.rawValue, 2)
        XCTAssertEqual(GenderType.other.rawValue, 3)
    }

    /// Test PassengerType enum
    /// Matches Java: PassengerType.java (omv3)
    func testPassengerTypeEnum() {
        XCTAssertEqual(PassengerType.adult.rawValue, 0)
        XCTAssertEqual(PassengerType.senior.rawValue, 1)
        XCTAssertEqual(PassengerType.child.rawValue, 2)
        XCTAssertEqual(PassengerType.youth.rawValue, 3)
        XCTAssertEqual(PassengerType.dog.rawValue, 4)
        XCTAssertEqual(PassengerType.bicycle.rawValue, 5)
        XCTAssertEqual(PassengerType.freeAddonPassenger.rawValue, 6)
        XCTAssertEqual(PassengerType.freeAddonChild.rawValue, 7)
    }

    /// Test LinkMode enum
    func testLinkModeEnum() {
        XCTAssertEqual(LinkMode.issuedTogether.rawValue, 0)
        XCTAssertEqual(LinkMode.onlyValidInCombination.rawValue, 1)
    }

    /// Test ServiceType enum
    func testServiceTypeEnum() {
        XCTAssertEqual(ServiceType.seat.rawValue, 0)
        XCTAssertEqual(ServiceType.couchette.rawValue, 1)
        XCTAssertEqual(ServiceType.berth.rawValue, 2)
        XCTAssertEqual(ServiceType.carCarriage.rawValue, 3)
    }

    /// Test CodeTableType enum
    func testCodeTableTypeEnum() {
        XCTAssertEqual(CodeTableType.stationUIC.rawValue, 0)
        XCTAssertEqual(CodeTableType.stationUICReservation.rawValue, 1)
        XCTAssertEqual(CodeTableType.stationERA.rawValue, 2)
        XCTAssertEqual(CodeTableType.localCarrierStationCodeTable.rawValue, 3)
        XCTAssertEqual(CodeTableType.proprietaryIssuerStationCodeTable.rawValue, 4)
    }

    /// Test PriceTypeType enum
    func testPriceTypeEnum() {
        XCTAssertEqual(PriceTypeType.noPrice.rawValue, 0)
        XCTAssertEqual(PriceTypeType.reservationFee.rawValue, 1)
        XCTAssertEqual(PriceTypeType.supplement.rawValue, 2)
        XCTAssertEqual(PriceTypeType.travelPrice.rawValue, 3)
    }

    /// Test BerthTypeType enum
    func testBerthTypeEnum() {
        XCTAssertEqual(BerthTypeType.single.rawValue, 0)
        XCTAssertEqual(BerthTypeType.special.rawValue, 1)
        XCTAssertEqual(BerthTypeType.double.rawValue, 2)
        XCTAssertEqual(BerthTypeType.t2.rawValue, 3)
        XCTAssertEqual(BerthTypeType.t3.rawValue, 4)
        XCTAssertEqual(BerthTypeType.t4.rawValue, 5)
    }

    // MARK: - Common Types Tests

    /// Test GeoCoordinateType initialization
    func testGeoCoordinateType() {
        var coord = GeoCoordinateType()
        coord.longitude = 1234567
        coord.latitude = 7654321
        coord.geoUnit = .microDegree
        coord.coordinateSystem = .wgs84
        coord.hemisphereLongitude = .east
        coord.hemisphereLatitude = .north

        XCTAssertEqual(coord.longitude, 1234567)
        XCTAssertEqual(coord.latitude, 7654321)
        XCTAssertEqual(coord.geoUnit, .microDegree)
        XCTAssertEqual(coord.coordinateSystem, .wgs84)
    }

    /// Test CustomerStatusType initialization
    func testCustomerStatusType() {
        var status = CustomerStatusType()
        status.statusProviderNum = 1080
        status.customerStatus = 1
        status.customerStatusDescr = "senior"

        XCTAssertEqual(status.statusProviderNum, 1080)
        XCTAssertEqual(status.customerStatus, 1)
        XCTAssertEqual(status.customerStatusDescr, "senior")
    }

    /// Test CardReferenceType initialization
    func testCardReferenceType() {
        var cardRef = CardReferenceType()
        cardRef.cardIssuerNum = 1080
        cardRef.cardIdNum = 123456789
        cardRef.cardName = "BahnCard 50"
        cardRef.trailingCardIdNum = 100

        XCTAssertEqual(cardRef.cardIssuerNum, 1080)
        XCTAssertEqual(cardRef.cardIdNum, 123456789)
        XCTAssertEqual(cardRef.cardName, "BahnCard 50")
        XCTAssertEqual(cardRef.trailingCardIdNum, 100)
    }

    /// Test TicketLinkType initialization
    func testTicketLinkType() {
        var link = TicketLinkType()
        link.productOwnerNum = 1080
        link.productOwnerIA5 = "test"
        link.linkMode = .issuedTogether
        link.ticketType = .openTicket

        XCTAssertEqual(link.productOwnerNum, 1080)
        XCTAssertEqual(link.productOwnerIA5, "test")
        XCTAssertEqual(link.linkMode, .issuedTogether)
        XCTAssertEqual(link.ticketType, .openTicket)
    }

    /// Test TariffType initialization
    func testTariffType() {
        var tariff = TariffType()
        tariff.numberOfPassengers = 2
        tariff.passengerType = .adult
        tariff.ageBelow = 27
        tariff.ageAbove = 60
        tariff.tariffDesc = "Standard Tariff"

        XCTAssertEqual(tariff.numberOfPassengers, 2)
        XCTAssertEqual(tariff.passengerType, .adult)
        XCTAssertEqual(tariff.ageBelow, 27)
        XCTAssertEqual(tariff.ageAbove, 60)
        XCTAssertEqual(tariff.tariffDesc, "Standard Tariff")
    }

    /// Test RouteSectionType initialization
    func testRouteSectionType() {
        var route = RouteSectionType()
        route.stationCodeTable = .stationUIC
        route.fromStationNum = 8000001
        route.toStationNum = 8000002
        route.fromStationNameUTF8 = "Berlin Hbf"
        route.toStationNameUTF8 = "München Hbf"

        XCTAssertEqual(route.stationCodeTable, .stationUIC)
        XCTAssertEqual(route.fromStationNum, 8000001)
        XCTAssertEqual(route.toStationNum, 8000002)
        XCTAssertEqual(route.fromStationNameUTF8, "Berlin Hbf")
        XCTAssertEqual(route.toStationNameUTF8, "München Hbf")
    }

    /// Test VatDetailType initialization
    func testVatDetailType() {
        var vat = VatDetailType()
        vat.country = 80  // Germany
        vat.percentage = 190  // 19.0%
        vat.amount = 1900  // 19.00 EUR
        vat.vatId = "DE123456789"

        XCTAssertEqual(vat.country, 80)
        XCTAssertEqual(vat.percentage, 190)
        XCTAssertEqual(vat.amount, 1900)
        XCTAssertEqual(vat.vatId, "DE123456789")
    }

    // MARK: - UicRailTicketData Tests

    /// Test UicRailTicketData basic structure
    func testUicRailTicketDataStructure() {
        var ticket = UicRailTicketData()

        // Test IssuingData
        var issuing = IssuingData()
        issuing.issuerNum = 1080
        issuing.issuingYear = 2024
        issuing.issuingDay = 1
        issuing.specimen = true
        ticket.issuingDetail = issuing

        XCTAssertEqual(ticket.issuingDetail.issuerNum, 1080)
        XCTAssertEqual(ticket.issuingDetail.issuingYear, 2024)
        XCTAssertEqual(ticket.issuingDetail.issuingDay, 1)
        XCTAssertEqual(ticket.issuingDetail.specimen, true)
    }

    /// Test IssuingData from Java test
    func testIssuingDataFromJavaTest() {
        var issuing = IssuingData()
        issuing.issuerNum = 1080
        issuing.issuingYear = 2018
        issuing.issuingDay = 1
        issuing.specimen = true
        issuing.securePaperTicket = false
        issuing.activated = true
        issuing.issuerPNR = "issuerTestPNR"
        issuing.issuedOnLine = 12

        XCTAssertEqual(issuing.issuerNum, 1080)
        XCTAssertEqual(issuing.issuingYear, 2018)
        XCTAssertEqual(issuing.issuingDay, 1)
        XCTAssertEqual(issuing.specimen, true)
        XCTAssertEqual(issuing.securePaperTicket, false)
        XCTAssertEqual(issuing.activated, true)
        XCTAssertEqual(issuing.issuerPNR, "issuerTestPNR")
        XCTAssertEqual(issuing.issuedOnLine, 12)
    }

    // MARK: - TravelerData Tests

    /// Test TravelerData creation from Java test
    func testTravelerDataFromJavaTest() {
        var travelerDetail = TravelerData()
        travelerDetail.groupName = "myGroup"

        var traveler = TravelerType()
        traveler.firstName = "John"
        traveler.secondName = "Dow"
        traveler.idCard = "12345"
        traveler.ticketHolder = true

        var status = CustomerStatusType()
        status.customerStatusDescr = "senior"
        traveler.status = [status]

        travelerDetail.traveler = [traveler]

        XCTAssertEqual(travelerDetail.groupName, "myGroup")
        XCTAssertEqual(travelerDetail.traveler?.count, 1)

        if let t = travelerDetail.traveler?.first {
            XCTAssertEqual(t.firstName, "John")
            XCTAssertEqual(t.secondName, "Dow")
            XCTAssertEqual(t.idCard, "12345")
            XCTAssertEqual(t.ticketHolder, true)
            XCTAssertEqual(t.status?.first?.customerStatusDescr, "senior")
        }
    }

    // MARK: - OpenTicketData Tests

    /// Test OpenTicketData from Java test
    func testOpenTicketFromJavaTest() {
        var openTicket = OpenTicketData()
        openTicket.infoText = "openTicketInfo"
        openTicket.returnIncluded = false

        XCTAssertEqual(openTicket.infoText, "openTicketInfo")
        XCTAssertEqual(openTicket.returnIncluded, false)
    }

    /// Test OpenTicketData with station data
    func testOpenTicketWithStations() {
        var openTicket = OpenTicketData()
        openTicket.fromStationNum = 8000001
        openTicket.toStationNum = 8000002
        openTicket.fromStationNameUTF8 = "Berlin Hbf"
        openTicket.toStationNameUTF8 = "München Hbf"

        XCTAssertEqual(openTicket.fromStationNum, 8000001)
        XCTAssertEqual(openTicket.toStationNum, 8000002)
        XCTAssertEqual(openTicket.fromStationNameUTF8, "Berlin Hbf")
        XCTAssertEqual(openTicket.toStationNameUTF8, "München Hbf")
    }

    // MARK: - StationPassageData Tests

    /// Test StationPassageData from Java test
    func testStationPassageFromJavaTest() {
        var stationPassage = StationPassageData()
        stationPassage.productName = "passage"
        stationPassage.stationNum = [8312345]
        stationPassage.stationNameUTF8 = ["Amsterdam"]
        stationPassage.validFromDay = 0
        stationPassage.validUntilDay = 4

        XCTAssertEqual(stationPassage.productName, "passage")
        XCTAssertEqual(stationPassage.stationNum?.first, 8312345)
        XCTAssertEqual(stationPassage.stationNameUTF8?.first, "Amsterdam")
        XCTAssertEqual(stationPassage.validFromDay, 0)
        XCTAssertEqual(stationPassage.validUntilDay, 4)
    }

    // MARK: - ControlData Tests

    /// Test ControlData from Java test
    func testControlDataFromJavaTest() {
        var control = ControlData()
        control.infoText = "cd"
        control.ageCheckRequired = false
        control.identificationByIdCard = false
        control.identificationByPassportId = false
        control.onlineValidationRequired = false
        control.passportValidationRequired = false
        control.reductionCardCheckRequired = false

        var cardRef = CardReferenceType()
        cardRef.trailingCardIdNum = 100
        control.identificationByCardReference = [cardRef]

        var linkedTicket = TicketLinkType()
        linkedTicket.productOwnerIA5 = "test"
        linkedTicket.linkMode = .issuedTogether
        control.includedTickets = [linkedTicket]

        XCTAssertEqual(control.infoText, "cd")
        XCTAssertEqual(control.ageCheckRequired, false)
        XCTAssertEqual(control.identificationByCardReference?.first?.trailingCardIdNum, 100)
        XCTAssertEqual(control.includedTickets?.first?.productOwnerIA5, "test")
        XCTAssertEqual(control.includedTickets?.first?.linkMode, .issuedTogether)
    }

    // MARK: - ExtensionData Tests

    /// Test ExtensionData from Java test
    func testExtensionFromJavaTest() {
        var ext = ExtensionData()
        ext.extensionId = "1"
        ext.extensionData = Data([0x82, 0xDA])

        XCTAssertEqual(ext.extensionId, "1")
        XCTAssertEqual(ext.extensionData, Data([0x82, 0xDA]))
    }

    // MARK: - ReservationData Tests

    /// Test ReservationData structure
    func testReservationData() {
        var reservation = ReservationData()
        reservation.trainNum = 123
        reservation.fromStationNum = 8000001
        reservation.toStationNum = 8000002
        reservation.departureDate = 100
        reservation.departureTime = 480  // 08:00
        reservation.arrivalTime = 720    // 12:00
        reservation.classCode = .first
        reservation.service = .seat
        reservation.infoText = "Reservation info"

        XCTAssertEqual(reservation.trainNum, 123)
        XCTAssertEqual(reservation.fromStationNum, 8000001)
        XCTAssertEqual(reservation.toStationNum, 8000002)
        XCTAssertEqual(reservation.departureDate, 100)
        XCTAssertEqual(reservation.departureTime, 480)
        XCTAssertEqual(reservation.arrivalTime, 720)
        XCTAssertEqual(reservation.classCode, .first)
        XCTAssertEqual(reservation.service, .seat)
        XCTAssertEqual(reservation.infoText, "Reservation info")
    }

    // MARK: - PassData Tests

    /// Test PassData structure
    func testPassData() {
        var pass = PassData()
        pass.passType = 1
        pass.passDescription = "Interrail Global Pass"
        pass.classCode = .second
        pass.validFromDay = 0
        pass.validFromTime = 0
        pass.validUntilDay = 30
        pass.validUntilTime = 1439  // 23:59

        XCTAssertEqual(pass.passType, 1)
        XCTAssertEqual(pass.passDescription, "Interrail Global Pass")
        XCTAssertEqual(pass.classCode, .second)
        XCTAssertEqual(pass.validFromDay, 0)
        XCTAssertEqual(pass.validUntilDay, 30)
    }

    // MARK: - CustomerCardData Tests

    /// Test CustomerCardData structure
    func testCustomerCardData() {
        var card = CustomerCardData()
        card.cardIdNum = 123456789
        card.cardType = 1
        card.cardTypeDescr = "BahnCard 50"
        card.classCode = .first
        card.validFromYear = 2024
        card.validFromDay = 1
        card.validUntilYear = 2025
        card.validUntilDay = 365

        XCTAssertEqual(card.cardIdNum, 123456789)
        XCTAssertEqual(card.cardType, 1)
        XCTAssertEqual(card.cardTypeDescr, "BahnCard 50")
        XCTAssertEqual(card.classCode, .first)
        XCTAssertEqual(card.validFromYear, 2024)
        XCTAssertEqual(card.validUntilYear, 2025)
    }

    // MARK: - VoucherData Tests

    /// Test VoucherData structure
    func testVoucherData() {
        var voucher = VoucherData()
        voucher.referenceNum = 12345
        voucher.productOwnerNum = 1080
        voucher.productIdNum = 999
        voucher.validFromYear = 2024
        voucher.validFromDay = 1
        voucher.validUntilYear = 2024
        voucher.validUntilDay = 365
        voucher.value = 5000  // 50.00 EUR
        voucher.voucherType = 1
        voucher.infoText = "Gutschein"

        XCTAssertEqual(voucher.referenceNum, 12345)
        XCTAssertEqual(voucher.productOwnerNum, 1080)
        XCTAssertEqual(voucher.value, 5000)
        XCTAssertEqual(voucher.infoText, "Gutschein")
    }

    // MARK: - DelayConfirmation Tests

    /// Test DelayConfirmation structure
    func testDelayConfirmation() {
        var delay = DelayConfirmation()
        delay.referenceNum = 123
        delay.trainNum = 456
        delay.plannedArrivalYear = 2024
        delay.plannedArrivalDay = 100
        delay.delay = 30  // 30 minutes delay
        delay.trainCancelled = false
        delay.confirmationType = .trainDelayConfirmation

        // affectedTickets is [TicketLinkType], create proper objects
        var ticket1 = TicketLinkType()
        ticket1.referenceIA5 = "TICKET001"
        var ticket2 = TicketLinkType()
        ticket2.referenceIA5 = "TICKET002"
        delay.affectedTickets = [ticket1, ticket2]

        XCTAssertEqual(delay.referenceNum, 123)
        XCTAssertEqual(delay.trainNum, 456)
        XCTAssertEqual(delay.delay, 30)
        XCTAssertEqual(delay.trainCancelled, false)
        XCTAssertEqual(delay.confirmationType, .trainDelayConfirmation)
        XCTAssertEqual(delay.affectedTickets?.count, 2)
    }
}
