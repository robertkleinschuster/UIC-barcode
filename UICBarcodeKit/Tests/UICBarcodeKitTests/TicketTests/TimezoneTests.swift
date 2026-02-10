import XCTest
@testable import UICBarcodeKit

/// Tests for timezone-correct date population in decoders and UTC-correct encoding.
final class TimezoneTests: XCTestCase {

    // MARK: - Helper: UTC Date creation

    private func utcDate(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal.date(from: DateComponents(
            timeZone: TimeZone(identifier: "UTC")!,
            year: year, month: month, day: day,
            hour: hour, minute: minute
        ))!
    }

    // MARK: - DateTimeUtils Unit Tests

    func testGetDateWithDayOffset() {
        let issuing = utcDate(year: 2024, month: 6, day: 15, hour: 10, minute: 30)
        let result = DateTimeUtils.getDate(issuingDate: issuing, dayOffset: 5, time: 720) // noon
        XCTAssertNotNil(result)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: result!)
        XCTAssertEqual(comps.month, 6)
        XCTAssertEqual(comps.day, 20)
        XCTAssertEqual(comps.hour, 12)
        XCTAssertEqual(comps.minute, 0)
    }

    func testGetDateWithNilIssuingDate() {
        let result = DateTimeUtils.getDate(issuingDate: nil, dayOffset: 5, time: 720)
        XCTAssertNil(result)
    }

    func testGetDateWithZeroOffset() {
        let issuing = utcDate(year: 2024, month: 1, day: 1, hour: 0, minute: 0)
        let result = DateTimeUtils.getDate(issuingDate: issuing, dayOffset: 0, time: 0)
        XCTAssertNotNil(result)
    }

    func testGetDateDifferenceBasic() {
        let d1 = utcDate(year: 2024, month: 6, day: 15)
        let d2 = utcDate(year: 2024, month: 6, day: 20)
        XCTAssertEqual(DateTimeUtils.getDateDifference(d1, d2), 5)
    }

    func testGetDateDifferenceNegative() {
        let d1 = utcDate(year: 2024, month: 6, day: 20)
        let d2 = utcDate(year: 2024, month: 6, day: 15)
        XCTAssertEqual(DateTimeUtils.getDateDifference(d1, d2), -5)
    }

    func testGetDateDifferenceSameDay() {
        let d1 = utcDate(year: 2024, month: 6, day: 15, hour: 3, minute: 0)
        let d2 = utcDate(year: 2024, month: 6, day: 15, hour: 23, minute: 0)
        XCTAssertEqual(DateTimeUtils.getDateDifference(d1, d2), 0)
    }

    func testGetDateDifferenceNilInput() {
        XCTAssertNil(DateTimeUtils.getDateDifference(nil, utcDate(year: 2024, month: 1, day: 1)))
        XCTAssertNil(DateTimeUtils.getDateDifference(utcDate(year: 2024, month: 1, day: 1), nil))
    }

    func testGetTimeFromDate() {
        let date = utcDate(year: 2024, month: 6, day: 15, hour: 14, minute: 30)
        // getTime uses system calendar, not UTC; compare in local terms
        let time = DateTimeUtils.getTime(date)
        XCTAssertNotNil(time)
    }

    func testGetTimeNil() {
        XCTAssertNil(DateTimeUtils.getTime(nil))
    }

    // MARK: - V3 Reservation Date Round-Trip

    func testV3ReservationDatesRoundTrip() throws {
        let issuingDate = utcDate(year: 2024, month: 6, day: 15, hour: 10, minute: 30)

        let ticket = SimpleUicRailTicket()
        let issuing = SimpleIssuingDetail()
        issuing.issuingDate = issuingDate
        issuing.issuer = "1080"
        issuing.securePaperTicket = false
        issuing.activated = true
        issuing.specimen = false
        ticket.issuingDetail = issuing

        let res = Reservation()
        res.reference = "12345"
        res.productOwner = "1080"
        res.fromStation = "8000001"
        res.toStation = "8000002"
        res.departureDate = utcDate(year: 2024, month: 6, day: 17, hour: 14, minute: 30) // 2 days + 870 min
        res.arrivalDate = utcDate(year: 2024, month: 6, day: 17, hour: 18, minute: 0) // same day + 1080 min
        ticket.addDocument(.reservation(res))

        let (orig, rt) = try roundTripV3(ticket)

        guard case .reservation(let origR) = orig.documents[0],
              case .reservation(let rtR) = rt.documents[0] else {
            XCTFail("Expected reservation"); return
        }

        XCTAssertNotNil(rtR.departureDate)
        XCTAssertNotNil(rtR.arrivalDate)

        // Verify day component matches
        let cal = Calendar(identifier: .gregorian)
        if let dep = rtR.departureDate {
            let comps = cal.dateComponents([.month, .day], from: dep)
            XCTAssertEqual(comps.month, 6)
            XCTAssertEqual(comps.day, 17)
        }
    }

    // MARK: - V3 OpenTicket Date Round-Trip

    func testV3OpenTicketDatesRoundTrip() throws {
        let issuingDate = utcDate(year: 2024, month: 3, day: 1, hour: 8, minute: 0)

        let ticket = SimpleUicRailTicket()
        let issuing = SimpleIssuingDetail()
        issuing.issuingDate = issuingDate
        issuing.issuer = "1080"
        issuing.securePaperTicket = false
        issuing.activated = true
        issuing.specimen = false
        ticket.issuingDetail = issuing

        let ot = OpenTicket()
        ot.reference = "OT001"
        ot.productOwner = "1080"
        ot.validFrom = utcDate(year: 2024, month: 3, day: 5, hour: 0, minute: 0) // 4 days offset
        ot.validUntil = utcDate(year: 2024, month: 3, day: 10, hour: 23, minute: 59) // 5 more days
        ticket.addDocument(.openTicket(ot))

        let (_, rt) = try roundTripV3(ticket)

        guard case .openTicket(let rtOT) = rt.documents[0] else {
            XCTFail("Expected openTicket"); return
        }

        XCTAssertNotNil(rtOT.validFrom)
        XCTAssertNotNil(rtOT.validUntil)
    }

    // MARK: - V3 Pass Date Round-Trip

    func testV3PassDatesRoundTrip() throws {
        let issuingDate = utcDate(year: 2024, month: 7, day: 1)

        let ticket = SimpleUicRailTicket()
        let issuing = SimpleIssuingDetail()
        issuing.issuingDate = issuingDate
        issuing.issuer = "1080"
        issuing.securePaperTicket = false
        issuing.activated = true
        issuing.specimen = false
        ticket.issuingDetail = issuing

        let pass = Pass()
        pass.reference = "P001"
        pass.productOwner = "1080"
        pass.validFrom = utcDate(year: 2024, month: 7, day: 5)
        pass.validUntil = utcDate(year: 2024, month: 7, day: 20, hour: 23, minute: 59)
        ticket.addDocument(.pass(pass))

        let (_, rt) = try roundTripV3(ticket)

        guard case .pass(let rtP) = rt.documents[0] else {
            XCTFail("Expected pass"); return
        }

        XCTAssertNotNil(rtP.validFrom)
        XCTAssertNotNil(rtP.validUntil)
    }

    // MARK: - V3 Voucher Absolute Date Round-Trip

    func testV3VoucherDatesRoundTrip() throws {
        let issuingDate = utcDate(year: 2024, month: 5, day: 1)

        let ticket = SimpleUicRailTicket()
        let issuing = SimpleIssuingDetail()
        issuing.issuingDate = issuingDate
        issuing.issuer = "1080"
        issuing.securePaperTicket = false
        issuing.activated = true
        issuing.specimen = false
        ticket.issuingDetail = issuing

        let v = VoucherAPI()
        v.reference = "V001"
        v.productOwner = "1080"
        v.validFrom = utcDate(year: 2024, month: 6, day: 1)
        v.validUntil = utcDate(year: 2024, month: 12, day: 31)
        ticket.addDocument(.voucher(v))

        let (_, rt) = try roundTripV3(ticket)

        guard case .voucher(let rtV) = rt.documents[0] else {
            XCTFail("Expected voucher"); return
        }

        XCTAssertNotNil(rtV.validFrom)
        XCTAssertNotNil(rtV.validUntil)

        // Verify year/day round-trip for voucher (absolute dates)
        let cal = Calendar(identifier: .gregorian)
        if let vf = rtV.validFrom {
            let comps = cal.dateComponents([.year, .month, .day], from: vf)
            XCTAssertEqual(comps.year, 2024)
            XCTAssertEqual(comps.month, 6)
            XCTAssertEqual(comps.day, 1)
        }
        if let vu = rtV.validUntil {
            let comps = cal.dateComponents([.year, .month, .day], from: vu)
            XCTAssertEqual(comps.year, 2024)
            XCTAssertEqual(comps.month, 12)
            XCTAssertEqual(comps.day, 31)
        }
    }

    // MARK: - V3 CustomerCard Absolute Date Round-Trip

    func testV3CustomerCardDatesRoundTrip() throws {
        let issuingDate = utcDate(year: 2024, month: 1, day: 15)

        let ticket = SimpleUicRailTicket()
        let issuing = SimpleIssuingDetail()
        issuing.issuingDate = issuingDate
        issuing.issuer = "1080"
        issuing.securePaperTicket = false
        issuing.activated = true
        issuing.specimen = false
        ticket.issuingDetail = issuing

        let cc = CustomerCardAPI()
        cc.reference = "CC001"
        cc.validFrom = utcDate(year: 2024, month: 1, day: 1)
        cc.validUntil = utcDate(year: 2025, month: 1, day: 1)
        ticket.addDocument(.customerCard(cc))

        let (_, rt) = try roundTripV3(ticket)

        guard case .customerCard(let rtCC) = rt.documents[0] else {
            XCTFail("Expected customerCard"); return
        }

        XCTAssertNotNil(rtCC.validFrom)
        XCTAssertNotNil(rtCC.validUntil)
    }

    // MARK: - V3 CounterMark Date Round-Trip

    func testV3CounterMarkDatesRoundTrip() throws {
        let issuingDate = utcDate(year: 2024, month: 4, day: 10)

        let ticket = SimpleUicRailTicket()
        let issuing = SimpleIssuingDetail()
        issuing.issuingDate = issuingDate
        issuing.issuer = "1080"
        issuing.securePaperTicket = false
        issuing.activated = true
        issuing.specimen = false
        ticket.issuingDetail = issuing

        let cm = CounterMarkAPI()
        cm.reference = "CM001"
        cm.productOwner = "1080"
        cm.numberOfCountermark = 1
        cm.totalOfCountermarks = 1
        cm.validFrom = utcDate(year: 2024, month: 4, day: 12, hour: 6, minute: 0)
        cm.validUntil = utcDate(year: 2024, month: 4, day: 14, hour: 23, minute: 59)
        ticket.addDocument(.counterMark(cm))

        let (_, rt) = try roundTripV3(ticket)

        guard case .counterMark(let rtCM) = rt.documents[0] else {
            XCTFail("Expected counterMark"); return
        }

        XCTAssertNotNil(rtCM.validFrom)
        XCTAssertNotNil(rtCM.validUntil)
    }

    // MARK: - V3 ParkingGround Date Round-Trip

    func testV3ParkingGroundDatesRoundTrip() throws {
        let issuingDate = utcDate(year: 2024, month: 8, day: 1)

        let ticket = SimpleUicRailTicket()
        let issuing = SimpleIssuingDetail()
        issuing.issuingDate = issuingDate
        issuing.issuer = "1080"
        issuing.securePaperTicket = false
        issuing.activated = true
        issuing.specimen = false
        ticket.issuingDetail = issuing

        let pg = ParkingGroundAPI()
        pg.reference = "PG001"
        pg.productOwner = "1080"
        pg.fromParkingDate = utcDate(year: 2024, month: 8, day: 5)
        pg.toParkingDate = utcDate(year: 2024, month: 8, day: 10)
        ticket.addDocument(.parkingGround(pg))

        let (_, rt) = try roundTripV3(ticket)

        guard case .parkingGround(let rtPG) = rt.documents[0] else {
            XCTFail("Expected parkingGround"); return
        }

        XCTAssertNotNil(rtPG.fromParkingDate)
        XCTAssertNotNil(rtPG.toParkingDate)
    }

    // MARK: - V3 StationPassage Date Round-Trip

    func testV3StationPassageDatesRoundTrip() throws {
        let issuingDate = utcDate(year: 2024, month: 5, day: 20)

        let ticket = SimpleUicRailTicket()
        let issuing = SimpleIssuingDetail()
        issuing.issuingDate = issuingDate
        issuing.issuer = "1080"
        issuing.securePaperTicket = false
        issuing.activated = true
        issuing.specimen = false
        ticket.issuingDetail = issuing

        let sp = StationPassageAPI()
        sp.reference = "SP001"
        sp.productOwner = "1080"
        sp.validFrom = utcDate(year: 2024, month: 5, day: 22, hour: 8, minute: 0)
        sp.validUntil = utcDate(year: 2024, month: 5, day: 23, hour: 0, minute: 0)
        ticket.addDocument(.stationPassage(sp))

        let (_, rt) = try roundTripV3(ticket)

        guard case .stationPassage(let rtSP) = rt.documents[0] else {
            XCTFail("Expected stationPassage"); return
        }

        XCTAssertNotNil(rtSP.validFrom)
        XCTAssertNotNil(rtSP.validUntil)
    }

    // MARK: - V3 FIPTicket Date Round-Trip

    func testV3FIPTicketDatesRoundTrip() throws {
        let issuingDate = utcDate(year: 2024, month: 9, day: 1)

        let ticket = SimpleUicRailTicket()
        let issuing = SimpleIssuingDetail()
        issuing.issuingDate = issuingDate
        issuing.issuer = "1080"
        issuing.securePaperTicket = false
        issuing.activated = true
        issuing.specimen = false
        ticket.issuingDetail = issuing

        let fip = FIPTicketAPI()
        fip.reference = "FIP001"
        fip.productOwner = "1080"
        fip.numberOfTravelDays = 10
        fip.validFrom = utcDate(year: 2024, month: 9, day: 5)
        fip.validUntil = utcDate(year: 2024, month: 9, day: 15)
        ticket.addDocument(.fipTicket(fip))

        let (_, rt) = try roundTripV3(ticket)

        guard case .fipTicket(let rtFIP) = rt.documents[0] else {
            XCTFail("Expected fipTicket"); return
        }

        XCTAssertNotNil(rtFIP.validFrom)
        XCTAssertNotNil(rtFIP.validUntil)
    }

    // MARK: - V1 Reservation Date Round-Trip

    func testV1ReservationDatesRoundTrip() throws {
        let issuingDate = utcDate(year: 2024, month: 6, day: 15, hour: 10, minute: 30)

        let ticket = SimpleUicRailTicket()
        let issuing = SimpleIssuingDetail()
        issuing.issuingDate = issuingDate
        issuing.issuer = "1080"
        issuing.securePaperTicket = false
        issuing.activated = true
        issuing.specimen = false
        ticket.issuingDetail = issuing

        let res = Reservation()
        res.reference = "12345"
        res.productOwner = "1080"
        res.fromStation = "8000001"
        res.toStation = "8000002"
        res.departureDate = utcDate(year: 2024, month: 6, day: 17, hour: 14, minute: 30)
        res.arrivalDate = utcDate(year: 2024, month: 6, day: 17, hour: 18, minute: 0)
        ticket.addDocument(.reservation(res))

        let (_, rt) = try roundTripV1(ticket)

        guard case .reservation(let rtR) = rt.documents[0] else {
            XCTFail("Expected reservation"); return
        }

        XCTAssertNotNil(rtR.departureDate)
        XCTAssertNotNil(rtR.arrivalDate)
    }

    // MARK: - V2 Reservation Date Round-Trip

    func testV2ReservationDatesRoundTrip() throws {
        let issuingDate = utcDate(year: 2024, month: 6, day: 15, hour: 10, minute: 30)

        let ticket = SimpleUicRailTicket()
        let issuing = SimpleIssuingDetail()
        issuing.issuingDate = issuingDate
        issuing.issuer = "1080"
        issuing.securePaperTicket = false
        issuing.activated = true
        issuing.specimen = false
        ticket.issuingDetail = issuing

        let res = Reservation()
        res.reference = "12345"
        res.productOwner = "1080"
        res.fromStation = "8000001"
        res.toStation = "8000002"
        res.departureDate = utcDate(year: 2024, month: 6, day: 17, hour: 14, minute: 30)
        res.arrivalDate = utcDate(year: 2024, month: 6, day: 17, hour: 18, minute: 0)
        ticket.addDocument(.reservation(res))

        let (_, rt) = try roundTripV2(ticket)

        guard case .reservation(let rtR) = rt.documents[0] else {
            XCTFail("Expected reservation"); return
        }

        XCTAssertNotNil(rtR.departureDate)
        XCTAssertNotNil(rtR.arrivalDate)
    }

    // MARK: - V1 OpenTicket Date Round-Trip

    func testV1OpenTicketDatesRoundTrip() throws {
        let issuingDate = utcDate(year: 2024, month: 3, day: 1)

        let ticket = SimpleUicRailTicket()
        let issuing = SimpleIssuingDetail()
        issuing.issuingDate = issuingDate
        issuing.issuer = "1080"
        issuing.securePaperTicket = false
        issuing.activated = true
        issuing.specimen = false
        ticket.issuingDetail = issuing

        let ot = OpenTicket()
        ot.reference = "OT001"
        ot.productOwner = "1080"
        ot.validFrom = utcDate(year: 2024, month: 3, day: 5)
        ot.validUntil = utcDate(year: 2024, month: 3, day: 10, hour: 23, minute: 59)
        ticket.addDocument(.openTicket(ot))

        let (_, rt) = try roundTripV1(ticket)

        guard case .openTicket(let rtOT) = rt.documents[0] else {
            XCTFail("Expected openTicket"); return
        }

        XCTAssertNotNil(rtOT.validFrom)
        XCTAssertNotNil(rtOT.validUntil)
    }

    // MARK: - V2 OpenTicket Date Round-Trip

    func testV2OpenTicketDatesRoundTrip() throws {
        let issuingDate = utcDate(year: 2024, month: 3, day: 1)

        let ticket = SimpleUicRailTicket()
        let issuing = SimpleIssuingDetail()
        issuing.issuingDate = issuingDate
        issuing.issuer = "1080"
        issuing.securePaperTicket = false
        issuing.activated = true
        issuing.specimen = false
        ticket.issuingDetail = issuing

        let ot = OpenTicket()
        ot.reference = "OT001"
        ot.productOwner = "1080"
        ot.validFrom = utcDate(year: 2024, month: 3, day: 5)
        ot.validUntil = utcDate(year: 2024, month: 3, day: 10, hour: 23, minute: 59)
        ticket.addDocument(.openTicket(ot))

        let (_, rt) = try roundTripV2(ticket)

        guard case .openTicket(let rtOT) = rt.documents[0] else {
            XCTFail("Expected openTicket"); return
        }

        XCTAssertNotNil(rtOT.validFrom)
        XCTAssertNotNil(rtOT.validUntil)
    }

    // MARK: - Issuing Date Round-Trip (UTC consistency)

    func testV3IssuingDateUTCRoundTrip() throws {
        let issuingDate = utcDate(year: 2024, month: 12, day: 31, hour: 23, minute: 30) // near midnight

        let ticket = SimpleUicRailTicket()
        let issuing = SimpleIssuingDetail()
        issuing.issuingDate = issuingDate
        issuing.issuer = "1080"
        issuing.securePaperTicket = false
        issuing.activated = true
        issuing.specimen = false
        ticket.issuingDetail = issuing

        // Need at least one document for a valid ticket
        let ot = OpenTicket()
        ot.reference = "T001"
        ot.productOwner = "1080"
        ticket.addDocument(.openTicket(ot))

        let (_, rt) = try roundTripV3(ticket)

        let rtIssuing = try XCTUnwrap(rt.issuingDetail)
        XCTAssertNotNil(rtIssuing.issuingDate)

        // After the UTC fix, the day-of-year should encode/decode correctly
        // even for dates near midnight UTC
        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(identifier: "UTC")!
        if let rtDate = rtIssuing.issuingDate {
            let origDay = utcCal.ordinality(of: .day, in: .year, for: issuingDate)
            let rtDay = utcCal.ordinality(of: .day, in: .year, for: rtDate)
            XCTAssertEqual(origDay, rtDay, "Day-of-year should match after UTC round-trip")
        }
    }

    func testV1IssuingDateUTCRoundTrip() throws {
        let issuingDate = utcDate(year: 2024, month: 12, day: 31, hour: 23, minute: 30)

        let ticket = SimpleUicRailTicket()
        let issuing = SimpleIssuingDetail()
        issuing.issuingDate = issuingDate
        issuing.issuer = "1080"
        issuing.securePaperTicket = false
        issuing.activated = true
        issuing.specimen = false
        ticket.issuingDetail = issuing

        let ot = OpenTicket()
        ot.reference = "T001"
        ot.productOwner = "1080"
        ticket.addDocument(.openTicket(ot))

        let (_, rt) = try roundTripV1(ticket)

        let rtIssuing = try XCTUnwrap(rt.issuingDetail)
        XCTAssertNotNil(rtIssuing.issuingDate)

        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(identifier: "UTC")!
        if let rtDate = rtIssuing.issuingDate {
            let origDay = utcCal.ordinality(of: .day, in: .year, for: issuingDate)
            let rtDay = utcCal.ordinality(of: .day, in: .year, for: rtDate)
            XCTAssertEqual(origDay, rtDay, "Day-of-year should match after UTC round-trip")
        }
    }

    func testV2IssuingDateUTCRoundTrip() throws {
        let issuingDate = utcDate(year: 2024, month: 12, day: 31, hour: 23, minute: 30)

        let ticket = SimpleUicRailTicket()
        let issuing = SimpleIssuingDetail()
        issuing.issuingDate = issuingDate
        issuing.issuer = "1080"
        issuing.securePaperTicket = false
        issuing.activated = true
        issuing.specimen = false
        ticket.issuingDetail = issuing

        let ot = OpenTicket()
        ot.reference = "T001"
        ot.productOwner = "1080"
        ticket.addDocument(.openTicket(ot))

        let (_, rt) = try roundTripV2(ticket)

        let rtIssuing = try XCTUnwrap(rt.issuingDetail)
        XCTAssertNotNil(rtIssuing.issuingDate)

        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(identifier: "UTC")!
        if let rtDate = rtIssuing.issuingDate {
            let origDay = utcCal.ordinality(of: .day, in: .year, for: issuingDate)
            let rtDay = utcCal.ordinality(of: .day, in: .year, for: rtDate)
            XCTAssertEqual(origDay, rtDay, "Day-of-year should match after UTC round-trip")
        }
    }

    // MARK: - Existing All-Elements Date Population Tests

    func testV3AllElementsReservationHasDates() throws {
        let ticket = try decodeV3AllElements()

        guard case .reservation(let res) = ticket.documents.first(where: {
            if case .reservation = $0 { return true }; return false
        }) else {
            XCTFail("No reservation in all-elements V3"); return
        }

        XCTAssertNotNil(res.departureDate, "V3 reservation should have departureDate populated")
        XCTAssertNotNil(res.arrivalDate, "V3 reservation should have arrivalDate populated")
    }

    func testV3AllElementsOpenTicketHasDates() throws {
        let ticket = try decodeV3AllElements()

        guard case .openTicket(let ot) = ticket.documents.first(where: {
            if case .openTicket = $0 { return true }; return false
        }) else {
            XCTFail("No openTicket in all-elements V3"); return
        }

        XCTAssertNotNil(ot.validFrom, "V3 openTicket should have validFrom populated")
        XCTAssertNotNil(ot.validUntil, "V3 openTicket should have validUntil populated")
    }

    func testV1AllElementsReservationHasDates() throws {
        let ticket = try decodeV1AllElements()

        guard case .reservation(let res) = ticket.documents.first(where: {
            if case .reservation = $0 { return true }; return false
        }) else {
            XCTFail("No reservation in all-elements V1"); return
        }

        XCTAssertNotNil(res.departureDate, "V1 reservation should have departureDate populated")
        XCTAssertNotNil(res.arrivalDate, "V1 reservation should have arrivalDate populated")
    }

    func testV2AllElementsReservationHasDates() throws {
        let ticket = try decodeV2AllElements()

        guard case .reservation(let res) = ticket.documents.first(where: {
            if case .reservation = $0 { return true }; return false
        }) else {
            XCTFail("No reservation in all-elements V2"); return
        }

        XCTAssertNotNil(res.departureDate, "V2 reservation should have departureDate populated")
        XCTAssertNotNil(res.arrivalDate, "V2 reservation should have arrivalDate populated")
    }

    // MARK: - Round-Trip Helpers

    private func roundTripV3(_ ticket: SimpleUicRailTicket) throws -> (original: SimpleUicRailTicket, roundTripped: SimpleUicRailTicket) {
        let asn = UicRailTicketCoder.encodeV3(ticket)
        let encoded = try FCBVersionEncoder.encode(ticket: asn)
        var decoder = UPERDecoder(data: encoded)
        let decoded = try UicRailTicketData(from: &decoder)
        let roundTripped = UicRailTicketCoder.decode(decoded)
        return (ticket, roundTripped)
    }

    private func roundTripV1(_ ticket: SimpleUicRailTicket) throws -> (original: SimpleUicRailTicket, roundTripped: SimpleUicRailTicket) {
        let asn = UicRailTicketCoder.encodeV1(ticket)
        let encoded = try FCBVersionEncoder.encode(ticketV1: asn)
        var decoder = UPERDecoder(data: encoded)
        let decoded = try UicRailTicketDataV1(from: &decoder)
        let roundTripped = UicRailTicketCoder.decode(decoded)
        return (ticket, roundTripped)
    }

    private func roundTripV2(_ ticket: SimpleUicRailTicket) throws -> (original: SimpleUicRailTicket, roundTripped: SimpleUicRailTicket) {
        let asn = UicRailTicketCoder.encodeV2(ticket)
        let encoded = try FCBVersionEncoder.encode(ticketV2: asn)
        var decoder = UPERDecoder(data: encoded)
        let decoded = try UicRailTicketDataV2(from: &decoder)
        let roundTripped = UicRailTicketCoder.decode(decoded)
        return (ticket, roundTripped)
    }

    // MARK: - All-Elements Decode Helpers

    private func decodeV3AllElements() throws -> SimpleUicRailTicket {
        let data = TestTicketsV3.allElementsData
        var decoder = UPERDecoder(data: data)
        let asn = try UicRailTicketData(from: &decoder)
        return UicRailTicketCoder.decode(asn)
    }

    private func decodeV1AllElements() throws -> SimpleUicRailTicket {
        let data = TestTicketsV1.allElementsData
        var decoder = UPERDecoder(data: data)
        let asn = try UicRailTicketDataV1(from: &decoder)
        return UicRailTicketCoder.decode(asn)
    }

    private func decodeV2AllElements() throws -> SimpleUicRailTicket {
        let data = TestTicketsV2.allElementsData
        var decoder = UPERDecoder(data: data)
        let asn = try UicRailTicketDataV2(from: &decoder)
        return UicRailTicketCoder.decode(asn)
    }
}
