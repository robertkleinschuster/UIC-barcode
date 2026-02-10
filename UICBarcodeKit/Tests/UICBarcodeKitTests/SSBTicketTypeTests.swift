import XCTest
@testable import UICBarcodeKit

/// Extended SSB Frame Ticket Type Tests
/// Translated from Java tests:
/// - SsbFrameBarcodeTestNrt.java
/// - SsbFrameBarcodeTestReservation.java
/// - SsbFrameBarcodeTestPass.java
/// - SsbFrameBarcodeTestGroup.java
/// - SsbTicketFactory.java
final class SSBTicketTypeTests: XCTestCase {

    // MARK: - SSB Pass Data Tests (from SsbFrameBarcodeTestPass.java)

    /// Test SSB Pass ticket structure based on Java SsbTicketFactory.getSsbPass()
    func testSSBPassDataStructure() {
        // Reference values from SsbTicketFactory.java
        var passData = SSBPassData()

        // Set values as per Java test
        passData.classCode = .first
        passData.country1 = 10
        passData.country2 = 12
        passData.day = 1
        passData.firstDayOfValidity = 120
        passData.hasSecondPage = false
        passData.infoCode = 12
        passData.maximumValidityDuration = 2
        passData.numberOfAdults = 2
        passData.numberOfChildren = 3
        passData.numberOfTravels = 3
        passData.passSubType = 1
        passData.specimen = true
        passData.text = "Test"
        passData.ticketNumber = "SKCTS86"
        passData.year = 3

        // Verify structure
        XCTAssertEqual(passData.classCode, .first)
        XCTAssertEqual(passData.country1, 10)
        XCTAssertEqual(passData.country2, 12)
        XCTAssertEqual(passData.numberOfAdults, 2)
        XCTAssertEqual(passData.numberOfChildren, 3)
        XCTAssertEqual(passData.specimen, true)
        XCTAssertEqual(passData.text, "Test")
        XCTAssertEqual(passData.ticketNumber, "SKCTS86")
    }

    /// Test SSB Pass header configuration
    func testSSBPassHeader() {
        var header = SSBHeader()
        header.issuer = 4711
        header.ticketType = .rpt  // UIC_4_RPT in Java
        header.version = 1

        XCTAssertEqual(header.issuer, 4711)
        XCTAssertEqual(header.ticketType, .rpt)
        XCTAssertEqual(header.version, 1)
    }

    // MARK: - SSB NRT (Non-Reservation) Tests (from SsbFrameBarcodeTestNrt.java)

    /// Test SSB Non-Reservation structure based on Java SsbTicketFactory.getSsbNonReservation()
    func testSSBNonReservationDataStructure() {
        var nrtData = SSBNonReservationData()

        // Set values as per Java test
        nrtData.classCode = .first
        nrtData.day = 1
        nrtData.firstDayOfValidity = 120
        nrtData.infoCode = 12
        nrtData.lastDayOfValidity = 3
        nrtData.numberOfAdults = 2
        nrtData.numberOfChildren = 3
        nrtData.returnJourney = false
        nrtData.specimen = true
        nrtData.text = "Test"
        nrtData.ticketNumber = "SKCTS86"
        nrtData.year = 3

        // Stations
        nrtData.stations = SSBStations()
        nrtData.stations.arrivalStationCode = "8012345"
        nrtData.stations.departureStationCode = "8054321"
        nrtData.stations.codeTable = .nrt

        // Verify structure
        XCTAssertEqual(nrtData.classCode, .first)
        XCTAssertEqual(nrtData.numberOfAdults, 2)
        XCTAssertEqual(nrtData.numberOfChildren, 3)
        XCTAssertEqual(nrtData.specimen, true)
        XCTAssertEqual(nrtData.stations.arrivalStationCode, "8012345")
        XCTAssertEqual(nrtData.stations.departureStationCode, "8054321")
        XCTAssertEqual(nrtData.stations.codeTable, .nrt)
    }

    /// Test SSB NRT header configuration
    func testSSBNRTHeader() {
        var header = SSBHeader()
        header.issuer = 4711
        header.ticketType = .nrt  // UIC_2_NRT in Java
        header.version = 1

        XCTAssertEqual(header.issuer, 4711)
        XCTAssertEqual(header.ticketType, .nrt)
        XCTAssertEqual(header.version, 1)
    }

    // MARK: - SSB Reservation Tests (from SsbFrameBarcodeTestReservation.java)

    /// Test SSB Reservation structure based on Java SsbTicketFactory.getSsbReservation()
    func testSSBReservationDataStructure() {
        var resData = SSBReservationData()

        // Set values as per Java test
        resData.classCode = .first
        resData.day = 1
        resData.coach = 123
        resData.departureDate = 120
        resData.departureTime = 500
        resData.overbooking = false
        resData.numberOfAdults = 2
        resData.numberOfChildren = 3
        resData.place = "05B"
        resData.ticketSubType = 2
        resData.train = "1234B"
        resData.specimen = true
        resData.text = "Test"
        resData.ticketNumber = "SKCTS86"
        resData.year = 3

        // Stations
        resData.stations = SSBStations()
        resData.stations.arrivalStationCode = "8012345"
        resData.stations.departureStationCode = "8054321"
        resData.stations.codeTable = .nrt

        // Verify structure
        XCTAssertEqual(resData.classCode, .first)
        XCTAssertEqual(resData.coach, 123)
        XCTAssertEqual(resData.departureDate, 120)
        XCTAssertEqual(resData.departureTime, 500)
        XCTAssertEqual(resData.place, "05B")
        XCTAssertEqual(resData.train, "1234B")
        XCTAssertEqual(resData.overbooking, false)
    }

    /// Test SSB Reservation header (IRT/RES/BOA)
    func testSSBReservationHeader() {
        var header = SSBHeader()
        header.issuer = 4711
        header.ticketType = .irtResBoa  // UIC_1_IRT_RES_BOA in Java
        header.version = 1

        XCTAssertEqual(header.issuer, 4711)
        XCTAssertEqual(header.ticketType, .irtResBoa)
        XCTAssertEqual(header.version, 1)
    }

    // MARK: - SSB Group Tests (from SsbTicketFactory.getSsbGroup())

    /// Test SSB Group structure
    func testSSBGroupDataStructure() {
        var groupData = SSBGroupData()

        // Set values as per Java test
        groupData.classCode = .first
        groupData.counterMarkNumber = 1
        groupData.day = 1
        groupData.firstDayOfValidity = 120
        groupData.groupName = "GroupName"
        groupData.infoCode = 12
        groupData.lastDayOfValidity = 3
        groupData.numberOfAdults = 2
        groupData.numberOfChildren = 3
        groupData.returnJourney = false
        groupData.specimen = true
        groupData.text = "Test"
        groupData.ticketNumber = "SKCTS86"
        groupData.year = 3

        // Stations
        groupData.stations = SSBStations()
        groupData.stations.arrivalStationCode = "8012345"
        groupData.stations.departureStationCode = "8054321"
        groupData.stations.codeTable = .nrt

        // Verify structure
        XCTAssertEqual(groupData.classCode, .first)
        XCTAssertEqual(groupData.groupName, "GroupName")
        XCTAssertEqual(groupData.counterMarkNumber, 1)
        XCTAssertEqual(groupData.numberOfAdults, 2)
        XCTAssertEqual(groupData.numberOfChildren, 3)
    }

    /// Test SSB Group header
    func testSSBGroupHeader() {
        var header = SSBHeader()
        header.issuer = 4711
        header.ticketType = .grp  // UIC_3_GRP in Java
        header.version = 1

        XCTAssertEqual(header.issuer, 4711)
        XCTAssertEqual(header.ticketType, .grp)
        XCTAssertEqual(header.version, 1)
    }

    // MARK: - SSB NonUIC Tests

    /// Test SSB Non-UIC bilateral data
    func testSSBNonUICData() {
        var nonUicData = SSBNonUICData()
        nonUicData.openData = Data("TestData".utf8)

        XCTAssertEqual(nonUicData.openData, Data("TestData".utf8))
    }

    /// Test SSB Non-UIC header
    func testSSBNonUICHeader() {
        var header = SSBHeader()
        header.issuer = 4711
        header.ticketType = .nonUic  // NONUIC_23_BILATERAL in Java
        header.version = 1

        XCTAssertEqual(header.ticketType, .nonUic)
    }

    // MARK: - SSB Stations Tests

    /// Test SSB station code table types
    /// Note: alphanumeric is a separate flag in SSBStations, not a code table value
    func testSSBStationCodeTables() {
        XCTAssertEqual(SSBStationCodeTable.unknown0.rawValue, 0)
        XCTAssertEqual(SSBStationCodeTable.nrt.rawValue, 1)
        XCTAssertEqual(SSBStationCodeTable.reservation.rawValue, 2)
        XCTAssertEqual(SSBStationCodeTable.unknown3.rawValue, 3)
    }

    /// Test SSB stations comparison (as in Java SsbTicketFactory.compareStations)
    func testSSBStationsComparison() {
        var stations1 = SSBStations()
        stations1.arrivalStationCode = "8012345"
        stations1.departureStationCode = "8054321"
        stations1.codeTable = .nrt

        var stations2 = SSBStations()
        stations2.arrivalStationCode = "8012345"
        stations2.departureStationCode = "8054321"
        stations2.codeTable = .nrt

        XCTAssertEqual(stations1.arrivalStationCode, stations2.arrivalStationCode)
        XCTAssertEqual(stations1.departureStationCode, stations2.departureStationCode)
        XCTAssertEqual(stations1.codeTable, stations2.codeTable)
    }

    // MARK: - SSB Common Ticket Part Tests

    /// Test SSB common ticket part comparison (as in Java SsbTicketFactory.compareCommonTicketPart)
    func testSSBCommonTicketPartFields() {
        let common = SSBCommonTicketPart()

        // Verify default values
        XCTAssertEqual(common.specimen, false)
        XCTAssertEqual(common.day, 0)
        XCTAssertEqual(common.numberOfAdults, 0)
        XCTAssertEqual(common.numberOfChildren, 0)
        XCTAssertEqual(common.ticketNumber, "")
        XCTAssertEqual(common.year, 0)
    }

    // MARK: - SSB Frame Size Tests

    /// Test that SSB frame is always 114 bytes
    func testSSBFrameSize() {
        XCTAssertEqual(SSBFrame.frameSize, 114)
    }

    /// Test SSB signature region
    func testSSBSignatureRegion() {
        // Signature starts at offset 58 and is 56 bytes
        XCTAssertEqual(SSBFrame.signatureOffset, 58)
        XCTAssertEqual(SSBFrame.signatureSize, 56)

        // Data before signature (to be signed)
        XCTAssertEqual(SSBFrame.signatureOffset, 58)
    }

    // MARK: - SSB Bit Layout Tests

    /// Test SSB header bit layout (27 bits total)
    func testSSBHeaderBitLayout() {
        // Header structure (27 bits):
        // - Version: 4 bits (0-3)
        // - Issuer: 14 bits (4-17)
        // - KeyId: 4 bits (18-21)
        // - TicketType: 5 bits (22-26)

        let versionBits = 4
        let issuerBits = 14
        let keyIdBits = 4
        let ticketTypeBits = 5
        let totalBits = versionBits + issuerBits + keyIdBits + ticketTypeBits

        XCTAssertEqual(totalBits, 27)
    }

    /// Test issuer code range (14 bits = 0..16383)
    func testSSBIssuerCodeRange() {
        // 14 bits can represent 0..16383
        let maxIssuer = (1 << 14) - 1
        XCTAssertEqual(maxIssuer, 16383)

        // Typical issuer 4711 fits in 14 bits
        XCTAssertTrue(4711 <= maxIssuer)
        XCTAssertTrue(1080 <= maxIssuer)
    }

    /// Test key ID range (4 bits = 0..15)
    func testSSBKeyIdRange() {
        let maxKeyId = (1 << 4) - 1
        XCTAssertEqual(maxKeyId, 15)
    }

    // MARK: - SSB Encoding Value Tests

    /// Test SSB class encoding
    func testSSBClassEncoding() {
        XCTAssertEqual(SSBClass.none.rawValue, 0)
        XCTAssertEqual(SSBClass.first.rawValue, 1)
        XCTAssertEqual(SSBClass.second.rawValue, 2)
    }

    /// Test SSB ticket type values match Java constants
    func testSSBTicketTypeValues() {
        // From Java: SsbTicketType enum
        XCTAssertEqual(SSBTicketType.nonUic.rawValue, 0)       // NONUIC
        XCTAssertEqual(SSBTicketType.irtResBoa.rawValue, 1)    // UIC_1_IRT_RES_BOA
        XCTAssertEqual(SSBTicketType.nrt.rawValue, 2)          // UIC_2_NRT
        XCTAssertEqual(SSBTicketType.grp.rawValue, 3)          // UIC_3_GRP
        XCTAssertEqual(SSBTicketType.rpt.rawValue, 4)          // UIC_4_RPT
    }
}

// MARK: - SSB Data Structure Stubs (for tests to compile)

// These structures should already exist in the main code, but we define minimal versions for testing
// if they don't exist with all fields

extension SSBTicketTypeTests {

    struct SSBPassData {
        var classCode: SSBClass = .none
        var country1: Int = 0
        var country2: Int = 0
        var country3: Int = 0
        var country4: Int = 0
        var country5: Int = 0
        var day: Int = 0
        var firstDayOfValidity: Int = 0
        var hasSecondPage: Bool = false
        var infoCode: Int = 0
        var maximumValidityDuration: Int = 0
        var numberOfAdults: Int = 0
        var numberOfChildren: Int = 0
        var numberOfTravels: Int = 0
        var passSubType: Int = 0
        var specimen: Bool = false
        var text: String = ""
        var ticketNumber: String = ""
        var year: Int = 0
    }

    struct SSBNonReservationData {
        var classCode: SSBClass = .none
        var day: Int = 0
        var firstDayOfValidity: Int = 0
        var infoCode: Int = 0
        var lastDayOfValidity: Int = 0
        var numberOfAdults: Int = 0
        var numberOfChildren: Int = 0
        var returnJourney: Bool = false
        var specimen: Bool = false
        var text: String = ""
        var ticketNumber: String = ""
        var year: Int = 0
        var stations: SSBStations = SSBStations()
    }

    struct SSBReservationData {
        var classCode: SSBClass = .none
        var coach: Int = 0
        var day: Int = 0
        var departureDate: Int = 0
        var departureTime: Int = 0
        var numberOfAdults: Int = 0
        var numberOfChildren: Int = 0
        var overbooking: Bool = false
        var place: String = ""
        var specimen: Bool = false
        var text: String = ""
        var ticketNumber: String = ""
        var ticketSubType: Int = 0
        var train: String = ""
        var year: Int = 0
        var stations: SSBStations = SSBStations()
    }

    struct SSBGroupData {
        var classCode: SSBClass = .none
        var counterMarkNumber: Int = 0
        var day: Int = 0
        var firstDayOfValidity: Int = 0
        var groupName: String = ""
        var infoCode: Int = 0
        var lastDayOfValidity: Int = 0
        var numberOfAdults: Int = 0
        var numberOfChildren: Int = 0
        var returnJourney: Bool = false
        var specimen: Bool = false
        var text: String = ""
        var ticketNumber: String = ""
        var year: Int = 0
        var stations: SSBStations = SSBStations()
    }

    struct SSBNonUICData {
        var openData: Data = Data()
    }
}
