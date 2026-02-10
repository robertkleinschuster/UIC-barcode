import XCTest
@testable import UICBarcodeKit

/// FCB Encoder Round-Trip Tests
/// Builds v3 model objects, encodes to UPER, decodes back, and verifies equality.
final class FCBEncoderTests: XCTestCase {

    // MARK: - Minimal Ticket Round-Trip

    func testMinimalTicketRoundTrip() throws {
        var ticket = UicRailTicketData()
        ticket.issuingDetail = IssuingData()
        ticket.issuingDetail.issuingYear = 2025
        ticket.issuingDetail.issuingDay = 42
        ticket.issuingDetail.issuingTime = 720

        let encoded = try FCBVersionEncoder.encode(ticket: ticket)
        let decoded = try FCBVersionDecoder.decode(data: encoded, version: 3)

        XCTAssertEqual(decoded.issuingDetail.issuingYear, 2025)
        XCTAssertEqual(decoded.issuingDetail.issuingDay, 42)
        XCTAssertEqual(decoded.issuingDetail.issuingTime, 720)
        XCTAssertNil(decoded.travelerDetail)
        XCTAssertNil(decoded.transportDocument)
        XCTAssertNil(decoded.controlDetail)
    }

    // MARK: - IssuingData All Fields

    func testIssuingDataAllFieldsRoundTrip() throws {
        var issuing = IssuingData()
        issuing.securityProviderNum = 1234
        issuing.securityProviderIA5 = "PROV"
        issuing.issuerNum = 5678
        issuing.issuerIA5 = "ISS"
        issuing.issuingYear = 2025
        issuing.issuingDay = 100
        issuing.issuingTime = 600
        issuing.issuerName = "Test Issuer"
        issuing.specimen = true
        issuing.securePaperTicket = true
        issuing.activated = false
        issuing.currency = "USD"  // non-default
        issuing.currencyFract = 3  // non-default
        issuing.issuerPNR = "PNR123"
        issuing.issuedOnTrainNum = 42
        issuing.issuedOnTrainIA5 = "ICE42"
        issuing.issuedOnLine = 7

        var ticket = UicRailTicketData()
        ticket.issuingDetail = issuing

        let encoded = try FCBVersionEncoder.encode(ticket: ticket)
        let decoded = try FCBVersionDecoder.decode(data: encoded, version: 3)

        let d = decoded.issuingDetail
        XCTAssertEqual(d.securityProviderNum, 1234)
        XCTAssertEqual(d.securityProviderIA5, "PROV")
        XCTAssertEqual(d.issuerNum, 5678)
        XCTAssertEqual(d.issuerIA5, "ISS")
        XCTAssertEqual(d.issuingYear, 2025)
        XCTAssertEqual(d.issuingDay, 100)
        XCTAssertEqual(d.issuingTime, 600)
        XCTAssertEqual(d.issuerName, "Test Issuer")
        XCTAssertTrue(d.specimen)
        XCTAssertTrue(d.securePaperTicket)
        XCTAssertFalse(d.activated)
        XCTAssertEqual(d.currency, "USD")
        XCTAssertEqual(d.currencyFract, 3)
        XCTAssertEqual(d.issuerPNR, "PNR123")
        XCTAssertEqual(d.issuedOnTrainNum, 42)
        XCTAssertEqual(d.issuedOnTrainIA5, "ICE42")
        XCTAssertEqual(d.issuedOnLine, 7)
    }

    func testIssuingDataDefaultsRoundTrip() throws {
        // When currency is EUR (default) and currencyFract is 2 (default),
        // they should not be encoded but still decode to default values
        var issuing = IssuingData()
        issuing.issuingYear = 2025
        issuing.issuingDay = 1
        issuing.issuingTime = 0
        issuing.currency = "EUR"
        issuing.currencyFract = 2

        var ticket = UicRailTicketData()
        ticket.issuingDetail = issuing

        let encoded = try FCBVersionEncoder.encode(ticket: ticket)
        let decoded = try FCBVersionDecoder.decode(data: encoded, version: 3)

        XCTAssertEqual(decoded.issuingDetail.currency, "EUR")
        XCTAssertEqual(decoded.issuingDetail.currencyFract, 2)
    }

    // MARK: - TravelerData

    func testTravelerDataRoundTrip() throws {
        var traveler = TravelerType()
        traveler.firstName = "Max"
        traveler.lastName = "Mustermann"
        traveler.ticketHolder = true
        traveler.yearOfBirth = 1990
        traveler.monthOfBirth = 6
        traveler.dayOfBirth = 15
        traveler.gender = .male
        traveler.passengerType = .adult
        traveler.countryOfResidence = 80

        var travelerData = TravelerData()
        travelerData.traveler = [traveler]
        travelerData.preferedLanguage = "de"
        travelerData.groupName = "TestGroup"

        var ticket = UicRailTicketData()
        ticket.issuingDetail = IssuingData()
        ticket.issuingDetail.issuingYear = 2025
        ticket.issuingDetail.issuingDay = 1
        ticket.issuingDetail.issuingTime = 0
        ticket.travelerDetail = travelerData

        let encoded = try FCBVersionEncoder.encode(ticket: ticket)
        let decoded = try FCBVersionDecoder.decode(data: encoded, version: 3)

        XCTAssertNotNil(decoded.travelerDetail)
        let td = decoded.travelerDetail!
        XCTAssertEqual(td.preferedLanguage, "de")
        XCTAssertEqual(td.groupName, "TestGroup")
        XCTAssertEqual(td.traveler?.count, 1)

        let t = td.traveler![0]
        XCTAssertEqual(t.firstName, "Max")
        XCTAssertEqual(t.lastName, "Mustermann")
        XCTAssertTrue(t.ticketHolder)
        XCTAssertEqual(t.yearOfBirth, 1990)
        XCTAssertEqual(t.monthOfBirth, 6)
        XCTAssertEqual(t.dayOfBirth, 15)
        XCTAssertEqual(t.gender, .male)
        XCTAssertEqual(t.passengerType, .adult)
        XCTAssertEqual(t.countryOfResidence, 80)
    }

    // MARK: - Reservation

    func testReservationRoundTrip() throws {
        var res = ReservationData()
        res.trainNum = 12345
        res.departureDate = 10
        res.departureTime = 480
        res.arrivalDate = 10
        res.arrivalTime = 720
        res.fromStationNum = 8000105
        res.toStationNum = 8000261
        res.classCode = .second
        res.service = .seat
        res.numberOfOverbooked = 0
        res.price = 4900  // 49.00

        var doc = DocumentData()
        doc.ticket = TicketDetailData()
        doc.ticket.ticketType = .reservation(res)

        var ticket = UicRailTicketData()
        ticket.issuingDetail = IssuingData()
        ticket.issuingDetail.issuingYear = 2025
        ticket.issuingDetail.issuingDay = 42
        ticket.issuingDetail.issuingTime = 0
        ticket.transportDocument = [doc]

        let encoded = try FCBVersionEncoder.encode(ticket: ticket)
        let decoded = try FCBVersionDecoder.decode(data: encoded, version: 3)

        XCTAssertNotNil(decoded.transportDocument)
        XCTAssertEqual(decoded.transportDocument?.count, 1)

        guard case .reservation(let r)? = decoded.transportDocument?[0].ticket.ticketType else {
            XCTFail("Expected reservation")
            return
        }

        XCTAssertEqual(r.trainNum, 12345)
        XCTAssertEqual(r.departureDate, 10)
        XCTAssertEqual(r.departureTime, 480)
        XCTAssertEqual(r.arrivalDate, 10)
        XCTAssertEqual(r.arrivalTime, 720)
        XCTAssertEqual(r.fromStationNum, 8000105)
        XCTAssertEqual(r.toStationNum, 8000261)
        XCTAssertEqual(r.classCode, .second)
        XCTAssertEqual(r.service, .seat)
        XCTAssertEqual(r.numberOfOverbooked, 0)
        XCTAssertEqual(r.price, 4900)
    }

    // MARK: - Open Ticket

    func testOpenTicketRoundTrip() throws {
        var ot = OpenTicketData()
        ot.returnIncluded = false
        ot.fromStationNum = 8000105
        ot.toStationNum = 8000261
        ot.classCode = .second
        ot.validFromDay = 0
        ot.validUntilDay = 1
        ot.price = 3500
        ot.productIdNum = 1234

        var doc = DocumentData()
        doc.ticket = TicketDetailData()
        doc.ticket.ticketType = .openTicket(ot)

        var ticket = UicRailTicketData()
        ticket.issuingDetail = IssuingData()
        ticket.issuingDetail.issuingYear = 2025
        ticket.issuingDetail.issuingDay = 1
        ticket.issuingDetail.issuingTime = 0
        ticket.transportDocument = [doc]

        let encoded = try FCBVersionEncoder.encode(ticket: ticket)
        let decoded = try FCBVersionDecoder.decode(data: encoded, version: 3)

        guard case .openTicket(let o)? = decoded.transportDocument?[0].ticket.ticketType else {
            XCTFail("Expected openTicket")
            return
        }

        XCTAssertFalse(o.returnIncluded)
        XCTAssertEqual(o.fromStationNum, 8000105)
        XCTAssertEqual(o.toStationNum, 8000261)
        XCTAssertEqual(o.classCode, .second)
        XCTAssertEqual(o.validFromDay, 0)
        XCTAssertEqual(o.validUntilDay, 1)
        XCTAssertEqual(o.price, 3500)
        XCTAssertEqual(o.productIdNum, 1234)
    }

    // MARK: - Pass

    func testPassRoundTrip() throws {
        var pass = PassData()
        pass.passType = 1
        pass.classCode = .first
        pass.validFromDay = 0
        pass.validUntilDay = 30
        pass.price = 29900

        var doc = DocumentData()
        doc.ticket = TicketDetailData()
        doc.ticket.ticketType = .pass(pass)

        var ticket = UicRailTicketData()
        ticket.issuingDetail = IssuingData()
        ticket.issuingDetail.issuingYear = 2025
        ticket.issuingDetail.issuingDay = 1
        ticket.issuingDetail.issuingTime = 0
        ticket.transportDocument = [doc]

        let encoded = try FCBVersionEncoder.encode(ticket: ticket)
        let decoded = try FCBVersionDecoder.decode(data: encoded, version: 3)

        guard case .pass(let p)? = decoded.transportDocument?[0].ticket.ticketType else {
            XCTFail("Expected pass")
            return
        }

        XCTAssertEqual(p.passType, 1)
        XCTAssertEqual(p.classCode, .first)
        XCTAssertEqual(p.validFromDay, 0)
        XCTAssertEqual(p.validUntilDay, 30)
        XCTAssertEqual(p.price, 29900)
    }

    // MARK: - Customer Card

    func testCustomerCardRoundTrip() throws {
        var card = CustomerCardData()
        card.cardIdIA5 = "CARD123"
        card.validFromYear = 2025
        card.validFromDay = 1
        card.validUntilYear = 1  // delta from validFromYear (0..250)
        card.validUntilDay = 365
        card.classCode = .first
        card.cardType = 42

        var doc = DocumentData()
        doc.ticket = TicketDetailData()
        doc.ticket.ticketType = .customerCard(card)

        var ticket = UicRailTicketData()
        ticket.issuingDetail = IssuingData()
        ticket.issuingDetail.issuingYear = 2025
        ticket.issuingDetail.issuingDay = 1
        ticket.issuingDetail.issuingTime = 0
        ticket.transportDocument = [doc]

        let encoded = try FCBVersionEncoder.encode(ticket: ticket)
        let decoded = try FCBVersionDecoder.decode(data: encoded, version: 3)

        guard case .customerCard(let c)? = decoded.transportDocument?[0].ticket.ticketType else {
            XCTFail("Expected customerCard")
            return
        }

        XCTAssertEqual(c.cardIdIA5, "CARD123")
        XCTAssertEqual(c.validFromYear, 2025)
        XCTAssertEqual(c.validFromDay, 1)
        XCTAssertEqual(c.validUntilYear, 1)
        XCTAssertEqual(c.validUntilDay, 365)
        XCTAssertEqual(c.classCode, .first)
        XCTAssertEqual(c.cardType, 42)
    }

    // MARK: - Station Passage

    func testStationPassageRoundTrip() throws {
        var sp = StationPassageData()
        sp.productName = "Bahnsteigkarte"
        sp.validFromDay = 0
        sp.validFromTime = 480
        sp.validUntilDay = 0
        sp.validUntilTime = 1080
        sp.stationNum = [8000105, 8000261]

        var doc = DocumentData()
        doc.ticket = TicketDetailData()
        doc.ticket.ticketType = .stationPassage(sp)

        var ticket = UicRailTicketData()
        ticket.issuingDetail = IssuingData()
        ticket.issuingDetail.issuingYear = 2025
        ticket.issuingDetail.issuingDay = 1
        ticket.issuingDetail.issuingTime = 0
        ticket.transportDocument = [doc]

        let encoded = try FCBVersionEncoder.encode(ticket: ticket)
        let decoded = try FCBVersionDecoder.decode(data: encoded, version: 3)

        guard case .stationPassage(let s)? = decoded.transportDocument?[0].ticket.ticketType else {
            XCTFail("Expected stationPassage")
            return
        }

        XCTAssertEqual(s.productName, "Bahnsteigkarte")
        XCTAssertEqual(s.validFromDay, 0)
        XCTAssertEqual(s.validFromTime, 480)
        XCTAssertEqual(s.validUntilDay, 0)
        XCTAssertEqual(s.validUntilTime, 1080)
        XCTAssertEqual(s.stationNum, [8000105, 8000261])
    }

    // MARK: - Control Data

    func testControlDataRoundTrip() throws {
        var control = ControlData()
        control.identificationByIdCard = true
        control.identificationByPassportId = false
        control.passportValidationRequired = false
        control.onlineValidationRequired = true
        control.ageCheckRequired = false
        control.reductionCardCheckRequired = true
        control.infoText = "Please have ID ready"

        var ticket = UicRailTicketData()
        ticket.issuingDetail = IssuingData()
        ticket.issuingDetail.issuingYear = 2025
        ticket.issuingDetail.issuingDay = 1
        ticket.issuingDetail.issuingTime = 0
        ticket.controlDetail = control

        let encoded = try FCBVersionEncoder.encode(ticket: ticket)
        let decoded = try FCBVersionDecoder.decode(data: encoded, version: 3)

        XCTAssertNotNil(decoded.controlDetail)
        let c = decoded.controlDetail!
        XCTAssertTrue(c.identificationByIdCard)
        XCTAssertFalse(c.identificationByPassportId)
        XCTAssertFalse(c.passportValidationRequired)
        XCTAssertTrue(c.onlineValidationRequired)
        XCTAssertFalse(c.ageCheckRequired)
        XCTAssertTrue(c.reductionCardCheckRequired)
        XCTAssertEqual(c.infoText, "Please have ID ready")
    }

    // MARK: - Multiple Documents

    func testMultipleDocumentsRoundTrip() throws {
        var res = ReservationData()
        res.trainNum = 100
        res.departureDate = 5
        res.departureTime = 360

        var ot = OpenTicketData()
        ot.returnIncluded = false
        ot.fromStationNum = 8000105
        ot.toStationNum = 8000261
        ot.validFromDay = 0
        ot.validUntilDay = 1

        var doc1 = DocumentData()
        doc1.ticket = TicketDetailData()
        doc1.ticket.ticketType = .reservation(res)

        var doc2 = DocumentData()
        doc2.ticket = TicketDetailData()
        doc2.ticket.ticketType = .openTicket(ot)

        var ticket = UicRailTicketData()
        ticket.issuingDetail = IssuingData()
        ticket.issuingDetail.issuingYear = 2025
        ticket.issuingDetail.issuingDay = 1
        ticket.issuingDetail.issuingTime = 0
        ticket.transportDocument = [doc1, doc2]

        let encoded = try FCBVersionEncoder.encode(ticket: ticket)
        let decoded = try FCBVersionDecoder.decode(data: encoded, version: 3)

        XCTAssertEqual(decoded.transportDocument?.count, 2)

        guard case .reservation(let r)? = decoded.transportDocument?[0].ticket.ticketType else {
            XCTFail("Expected reservation for doc 0")
            return
        }
        XCTAssertEqual(r.trainNum, 100)
        XCTAssertEqual(r.departureDate, 5)
        XCTAssertEqual(r.departureTime, 360)

        guard case .openTicket(let o)? = decoded.transportDocument?[1].ticket.ticketType else {
            XCTFail("Expected openTicket for doc 1")
            return
        }
        XCTAssertFalse(o.returnIncluded)
        XCTAssertEqual(o.fromStationNum, 8000105)
        XCTAssertEqual(o.toStationNum, 8000261)
    }

    // MARK: - Extension Data

    func testExtensionDataRoundTrip() throws {
        var ext = ExtensionData()
        ext.extensionId = "1234"
        ext.extensionData = Data([0x01, 0x02, 0x03])

        var ticket = UicRailTicketData()
        ticket.issuingDetail = IssuingData()
        ticket.issuingDetail.issuingYear = 2025
        ticket.issuingDetail.issuingDay = 1
        ticket.issuingDetail.issuingTime = 0
        ticket.extensionData = [ext]

        let encoded = try FCBVersionEncoder.encode(ticket: ticket)
        let decoded = try FCBVersionDecoder.decode(data: encoded, version: 3)

        XCTAssertNotNil(decoded.extensionData)
        XCTAssertEqual(decoded.extensionData?.count, 1)
        XCTAssertEqual(decoded.extensionData?[0].extensionId, "1234")
        XCTAssertEqual(decoded.extensionData?[0].extensionData, Data([0x01, 0x02, 0x03]))
    }

    // MARK: - Decode-Encode-Decode (from test data hex)

    func testDecodeEncodeDecodeConsistency() throws {
        // Build a complete ticket, encode, decode, re-encode — the two byte sequences must match
        var ticket = UicRailTicketData()
        var issuing = IssuingData()
        issuing.issuerNum = 1080
        issuing.issuingYear = 2025
        issuing.issuingDay = 42
        issuing.issuingTime = 600
        issuing.specimen = false
        issuing.securePaperTicket = false
        issuing.activated = true
        ticket.issuingDetail = issuing

        var res = ReservationData()
        res.trainNum = 100
        res.departureDate = 5
        res.departureTime = 480
        res.fromStationNum = 8000105
        res.toStationNum = 8000261
        res.classCode = .second

        var doc = DocumentData()
        doc.ticket = TicketDetailData()
        doc.ticket.ticketType = .reservation(res)
        ticket.transportDocument = [doc]

        let encoded1 = try FCBVersionEncoder.encode(ticket: ticket)
        let decoded = try FCBVersionDecoder.decode(data: encoded1, version: 3)
        let encoded2 = try FCBVersionEncoder.encode(ticket: decoded)

        // Byte-for-byte match: encode(decode(encode(ticket))) == encode(ticket)
        XCTAssertEqual(encoded1, encoded2, "Re-encoding decoded ticket should produce identical bytes")
    }
}
