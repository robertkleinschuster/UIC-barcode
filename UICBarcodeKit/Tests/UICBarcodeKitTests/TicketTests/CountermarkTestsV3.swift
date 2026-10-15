import XCTest
@testable import UICBarcodeKit

/// Countermark Complex V3 Tests
/// Translated from Java: CountermarkTestComplexTicketV3.java
/// Tests UPER decoding of CountermarkData
final class CountermarkTestsV3: XCTestCase {

    // MARK: - Complete Decode Test

    /// Test decoding Countermark Complex V3 ticket
    func testCountermarkComplexDecoding() throws {
        let data = TestTicketsV3.countermarkComplexData

        var decoder = UPERDecoder(data: data)
        let ticket = try UicRailTicketData(from: &decoder)

        // Assert basic structure
        XCTAssertEqual(ticket.issuingDetail.issuingYear, 2018)
        XCTAssertEqual(ticket.issuingDetail.issuingDay, 1)

        // Assert TravelerData
        XCTAssertNotNil(ticket.travelerDetail)
        XCTAssertEqual(ticket.travelerDetail?.traveler?.first?.firstName, "John")

        // Assert TransportDocument contains countermark
        XCTAssertGreaterThanOrEqual(ticket.transportDocument?.count ?? 0, 1)

        if let doc1 = ticket.transportDocument?.first {
            if case .countermark(let cm) = doc1.ticket.ticketType {
                // Verify countermark-specific fields
                XCTAssertNotNil(cm)
            } else {
                XCTFail("Expected countermark in first document")
            }
        }

        // Assert ControlData
        XCTAssertNotNil(ticket.controlDetail)

        // Assert ExtensionData
        XCTAssertEqual(ticket.extensionData?.count, 2)
    }

    /// Test CountermarkData structure
    func testCountermarkDataStructure() throws {
        var countermark = CountermarkData()
        countermark.referenceIA5 = "TEST123"
        countermark.productOwnerNum = 1080
        countermark.classCode = .first
        countermark.infoText = "Countermark test"

        XCTAssertEqual(countermark.referenceIA5, "TEST123")
        XCTAssertEqual(countermark.productOwnerNum, 1080)
        XCTAssertEqual(countermark.classCode, .first)
        XCTAssertEqual(countermark.infoText, "Countermark test")
    }
}
