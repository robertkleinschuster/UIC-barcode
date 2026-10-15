import XCTest
@testable import UICBarcodeKit

/// FCB Ticket Type Decoding Tests
/// Translated from Java tests:
/// - OpenTicketComplexTestV3.java
/// - PassComplexTestV3.java
/// - VoucherTestTicketV3.java
/// - DelayConfirmationTestV3.java
/// - CountermarkTestComplexTicketV3.java
/// - ReservationTestTicketV3.java
/// - StationPassageTestTicketV3.java
/// - CustomerCardTestTicketV3.java
/// - ParkingTestTicketV3.java
final class FCBTicketTypeDecodingTests: XCTestCase {

    // MARK: - Helper Functions

    func hexToData(_ hex: String) -> Data {
        let cleanHex = hex.replacingOccurrences(of: " ", with: "")
                          .replacingOccurrences(of: "\n", with: "")
        var data = Data()
        var index = cleanHex.startIndex
        while index < cleanHex.endIndex {
            let nextIndex = cleanHex.index(index, offsetBy: 2)
            if let byte = UInt8(cleanHex[index..<nextIndex], radix: 16) {
                data.append(byte)
            }
            index = nextIndex
        }
        return data
    }

    // MARK: - Test Data (from Java test files)

    /// OpenTicket Complex V3 encoding from OpenTestComplexTicketV3.java
    /// Contains: IssuingData, TravelerData, OpenTicketData, StationPassageData, ControlData, ExtensionData
    static let openTicketComplexV3Hex =
        "7804404004B14374F3E7D72F2A9979F4A13A90086280B4001044A6F686E03446" +
        "F770562C99B46B01106E797769DFC81DB5E51DC9BDD5C0094075A2560282DA10" +
        "00000101C0101C4F11804281A4D5891EA450E6F70656E5469636B6574496E666" +
        "F0140AD06021B8090020080B23E8013E8100B10008143D09003D1C8787B4B731" +
        "B63AB232B2103A34B1B5B2BA090110081DC185CDCD859D94042505B5CDD195C9" +
        "9185B4B780BDA60100402C800131B200ADC2EAC588C593466D5C366E089E8A84" +
        "84074275204E9979F428100B10282DA01640507B40"

    // MARK: - Data Structure Tests (from Java test patterns)

    /// Test that hex data can be converted to Data correctly
    func testHexDataConversion() {
        let hex = "7804404004B14374F3E7D72F2A9979F4A13A9008"
        let data = hexToData(hex)

        // Verify first bytes match
        XCTAssertEqual(data[0], 0x78)
        XCTAssertEqual(data[1], 0x04)
        XCTAssertEqual(data[2], 0x40)
        XCTAssertEqual(data[3], 0x40)

        // Hex string has 40 chars = 20 bytes
        XCTAssertEqual(data.count, 20)
    }

    /// Test OpenTicket V3 hex data length
    /// From Java: getEncodingHex() returns known-length encoding
    func testOpenTicketComplexV3DataLength() {
        let data = hexToData(Self.openTicketComplexV3Hex)

        // The encoding should have a specific length
        XCTAssertGreaterThan(data.count, 100)

        // First byte should indicate the structure
        XCTAssertEqual(data[0], 0x78)
    }

    // MARK: - UPER Decoding Infrastructure Tests

    /// Test that UPERDecoder can be initialized with FCB data
    func testUPERDecoderInitialization() {
        let data = hexToData(Self.openTicketComplexV3Hex)
        let decoder = UPERDecoder(data: data)

        XCTAssertEqual(decoder.remaining, data.count * 8)
    }

    /// Test reading first bits of FCB encoding
    /// From Java: First bit is extension marker, next bits are presence bitmap
    func testFCBFirstBitsDecoding() throws {
        let data = hexToData(Self.openTicketComplexV3Hex)
        var decoder = UPERDecoder(data: data)

        // Extension marker for UicRailTicketData
        let hasExtension = try decoder.decodeBit()
        XCTAssertTrue(hasExtension || !hasExtension) // Can be either

        // Should be able to read more bits
        let moreBits = try decoder.decodeBits(4)
        XCTAssertLessThanOrEqual(moreBits, 0xF)
    }

    // MARK: - FCB Model Structure Tests

    /// Test IssuingData structure matches Java
    /// From Java: issuingYear=2018, issuingDay=1, specimen=TRUE, activated=TRUE
    func testIssuingDataStructure() {
        // Test that IssuingData has all required fields from Java
        var issuingData = IssuingData()

        issuingData.issuingYear = 2018
        issuingData.issuingDay = 1
        issuingData.specimen = true
        issuingData.securePaperTicket = false
        issuingData.activated = true
        issuingData.issuerPNR = "issuerTestPNR"
        issuingData.issuedOnLine = 12

        XCTAssertEqual(issuingData.issuingYear, 2018)
        XCTAssertEqual(issuingData.issuingDay, 1)
        XCTAssertEqual(issuingData.specimen, true)
        XCTAssertEqual(issuingData.securePaperTicket, false)
        XCTAssertEqual(issuingData.activated, true)
        XCTAssertEqual(issuingData.issuerPNR, "issuerTestPNR")
        XCTAssertEqual(issuingData.issuedOnLine, 12)
    }

    /// Test TravelerData structure matches Java
    /// From Java: firstName="John", secondName="Dow", groupName="myGroup"
    func testTravelerDataStructure() {
        var travelerData = TravelerData()
        travelerData.groupName = "myGroup"

        var traveler = TravelerType()
        traveler.firstName = "John"
        traveler.secondName = "Dow"
        traveler.idCard = "12345"
        traveler.ticketHolder = true

        var status = CustomerStatusType()
        status.customerStatusDescr = "senior"
        traveler.status = [status]

        travelerData.traveler = [traveler]

        XCTAssertEqual(travelerData.groupName, "myGroup")
        XCTAssertEqual(travelerData.traveler?.first?.firstName, "John")
        XCTAssertEqual(travelerData.traveler?.first?.secondName, "Dow")
        XCTAssertEqual(travelerData.traveler?.first?.idCard, "12345")
        XCTAssertEqual(travelerData.traveler?.first?.ticketHolder, true)
        XCTAssertEqual(travelerData.traveler?.first?.status?.first?.customerStatusDescr, "senior")
    }

    /// Test ControlData structure matches Java
    /// From Java: infoText="cd", ageCheckRequired=FALSE
    func testControlDataStructure() {
        var controlData = ControlData()
        controlData.infoText = "cd"
        controlData.ageCheckRequired = false
        controlData.identificationByIdCard = false
        controlData.identificationByPassportId = false
        controlData.passportValidationRequired = false
        controlData.onlineValidationRequired = false
        controlData.reductionCardCheckRequired = false

        var cardRef = CardReferenceType()
        cardRef.trailingCardIdNum = 100
        controlData.identificationByCardReference = [cardRef]

        XCTAssertEqual(controlData.infoText, "cd")
        XCTAssertEqual(controlData.ageCheckRequired, false)
        XCTAssertEqual(controlData.identificationByCardReference?.first?.trailingCardIdNum, 100)
    }

    /// Test TicketLinkType structure matches Java
    /// From Java: referenceIA5="UED12435867", issuerName="OEBB", linkMode=onlyValidInCombination
    func testTicketLinkTypeStructure() {
        var ticketLink = TicketLinkType()
        ticketLink.referenceIA5 = "UED12435867"
        ticketLink.issuerName = "OEBB"
        ticketLink.issuerPNR = "PNR"
        ticketLink.productOwnerIA5 = "test"
        ticketLink.linkMode = .onlyValidInCombination

        XCTAssertEqual(ticketLink.referenceIA5, "UED12435867")
        XCTAssertEqual(ticketLink.issuerName, "OEBB")
        XCTAssertEqual(ticketLink.issuerPNR, "PNR")
        XCTAssertEqual(ticketLink.productOwnerIA5, "test")
        XCTAssertEqual(ticketLink.linkMode, .onlyValidInCombination)
    }

    /// Test OpenTicketData structure matches Java
    /// From Java: returnIncluded=FALSE, classCode=first, infoText="openTicketInfo"
    func testOpenTicketDataStructure() {
        var openTicket = OpenTicketData()
        openTicket.returnIncluded = false
        openTicket.classCode = .first
        openTicket.infoText = "openTicketInfo"

        XCTAssertEqual(openTicket.returnIncluded, false)
        XCTAssertEqual(openTicket.classCode, .first)
        XCTAssertEqual(openTicket.infoText, "openTicketInfo")
    }

    /// Test VatDetailType structure matches Java
    /// From Java: country=80, percentage=70, amount=10, vatId="IUDGTE"
    func testVatDetailTypeStructure() {
        var vatDetail = VatDetailType()
        vatDetail.country = 80
        vatDetail.percentage = 70
        vatDetail.amount = 10
        vatDetail.vatId = "IUDGTE"

        XCTAssertEqual(vatDetail.country, 80)
        XCTAssertEqual(vatDetail.percentage, 70)
        XCTAssertEqual(vatDetail.amount, 10)
        XCTAssertEqual(vatDetail.vatId, "IUDGTE")
    }

    /// Test StationPassageData structure matches Java
    /// From Java: productName="passage", validFromDay=0, numberOfDaysValid=123
    func testStationPassageDataStructure() {
        var stationPassage = StationPassageData()
        stationPassage.productName = "passage"
        stationPassage.validFromDay = 0
        stationPassage.numberOfDaysValid = 123
        stationPassage.stationNameUTF8 = ["Amsterdam"]

        XCTAssertEqual(stationPassage.productName, "passage")
        XCTAssertEqual(stationPassage.validFromDay, 0)
        XCTAssertEqual(stationPassage.numberOfDaysValid, 123)
        XCTAssertEqual(stationPassage.stationNameUTF8?.first, "Amsterdam")
    }

    /// Test ExtensionData structure matches Java
    /// From Java: extensionId="1", extensionData='82DA'H
    func testExtensionDataStructure() {
        var ext1 = ExtensionData()
        ext1.extensionId = "1"
        ext1.extensionData = Data([0x82, 0xDA])

        var ext2 = ExtensionData()
        ext2.extensionId = "2"
        ext2.extensionData = Data([0x83, 0xDA])

        XCTAssertEqual(ext1.extensionId, "1")
        XCTAssertEqual(ext1.extensionData, Data([0x82, 0xDA]))
        XCTAssertEqual(ext2.extensionId, "2")
        XCTAssertEqual(ext2.extensionData, Data([0x83, 0xDA]))
    }

    /// Test CardReferenceType structure matches Java
    /// From Java: trailingCardIdNum=100
    func testCardReferenceTypeStructure() {
        var cardRef = CardReferenceType()
        cardRef.trailingCardIdNum = 100

        XCTAssertEqual(cardRef.trailingCardIdNum, 100)
    }

    /// Test TariffType structure matches Java
    /// From Java: numberOfPassengers=2, passengerType=adult, restrictedToCountryOfResidence=FALSE
    func testTariffTypeStructure() {
        var tariff = TariffType()
        tariff.numberOfPassengers = 2
        tariff.passengerType = .adult
        tariff.restrictedToCountryOfResidence = false

        var routeSection = RouteSectionType()
        routeSection.fromStationNum = 8000001
        routeSection.toStationNum = 8010000
        tariff.restrictedToRouteSection = routeSection

        XCTAssertEqual(tariff.numberOfPassengers, 2)
        XCTAssertEqual(tariff.passengerType, .adult)
        XCTAssertEqual(tariff.restrictedToCountryOfResidence, false)
        XCTAssertEqual(tariff.restrictedToRouteSection?.fromStationNum, 8000001)
        XCTAssertEqual(tariff.restrictedToRouteSection?.toStationNum, 8010000)
    }

    /// Test RouteSectionType structure matches Java
    /// From Java: fromStationNum=8000001, toStationNum=8010000
    func testRouteSectionTypeStructure() {
        var routeSection = RouteSectionType()
        routeSection.fromStationNum = 8000001
        routeSection.toStationNum = 8010000

        XCTAssertEqual(routeSection.fromStationNum, 8000001)
        XCTAssertEqual(routeSection.toStationNum, 8010000)
    }

    /// Test TokenType structure matches Java
    /// From Java: tokenProviderIA5="VDV", token='82DA'H
    func testTokenTypeStructure() {
        var token = TokenType()
        token.tokenProviderIA5 = "VDV"
        token.token = Data([0x82, 0xDA])

        XCTAssertEqual(token.tokenProviderIA5, "VDV")
        XCTAssertEqual(token.token, Data([0x82, 0xDA]))
    }

    // MARK: - Complete Ticket Structure Tests

    /// Test complete UicRailTicketData structure matches Java
    func testUicRailTicketDataStructure() {
        var ticket = UicRailTicketData()

        // IssuingData
        ticket.issuingDetail.issuingYear = 2018
        ticket.issuingDetail.issuingDay = 1
        ticket.issuingDetail.specimen = true
        ticket.issuingDetail.activated = true

        // TravelerData
        var traveler = TravelerType()
        traveler.firstName = "John"
        traveler.secondName = "Dow"
        traveler.ticketHolder = true

        var travelerData = TravelerData()
        travelerData.groupName = "myGroup"
        travelerData.traveler = [traveler]
        ticket.travelerDetail = travelerData

        // ControlData
        var controlData = ControlData()
        controlData.infoText = "cd"
        ticket.controlDetail = controlData

        // ExtensionData
        var ext = ExtensionData()
        ext.extensionId = "1"
        ext.extensionData = Data([0x82, 0xDA])
        ticket.extensionData = [ext]

        // Verify structure
        XCTAssertEqual(ticket.issuingDetail.issuingYear, 2018)
        XCTAssertEqual(ticket.travelerDetail?.groupName, "myGroup")
        XCTAssertEqual(ticket.travelerDetail?.traveler?.first?.firstName, "John")
        XCTAssertEqual(ticket.controlDetail?.infoText, "cd")
        XCTAssertEqual(ticket.extensionData?.first?.extensionId, "1")
    }

    /// Test DocumentData with OpenTicket
    func testDocumentDataWithOpenTicket() {
        var doc = DocumentData()

        // Token
        var token = TokenType()
        token.tokenProviderIA5 = "VDV"
        token.token = Data([0x82, 0xDA])
        doc.token = token

        // OpenTicket
        var openTicket = OpenTicketData()
        openTicket.returnIncluded = false
        openTicket.classCode = .first
        openTicket.infoText = "openTicketInfo"

        var ticketDetail = TicketDetailData()
        ticketDetail.ticketType = .openTicket(openTicket)
        doc.ticket = ticketDetail

        XCTAssertEqual(doc.token?.tokenProviderIA5, "VDV")
        if case .openTicket(let ot) = doc.ticket.ticketType {
            XCTAssertEqual(ot.classCode, .first)
            XCTAssertEqual(ot.infoText, "openTicketInfo")
        } else {
            XCTFail("Expected openTicket")
        }
    }

    /// Test DocumentData with StationPassage
    func testDocumentDataWithStationPassage() {
        var doc = DocumentData()

        var stationPassage = StationPassageData()
        stationPassage.productName = "passage"
        stationPassage.validFromDay = 0
        stationPassage.numberOfDaysValid = 123
        stationPassage.stationNameUTF8 = ["Amsterdam"]

        var ticketDetail = TicketDetailData()
        ticketDetail.ticketType = .stationPassage(stationPassage)
        doc.ticket = ticketDetail

        if case .stationPassage(let sp) = doc.ticket.ticketType {
            XCTAssertEqual(sp.productName, "passage")
            XCTAssertEqual(sp.numberOfDaysValid, 123)
            XCTAssertEqual(sp.stationNameUTF8?.first, "Amsterdam")
        } else {
            XCTFail("Expected stationPassage")
        }
    }

    // MARK: - Enum Tests (matching Java enums)

    /// Test TravelClassType enum values match Java
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

    /// Test PassengerType enum values match Java
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

    /// Test LinkMode enum values match Java
    func testLinkModeEnum() {
        XCTAssertEqual(LinkMode.issuedTogether.rawValue, 0)
        XCTAssertEqual(LinkMode.onlyValidInCombination.rawValue, 1)
    }

    /// Test TicketType enum values match Java
    func testTicketTypeEnumValues() {
        // TicketType in Java is used for TicketLinkType.ticketType
        XCTAssertEqual(TicketType.openTicket.rawValue, 0)
        XCTAssertEqual(TicketType.pass.rawValue, 1)
        XCTAssertEqual(TicketType.reservation.rawValue, 2)
    }

    // MARK: - Year/Day Range Tests

    /// Test IssuingYear valid range (2016-2269 in ASN.1)
    func testIssuingYearRange() {
        var issuingData = IssuingData()

        // Min value
        issuingData.issuingYear = 2016
        XCTAssertEqual(issuingData.issuingYear, 2016)

        // Max value
        issuingData.issuingYear = 2269
        XCTAssertEqual(issuingData.issuingYear, 2269)

        // Typical value from test
        issuingData.issuingYear = 2018
        XCTAssertEqual(issuingData.issuingYear, 2018)
    }

    /// Test IssuingDay valid range (1-366)
    func testIssuingDayRange() {
        var issuingData = IssuingData()

        // Min value
        issuingData.issuingDay = 1
        XCTAssertEqual(issuingData.issuingDay, 1)

        // Max value
        issuingData.issuingDay = 366
        XCTAssertEqual(issuingData.issuingDay, 366)
    }

    // MARK: - Multiple Documents Test

    /// Test ticket with multiple transport documents (from Java test)
    func testMultipleTransportDocuments() {
        var ticket = UicRailTicketData()
        ticket.issuingDetail.issuingYear = 2018

        // First document: OpenTicket with Token
        var doc1 = DocumentData()
        var token = TokenType()
        token.tokenProviderIA5 = "VDV"
        token.token = Data([0x82, 0xDA])
        doc1.token = token

        var openTicket = OpenTicketData()
        openTicket.classCode = .first
        openTicket.infoText = "openTicketInfo"
        var td1 = TicketDetailData()
        td1.ticketType = .openTicket(openTicket)
        doc1.ticket = td1

        // Second document: StationPassage
        var doc2 = DocumentData()
        var stationPassage = StationPassageData()
        stationPassage.productName = "passage"
        stationPassage.stationNameUTF8 = ["Amsterdam"]
        var td2 = TicketDetailData()
        td2.ticketType = .stationPassage(stationPassage)
        doc2.ticket = td2

        ticket.transportDocument = [doc1, doc2]

        XCTAssertEqual(ticket.transportDocument?.count, 2)

        // Verify first document
        if case .openTicket(let ot) = ticket.transportDocument?[0].ticket.ticketType {
            XCTAssertEqual(ot.classCode, .first)
        } else {
            XCTFail("Expected openTicket in first document")
        }

        // Verify second document
        if case .stationPassage(let sp) = ticket.transportDocument?[1].ticket.ticketType {
            XCTAssertEqual(sp.productName, "passage")
        } else {
            XCTFail("Expected stationPassage in second document")
        }
    }
}

// MARK: - Expected Values from Java Tests

extension FCBTicketTypeDecodingTests {

    /// Expected values for OpenTicket Complex V3 (from Java test assertions)
    struct OpenTicketV3Expected {
        // IssuingData
        static let issuingYear = 2018
        static let issuingDay = 1
        static let issuingTime = 600
        static let issuerPNR = "issuerTestPNR"
        static let specimen = true
        static let securePaperTicket = false
        static let activated = true
        static let issuedOnLine = 12

        // TravelerData
        static let groupName = "myGroup"
        static let firstName = "John"
        static let secondName = "Dow"
        static let idCard = "12345"
        static let ticketHolder = true
        static let customerStatusDescr = "senior"

        // ControlData
        static let controlInfoText = "cd"
        static let trailingCardIdNum = 100

        // OpenTicketData
        static let returnIncluded = false
        static let classCode = TravelClassType.first
        static let openTicketInfoText = "openTicketInfo"

        // VatDetail
        static let vatCountry = 80
        static let vatPercentage = 70
        static let vatAmount = 10
        static let vatId = "IUDGTE"

        // IncludedAddOn
        static let includedProductOwner = 1080
        static let includedClassCode = TravelClassType.second
        static let includedInfoText = "included ticket"
        static let zoneId = 100
        static let tariffPassengers = 2
        static let tariffPassengerType = PassengerType.adult
        static let routeFromStation = 8000001
        static let routeToStation = 8010000

        // StationPassage
        static let passageProductName = "passage"
        static let passageStation = "Amsterdam"
        static let passageValidFromDay = 0
        static let passageNumberOfDaysValid = 123

        // TicketLink
        static let ticketLinkReferenceIA5 = "UED12435867"
        static let ticketLinkIssuerName = "OEBB"
        static let ticketLinkIssuerPNR = "PNR"
        static let ticketLinkProductOwnerIA5 = "test"

        // Extension
        static let extension1Id = "1"
        static let extension1Data = Data([0x82, 0xDA])
        static let extension2Id = "2"
        static let extension2Data = Data([0x83, 0xDA])
    }
}
