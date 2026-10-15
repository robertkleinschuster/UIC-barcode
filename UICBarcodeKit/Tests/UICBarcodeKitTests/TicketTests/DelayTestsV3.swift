import XCTest
@testable import UICBarcodeKit

/// Delay Confirmation V3 Tests
/// Translated from Java: DelayTestTicketV3.java
/// Tests UPER decoding of DelayConfirmation
final class DelayTestsV3: XCTestCase {

    // MARK: - Complete Decode Test

    /// Test decoding Delay Confirmation V3 ticket
    func testDelayConfirmationDecoding() throws {
        let data = TestTicketsV3.delayConfirmationData

        var decoder = UPERDecoder(data: data)
        let ticket = try UicRailTicketData(from: &decoder)

        // Assert basic structure
        XCTAssertNotNil(ticket.issuingDetail)

        // Assert TravelerData
        XCTAssertNotNil(ticket.travelerDetail)
        XCTAssertEqual(ticket.travelerDetail?.traveler?.first?.firstName, "John")

        // Assert TransportDocument contains delayConfirmation
        XCTAssertGreaterThanOrEqual(ticket.transportDocument?.count ?? 0, 1)

        if let doc1 = ticket.transportDocument?.first {
            if case .delayConfirmation(let delay) = doc1.ticket.ticketType {
                XCTAssertNotNil(delay)
                // Additional delay-specific assertions would go here
            } else {
                XCTFail("Expected delayConfirmation in first document")
            }
        }

        // Assert ControlData
        XCTAssertNotNil(ticket.controlDetail)

        // Assert ExtensionData
        XCTAssertEqual(ticket.extensionData?.count, 2)
    }

    /// Test DelayConfirmation structure
    func testDelayConfirmationStructure() throws {
        var delay = DelayConfirmation()
        delay.referenceNum = 123
        delay.trainNum = 456
        delay.delay = 30
        delay.trainCancelled = false
        delay.confirmationType = .trainDelayConfirmation

        XCTAssertEqual(delay.referenceNum, 123)
        XCTAssertEqual(delay.trainNum, 456)
        XCTAssertEqual(delay.delay, 30)
        XCTAssertEqual(delay.trainCancelled, false)
        XCTAssertEqual(delay.confirmationType, .trainDelayConfirmation)
    }

    /// Test ConfirmationTypeType enum (matches Java ConfirmationTypeType.java)
    func testConfirmationTypeEnum() {
        XCTAssertEqual(ConfirmationTypeType.trainDelayConfirmation.rawValue, 0)
        XCTAssertEqual(ConfirmationTypeType.travelerDelayConfirmation.rawValue, 1)
        XCTAssertEqual(ConfirmationTypeType.trainLinkedTicketDelay.rawValue, 2)
    }
}
