import XCTest
@testable import UICBarcodeKit

/// Parking V3 Tests
/// Translated from Java: AsnLevelParkingTestV3.java
/// Tests UPER decoding and round-trip encoding of ParkingGroundData
final class ParkingTestsV3: XCTestCase {

    // MARK: - Complete Decode Test

    /// Test decoding Parking V3 ticket
    func testParkingDecoding() throws {
        let data = TestTicketsV3.parkingData

        var decoder = UPERDecoder(data: data)
        let ticket = try UicRailTicketData(from: &decoder)

        // Assert IssuingData
        XCTAssertEqual(ticket.issuingDetail.issuingYear, 2021)
        XCTAssertEqual(ticket.issuingDetail.issuingDay, 63)
        XCTAssertEqual(ticket.issuingDetail.specimen, true)
        XCTAssertEqual(ticket.issuingDetail.activated, true)
        XCTAssertEqual(ticket.issuingDetail.issuerPNR, "issuerTestPNR")
        XCTAssertEqual(ticket.issuingDetail.issuedOnLine, 12)

        // Assert TravelerData
        XCTAssertNotNil(ticket.travelerDetail)
        XCTAssertEqual(ticket.travelerDetail?.traveler?.first?.firstName, "John")
        XCTAssertEqual(ticket.travelerDetail?.traveler?.first?.secondName, "Dow")

        // Assert TransportDocument contains parking
        XCTAssertGreaterThanOrEqual(ticket.transportDocument?.count ?? 0, 1)

        if let doc = ticket.transportDocument?.first {
            if case .parkingGround(let p) = doc.ticket.ticketType {
                XCTAssertEqual(p.referenceIA5, "ACHE12345")
                XCTAssertEqual(p.parkingGroundId, "P47623")
                XCTAssertEqual(p.fromParkingDate, 1)
                XCTAssertEqual(p.toParkingDate, 1)
                XCTAssertEqual(p.location, "Parking Frankfurt Main West")
                XCTAssertEqual(p.stationNum, 8000001)
                XCTAssertEqual(p.specialInformation, "outdoor parking")
                XCTAssertEqual(p.price, 500)
                XCTAssertEqual(p.numberPlate, "AA-DE-12345")
            } else {
                XCTFail("Expected parkingGround in first document")
            }
        }

        // Assert ControlData
        XCTAssertNotNil(ticket.controlDetail)
        XCTAssertEqual(ticket.controlDetail?.infoText, "cd")

        // Assert ExtensionData
        XCTAssertEqual(ticket.extensionData?.count, 2)
    }

    /// Test round-trip encoding of Parking V3
    func testParkingRoundTrip() throws {
        let data = TestTicketsV3.parkingData

        // Decode
        var decoder = UPERDecoder(data: data)
        let ticket = try UicRailTicketData(from: &decoder)

        // Re-encode
        var encoder = UPEREncoder()
        try ticket.encode(to: &encoder)
        let reEncoded = encoder.toData()

        // Compare hex strings
        let originalHex = data.map { String(format: "%02X", $0) }.joined()
        let reEncodedHex = reEncoded.map { String(format: "%02X", $0) }.joined()
        XCTAssertEqual(originalHex, reEncodedHex, "Round-trip encoding should produce identical bytes")
    }

    /// Test ParkingGroundData structure
    func testParkingDataStructure() throws {
        var p = ParkingGroundData()
        p.referenceIA5 = "REF123"
        p.parkingGroundId = "P100"
        p.fromParkingDate = 5
        p.toParkingDate = 10
        p.location = "Test Parking"
        p.stationNum = 8000001
        p.specialInformation = "covered"
        p.price = 1500
        p.numberPlate = "XX-YY-123"

        XCTAssertEqual(p.referenceIA5, "REF123")
        XCTAssertEqual(p.parkingGroundId, "P100")
        XCTAssertEqual(p.fromParkingDate, 5)
        XCTAssertEqual(p.toParkingDate, 10)
        XCTAssertEqual(p.location, "Test Parking")
        XCTAssertEqual(p.stationNum, 8000001)
        XCTAssertEqual(p.specialInformation, "covered")
        XCTAssertEqual(p.price, 1500)
        XCTAssertEqual(p.numberPlate, "XX-YY-123")
    }
}
