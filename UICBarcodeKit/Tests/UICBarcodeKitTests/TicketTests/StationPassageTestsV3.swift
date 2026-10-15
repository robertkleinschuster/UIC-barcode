import XCTest
@testable import UICBarcodeKit

/// Station Passage V3 Tests
/// Translated from Java: StationPassageTestTicketV3.java
/// Tests UPER decoding of StationPassageData
final class StationPassageTestsV3: XCTestCase {

    // MARK: - Complete Decode Test

    /// Test decoding Station Passage V3 ticket
    func testStationPassageDecoding() throws {
        let data = TestTicketsV3.stationPassageData

        var decoder = UPERDecoder(data: data)
        let ticket = try UicRailTicketData(from: &decoder)

        // Assert basic structure
        XCTAssertEqual(ticket.issuingDetail.issuingYear, 2018)
        XCTAssertEqual(ticket.issuingDetail.issuingDay, 1)

        // Assert TravelerData
        XCTAssertNotNil(ticket.travelerDetail)
        XCTAssertEqual(ticket.travelerDetail?.traveler?.first?.firstName, "John")

        // Assert TransportDocument contains stationPassage
        XCTAssertGreaterThanOrEqual(ticket.transportDocument?.count ?? 0, 1)

        if let doc1 = ticket.transportDocument?.first {
            if case .stationPassage(let sp) = doc1.ticket.ticketType {
                XCTAssertNotNil(sp)
                // StationPassage-specific assertions
                XCTAssertEqual(sp.productName, "passage")
            } else {
                XCTFail("Expected stationPassage in first document")
            }
        }

        // Assert ControlData
        XCTAssertNotNil(ticket.controlDetail)

        // Assert ExtensionData
        XCTAssertEqual(ticket.extensionData?.count, 2)
    }

    /// Test StationPassageData structure
    func testStationPassageDataStructure() throws {
        var sp = StationPassageData()
        sp.productName = "passage"
        sp.stationNameUTF8 = ["Amsterdam", "Rotterdam"]
        sp.validFromDay = 0
        sp.numberOfDaysValid = 123

        XCTAssertEqual(sp.productName, "passage")
        XCTAssertEqual(sp.stationNameUTF8?.count, 2)
        XCTAssertEqual(sp.stationNameUTF8?.first, "Amsterdam")
        XCTAssertEqual(sp.validFromDay, 0)
        XCTAssertEqual(sp.numberOfDaysValid, 123)
    }

    /// Test multiple station names
    func testMultipleStationNames() throws {
        var sp = StationPassageData()
        sp.stationNameUTF8 = ["Amsterdam Centraal", "Rotterdam Centraal", "Den Haag HS"]
        sp.stationNum = [8400058, 8400530, 8400280]

        XCTAssertEqual(sp.stationNameUTF8?.count, 3)
        XCTAssertEqual(sp.stationNum?.count, 3)
        XCTAssertEqual(sp.stationNum?[0], 8400058)
    }

    /// Test area codes
    func testAreaCodes() throws {
        var sp = StationPassageData()
        sp.areaCodeNum = [100, 200]
        sp.areaNameUTF8 = ["Zone A", "Zone B"]

        XCTAssertEqual(sp.areaCodeNum?.count, 2)
        XCTAssertEqual(sp.areaNameUTF8?.count, 2)
        XCTAssertEqual(sp.areaNameUTF8?.first, "Zone A")
    }
}
