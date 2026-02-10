import XCTest
@testable import UICBarcodeKit

/// All Elements V3 Tests
/// Translated from Java: AllElementsTestTicketV3.java
/// Comprehensive test that verifies all FCB elements can be decoded
final class AllElementsTestsV3: XCTestCase {

    // MARK: - Complete Decode Test

    /// Test decoding All Elements V3 ticket
    /// This is the most comprehensive test covering all ticket types and fields
    func testAllElementsDecoding() throws {
        let data = TestTicketsV3.allElementsData
        print("AllElements data: \(data.count) bytes = \(data.count * 8) bits")

        var decoder = UPERDecoder(data: data)

        // Manually trace to find which document fails
        let uicExt = try decoder.decodeBit()
        let uicPresence = try decoder.decodePresenceBitmap(count: 4)
        print("pos \(decoder.position): UicRailTicketData ext=\(uicExt) presence=\(uicPresence)")

        let issuing = try IssuingData(from: &decoder)
        print("pos \(decoder.position): IssuingData done (year=\(issuing.issuingYear))")

        if uicPresence[0] {
            do {
                _ = try TravelerData(from: &decoder)
                print("pos \(decoder.position): TravelerData done")
            } catch {
                print("pos \(decoder.position): TravelerData FAILED: \(error)")
                throw error
            }
        }

        if uicPresence[1] {
            let docCount = try decoder.decodeLengthDeterminant()
            print("pos \(decoder.position): TransportDocument count=\(docCount)")

            for i in 0..<docCount {
                let startPos = decoder.position
                do {
                    // Trace DocumentData internals
                    let docExt = try decoder.decodeBit()
                    let docPresence = try decoder.decodePresenceBitmap(count: 1)
                    print("pos \(decoder.position): Doc[\(i)] ext=\(docExt) hasToken=\(docPresence[0])")

                    if docPresence[0] {
                        _ = try TokenType(from: &decoder)
                        print("pos \(decoder.position): Doc[\(i)] token done")
                    }

                    // CHOICE index for ticket
                    let choiceIdx = try decoder.decodeChoiceIndex(rootCount: 12, hasExtensionMarker: true)
                    print("pos \(decoder.position): Doc[\(i)] choiceIdx=\(choiceIdx)")

                    let ticketStartPos = decoder.position
                    switch choiceIdx {
                    case 0: _ = try ReservationData(from: &decoder)
                    case 1: _ = try CarCarriageReservationData(from: &decoder)
                    case 2: _ = try OpenTicketData(from: &decoder)
                    case 3: _ = try PassData(from: &decoder)
                    case 4: _ = try VoucherData(from: &decoder)
                    case 5: _ = try CustomerCardData(from: &decoder)
                    case 6: _ = try CountermarkData(from: &decoder)
                    case 7: _ = try ParkingGroundData(from: &decoder)
                    case 8: _ = try FIPTicketData(from: &decoder)
                    case 9: _ = try StationPassageData(from: &decoder)
                    case 10: _ = try ExtensionData(from: &decoder)
                    case 11: _ = try DelayConfirmation(from: &decoder)
                    default: print("Unknown choice index: \(choiceIdx)")
                    }
                    print("pos \(decoder.position): Doc[\(i)] ticket done (was \(ticketStartPos))")

                    // Handle DocumentData extensions
                    if docExt {
                        let numExt = try decoder.decodeBitmaskLength()
                        let extPresence = try decoder.decodePresenceBitmap(count: numExt)
                        for j in 0..<numExt where extPresence[j] {
                            try decoder.skipOpenType()
                        }
                    }

                    print("pos \(decoder.position): Doc[\(i)] done (was \(startPos))")
                } catch {
                    print("pos \(decoder.position): Doc[\(i)] FAILED at \(startPos): \(error)")
                    throw error
                }
            }
        }

        if uicPresence[2] {
            let startPos = decoder.position
            _ = try ControlData(from: &decoder)
            print("pos \(decoder.position): ControlData done (was \(startPos))")
        }

        if uicPresence[3] {
            let startPos = decoder.position
            let extCount = try decoder.decodeLengthDeterminant()
            for i in 0..<extCount {
                _ = try ExtensionData(from: &decoder)
                print("pos \(decoder.position): Extension[\(i)] done")
            }
            print("pos \(decoder.position): Extensions done (was \(startPos))")
        }

        print("pos \(decoder.position): ALL DONE / \(data.count * 8) bits")

        // Also test full decode path
        var decoder2 = UPERDecoder(data: data)
        let ticket = try UicRailTicketData(from: &decoder2)

        XCTAssertNotNil(ticket.issuingDetail)
        XCTAssertNotNil(ticket.travelerDetail)
        XCTAssertNotNil(ticket.travelerDetail?.traveler)
        XCTAssertNotNil(ticket.transportDocument)
        XCTAssertGreaterThan(ticket.transportDocument?.count ?? 0, 0)
        XCTAssertNotNil(ticket.controlDetail)
        XCTAssertNotNil(ticket.extensionData)
    }

    // MARK: - IssuingData Complete Tests

    /// Test all IssuingData fields
    func testIssuingDataCompleteFields() {
        var issuing = IssuingData()
        issuing.securityProviderNum = 1
        issuing.securityProviderIA5 = "1"
        issuing.issuerNum = 32000
        issuing.issuerIA5 = "1"
        issuing.issuingYear = 2018
        issuing.issuingDay = 1
        issuing.issuingTime = 600
        issuing.issuerName = "name"
        issuing.specimen = true
        issuing.securePaperTicket = false
        issuing.activated = true
        issuing.currency = "SRF"
        issuing.currencyFract = 3
        issuing.issuerPNR = "issuerTestPNR"

        // Extension fields
        issuing.issuedOnTrainNum = 123
        issuing.issuedOnTrainIA5 = "123"
        issuing.issuedOnLine = 12

        XCTAssertEqual(issuing.securityProviderNum, 1)
        XCTAssertEqual(issuing.securityProviderIA5, "1")
        XCTAssertEqual(issuing.issuerNum, 32000)
        XCTAssertEqual(issuing.issuerIA5, "1")
        XCTAssertEqual(issuing.issuingYear, 2018)
        XCTAssertEqual(issuing.issuingDay, 1)
        XCTAssertEqual(issuing.issuingTime, 600)
        XCTAssertEqual(issuing.issuerName, "name")
        XCTAssertEqual(issuing.specimen, true)
        XCTAssertEqual(issuing.securePaperTicket, false)
        XCTAssertEqual(issuing.activated, true)
        XCTAssertEqual(issuing.currency, "SRF")
        XCTAssertEqual(issuing.currencyFract, 3)
        XCTAssertEqual(issuing.issuerPNR, "issuerTestPNR")
        XCTAssertEqual(issuing.issuedOnTrainNum, 123)
        XCTAssertEqual(issuing.issuedOnTrainIA5, "123")
        XCTAssertEqual(issuing.issuedOnLine, 12)
    }

    // MARK: - TravelerData Complete Tests

    /// Test all TravelerType fields
    func testTravelerTypeCompleteFields() {
        var traveler = TravelerType()
        traveler.firstName = "John"
        traveler.secondName = "Little"
        traveler.lastName = "Dow"
        traveler.idCard = "12345"
        traveler.passportId = "JDTS"
        traveler.title = "PhD"
        traveler.gender = .male
        traveler.customerIdIA5 = "DZE5gT"
        traveler.customerIdNum = 12345
        traveler.yearOfBirth = 1901
        traveler.monthOfBirth = 12
        traveler.dayOfBirth = 31
        traveler.ticketHolder = true
        traveler.passengerType = .senior
        traveler.passengerWithReducedMobility = false
        traveler.countryOfResidence = 101
        traveler.countryOfPassport = 102
        traveler.countryOfIdCard = 103

        XCTAssertEqual(traveler.firstName, "John")
        XCTAssertEqual(traveler.secondName, "Little")
        XCTAssertEqual(traveler.lastName, "Dow")
        XCTAssertEqual(traveler.idCard, "12345")
        XCTAssertEqual(traveler.passportId, "JDTS")
        XCTAssertEqual(traveler.title, "PhD")
        XCTAssertEqual(traveler.gender, .male)
        XCTAssertEqual(traveler.customerIdIA5, "DZE5gT")
        XCTAssertEqual(traveler.customerIdNum, 12345)
        XCTAssertEqual(traveler.yearOfBirth, 1901)
        XCTAssertEqual(traveler.monthOfBirth, 12)
        XCTAssertEqual(traveler.dayOfBirth, 31)
        XCTAssertEqual(traveler.ticketHolder, true)
        XCTAssertEqual(traveler.passengerType, .senior)
        XCTAssertEqual(traveler.passengerWithReducedMobility, false)
        XCTAssertEqual(traveler.countryOfResidence, 101)
        XCTAssertEqual(traveler.countryOfPassport, 102)
        XCTAssertEqual(traveler.countryOfIdCard, 103)
    }

    // MARK: - GeoCoordinateType Complete Tests

    /// Test all GeoCoordinateType fields
    func testGeoCoordinateTypeCompleteFields() {
        var coord = GeoCoordinateType()
        coord.geoUnit = .microDegree
        coord.coordinateSystem = .wgs84
        coord.hemisphereLongitude = .east
        coord.hemisphereLatitude = .north
        coord.longitude = 12345
        coord.latitude = 56789
        coord.accuracy = .microDegree

        XCTAssertEqual(coord.geoUnit, .microDegree)
        XCTAssertEqual(coord.coordinateSystem, .wgs84)
        XCTAssertEqual(coord.hemisphereLongitude, .east)
        XCTAssertEqual(coord.hemisphereLatitude, .north)
        XCTAssertEqual(coord.longitude, 12345)
        XCTAssertEqual(coord.latitude, 56789)
        XCTAssertEqual(coord.accuracy, .microDegree)
    }

    // MARK: - All Enum Tests

    /// Test GenderType enum
    func testGenderTypeEnum() {
        XCTAssertEqual(GenderType.unspecified.rawValue, 0)
        XCTAssertEqual(GenderType.female.rawValue, 1)
        XCTAssertEqual(GenderType.male.rawValue, 2)
        XCTAssertEqual(GenderType.other.rawValue, 3)
    }

    /// Test PassengerType enum
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

    /// Test TravelClassType enum with all values
    func testTravelClassTypeEnumComplete() {
        XCTAssertEqual(TravelClassType.notApplicable.rawValue, 0)
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

    /// Test GeoUnitType enum
    func testGeoUnitTypeEnum() {
        XCTAssertEqual(GeoUnitType.microDegree.rawValue, 0)
        XCTAssertEqual(GeoUnitType.tenthmilliDegree.rawValue, 1)
        XCTAssertEqual(GeoUnitType.milliDegree.rawValue, 2)
        XCTAssertEqual(GeoUnitType.centiDegree.rawValue, 3)
        XCTAssertEqual(GeoUnitType.deciDegree.rawValue, 4)
    }

    /// Test CodeTableType enum
    func testCodeTableTypeEnum() {
        XCTAssertEqual(CodeTableType.stationUIC.rawValue, 0)
        XCTAssertEqual(CodeTableType.stationUICReservation.rawValue, 1)
        XCTAssertEqual(CodeTableType.stationERA.rawValue, 2)
        XCTAssertEqual(CodeTableType.localCarrierStationCodeTable.rawValue, 3)
        XCTAssertEqual(CodeTableType.proprietaryIssuerStationCodeTable.rawValue, 4)
    }

    /// Test HemisphereTypes
    func testHemisphereTypes() {
        XCTAssertEqual(HemisphereLatitudeType.north.rawValue, 0)
        XCTAssertEqual(HemisphereLatitudeType.south.rawValue, 1)
        XCTAssertEqual(HemisphereLongitudeType.east.rawValue, 0)
        XCTAssertEqual(HemisphereLongitudeType.west.rawValue, 1)
    }

    /// Test RoofRackType enum (matches Java RoofRackType.java)
    func testRoofRackTypeEnum() {
        XCTAssertEqual(RoofRackType.norack.rawValue, 0)
        XCTAssertEqual(RoofRackType.roofRailing.rawValue, 1)
        XCTAssertEqual(RoofRackType.luggageRack.rawValue, 2)
        XCTAssertEqual(RoofRackType.skiRack.rawValue, 3)
        XCTAssertEqual(RoofRackType.boxRack.rawValue, 4)
        XCTAssertEqual(RoofRackType.rackWithOneBox.rawValue, 5)
        XCTAssertEqual(RoofRackType.rackWithTwoBoxes.rawValue, 6)
        XCTAssertEqual(RoofRackType.bicycleRack.rawValue, 7)
        XCTAssertEqual(RoofRackType.otherRack.rawValue, 8)
    }

    /// Test LoadingDeckType enum (matches Java LoadingDeckType.java)
    func testLoadingDeckTypeEnum() {
        XCTAssertEqual(LoadingDeckType.unspecified.rawValue, 0)
        XCTAssertEqual(LoadingDeckType.upper.rawValue, 1)
        XCTAssertEqual(LoadingDeckType.lower.rawValue, 2)
    }

    /// Test BoardingOrArrivalType enum
    func testBoardingOrArrivalTypeEnum() {
        XCTAssertEqual(BoardingOrArrivalType.boarding.rawValue, 0)
        XCTAssertEqual(BoardingOrArrivalType.arrival.rawValue, 1)
    }

    // MARK: - Regional Validity Tests

    /// Test RegionalValidityType with zones
    func testRegionalValidityWithZones() {
        var zone = ZoneType()
        zone.zoneId = [100, 200, 300]
        zone.carrierNum = 1080
        zone.entryStationNum = 8000001
        zone.terminatingStationNum = 8000002

        XCTAssertEqual(zone.zoneId?.count, 3)
        XCTAssertEqual(zone.zoneId?[0], 100)
        XCTAssertEqual(zone.carrierNum, 1080)
    }

    /// Test RegionalValidityType with lines
    func testRegionalValidityWithLines() {
        var line = LineType()
        line.lineId = [1, 2, 3]
        line.carrierNum = 1080
        line.entryStationNum = 8000001

        XCTAssertEqual(line.lineId?.count, 3)
        XCTAssertEqual(line.carrierNum, 1080)
    }

    /// Test ViaStationType
    func testViaStationType() {
        var via = ViaStationType()
        via.stationNum = 8000001
        via.border = true
        via.carriersNum = [1080, 1181]

        XCTAssertEqual(via.stationNum, 8000001)
        XCTAssertEqual(via.border, true)
        XCTAssertEqual(via.carriersNum?.count, 2)
    }

    /// Test TrainLinkType
    func testTrainLinkType() {
        var trainLink = TrainLinkType()
        trainLink.trainNum = 123
        trainLink.trainIA5 = "ICE123"
        trainLink.travelDate = 0
        trainLink.departureTime = 480
        trainLink.fromStationNum = 8000001
        trainLink.toStationNum = 8000002

        XCTAssertEqual(trainLink.trainNum, 123)
        XCTAssertEqual(trainLink.trainIA5, "ICE123")
        XCTAssertEqual(trainLink.travelDate, 0)
        XCTAssertEqual(trainLink.departureTime, 480)
    }

    // MARK: - Validity Period Tests

    /// Test ValidityPeriodDetailType
    func testValidityPeriodDetailType() {
        var period = ValidityPeriodType()
        period.validFromDay = 0
        period.validFromTime = 0
        period.validUntilDay = 30
        period.validUntilTime = 1439

        XCTAssertEqual(period.validFromDay, 0)
        XCTAssertEqual(period.validFromTime, 0)
        XCTAssertEqual(period.validUntilDay, 30)
        XCTAssertEqual(period.validUntilTime, 1439)
    }

    /// Test TimeRangeType
    func testTimeRangeType() {
        let range = TimeRangeType(fromTime: 480, untilTime: 720)

        XCTAssertEqual(range.fromTime, 480)  // 08:00
        XCTAssertEqual(range.untilTime, 720) // 12:00
    }

    // MARK: - Luggage Tests

    /// Test LuggageRestrictionType
    func testLuggageRestrictionType() {
        var luggage = LuggageRestrictionType()
        luggage.maxHandLuggagePieces = 2
        luggage.maxNonHandLuggagePieces = 1

        XCTAssertEqual(luggage.maxHandLuggagePieces, 2)
        XCTAssertEqual(luggage.maxNonHandLuggagePieces, 1)
    }

    /// Test RegisteredLuggageType
    func testRegisteredLuggageType() {
        var registered = RegisteredLuggageType()
        registered.registrationId = "LUG123"
        registered.maxWeight = 30
        registered.maxSize = 150

        XCTAssertEqual(registered.registrationId, "LUG123")
        XCTAssertEqual(registered.maxWeight, 30)
        XCTAssertEqual(registered.maxSize, 150)
    }
}
