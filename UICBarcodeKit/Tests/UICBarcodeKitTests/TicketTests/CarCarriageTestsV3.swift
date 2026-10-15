import XCTest
@testable import UICBarcodeKit

/// Car Carriage Reservation V3 Tests
/// Translated from Java: AsnLevelCarCarriageTestV3.java
/// Tests UPER decoding and round-trip encoding of CarCarriageReservationData
final class CarCarriageTestsV3: XCTestCase {

    // MARK: - Complete Decode Test

    /// Test decoding Car Carriage V3 ticket
    func testCarCarriageDecoding() throws {
        let data = TestTicketsV3.carCarriageReservationData

        var decoder = UPERDecoder(data: data)
        let ticket = try UicRailTicketData(from: &decoder)

        // Assert IssuingData
        XCTAssertEqual(ticket.issuingDetail.issuingYear, 2018)
        XCTAssertEqual(ticket.issuingDetail.issuingDay, 1)
        XCTAssertEqual(ticket.issuingDetail.specimen, true)
        XCTAssertEqual(ticket.issuingDetail.activated, true)
        XCTAssertEqual(ticket.issuingDetail.issuerPNR, "issuerTestPNR")
        XCTAssertEqual(ticket.issuingDetail.issuedOnLine, 12)

        // Assert TravelerData
        XCTAssertNotNil(ticket.travelerDetail)
        XCTAssertEqual(ticket.travelerDetail?.groupName, "myGroup")
        XCTAssertEqual(ticket.travelerDetail?.traveler?.first?.firstName, "John")
        XCTAssertEqual(ticket.travelerDetail?.traveler?.first?.secondName, "Dow")

        // Assert TransportDocument contains carCarriageReservation
        XCTAssertGreaterThanOrEqual(ticket.transportDocument?.count ?? 0, 1)

        if let doc = ticket.transportDocument?.first {
            if case .carCarriageReservation(let cc) = doc.ticket.ticketType {
                XCTAssertEqual(cc.trainNum, 123)
                XCTAssertEqual(cc.coach, "21")
                XCTAssertEqual(cc.place, "41")
                XCTAssertEqual(cc.fromStationNum, 8100001)
                XCTAssertEqual(cc.toStationNum, 800001)
                XCTAssertEqual(cc.beginLoadingDate, 10)
                XCTAssertEqual(cc.beginLoadingTime, 0)
                XCTAssertEqual(cc.endLoadingTime, 500)
                XCTAssertEqual(cc.loadingDeck, .upper)
                XCTAssertEqual(cc.loadingListEntry, 421)
                XCTAssertEqual(cc.carCategory, 3)
                XCTAssertEqual(cc.numberPlate, "AD-DE-123")
                XCTAssertEqual(cc.trailerPlate, "DX-AB-123")
                XCTAssertEqual(cc.textileRoof, false)
                XCTAssertEqual(cc.roofRackType, .bicycleRack)
                XCTAssertEqual(cc.roofRackHeight, 20)
                XCTAssertEqual(cc.attachedBicycles, 1)
                XCTAssertEqual(cc.attachedSurfboards, 2)
                XCTAssertEqual(cc.referenceNum, 810123456789)
                XCTAssertEqual(cc.price, 12345)
                XCTAssertEqual(cc.infoText, "car carriage")
                XCTAssertEqual(cc.serviceBrand, 100)
                XCTAssertEqual(cc.serviceBrandAbrUTF8, "AZ")
                XCTAssertEqual(cc.serviceBrandNameUTF8, "special train")
                XCTAssertEqual(cc.priceType, .travelPrice)
                XCTAssertEqual(cc.carrierNum, [1080, 1181])

                // Tariff
                XCTAssertNotNil(cc.tariff)
                if let tariff = cc.tariff {
                    XCTAssertEqual(tariff.numberOfPassengers, 1)
                    XCTAssertEqual(tariff.tariffIdNum, 72)
                    XCTAssertEqual(tariff.tariffDesc, "Large Car Full Fare")
                }

                // VatDetails
                XCTAssertEqual(cc.vatDetails?.count, 1)
                if let vat = cc.vatDetails?.first {
                    XCTAssertEqual(vat.country, 80)
                    XCTAssertEqual(vat.percentage, 70)
                    XCTAssertEqual(vat.amount, 10)
                    XCTAssertEqual(vat.vatId, "IUDGTE")
                }
            } else {
                XCTFail("Expected carCarriageReservation in first document")
            }
        }

        // Assert ControlData
        XCTAssertNotNil(ticket.controlDetail)
        XCTAssertEqual(ticket.controlDetail?.infoText, "cd")

        // Assert ExtensionData
        XCTAssertEqual(ticket.extensionData?.count, 2)
    }

    /// Test round-trip encoding of Car Carriage V3
    func testCarCarriageRoundTrip() throws {
        let data = TestTicketsV3.carCarriageReservationData

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

    /// Test individual CarCarriageReservation fields
    func testCarCarriageFields() throws {
        let data = TestTicketsV3.carCarriageReservationData
        var decoder = UPERDecoder(data: data)
        let ticket = try UicRailTicketData(from: &decoder)

        if let doc = ticket.transportDocument?.first,
           case .carCarriageReservation(let cc) = doc.ticket.ticketType {
            // Loading deck
            XCTAssertEqual(cc.loadingDeck, .upper)
            // Roof rack type
            XCTAssertEqual(cc.roofRackType, .bicycleRack)
            // Price type
            XCTAssertEqual(cc.priceType, .travelPrice)
        } else {
            XCTFail("Could not extract CarCarriageReservation")
        }
    }
}
