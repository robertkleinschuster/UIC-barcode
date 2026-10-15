import XCTest
@testable import UICBarcodeKit

/// Voucher V3 Tests
/// Translated from Java: AsnLevelVoucherTestV3.java
/// Tests UPER decoding and round-trip encoding of VoucherData
final class VoucherTestsV3: XCTestCase {

    // MARK: - Complete Decode Test

    /// Test decoding Voucher V3 ticket
    func testVoucherDecoding() throws {
        let data = TestTicketsV3.voucherData

        var decoder = UPERDecoder(data: data)
        let ticket = try UicRailTicketData(from: &decoder)

        // Assert IssuingData
        XCTAssertEqual(ticket.issuingDetail.issuingYear, 2021)
        XCTAssertEqual(ticket.issuingDetail.issuingDay, 63)
        XCTAssertEqual(ticket.issuingDetail.issuingTime, 600)
        XCTAssertEqual(ticket.issuingDetail.specimen, true)
        XCTAssertEqual(ticket.issuingDetail.activated, true)
        XCTAssertEqual(ticket.issuingDetail.issuerPNR, "issuerTestPNR")
        XCTAssertEqual(ticket.issuingDetail.issuedOnLine, 12)

        // Assert TravelerData
        XCTAssertNotNil(ticket.travelerDetail)
        XCTAssertEqual(ticket.travelerDetail?.traveler?.first?.firstName, "John")
        XCTAssertEqual(ticket.travelerDetail?.traveler?.first?.secondName, "Dow")
        XCTAssertEqual(ticket.travelerDetail?.traveler?.first?.idCard, "12345")
        XCTAssertEqual(ticket.travelerDetail?.traveler?.first?.ticketHolder, true)

        // Assert TransportDocument contains voucher
        XCTAssertGreaterThanOrEqual(ticket.transportDocument?.count ?? 0, 1)

        if let doc = ticket.transportDocument?.first {
            if case .voucher(let v) = doc.ticket.ticketType {
                XCTAssertEqual(v.referenceIA5, "ACHE12345")
                XCTAssertEqual(v.productOwnerIA5, "COFFEEMACHINE")
                XCTAssertEqual(v.validFromYear, 2022)
                XCTAssertEqual(v.validFromDay, 1)
                XCTAssertEqual(v.validUntilYear, 2022)
                XCTAssertEqual(v.validUntilDay, 1)
                XCTAssertEqual(v.value, 500)
                XCTAssertEqual(v.infoText, "coffee voucher")
            } else {
                XCTFail("Expected voucher in first document")
            }
        }

        // Assert ControlData
        XCTAssertNotNil(ticket.controlDetail)
        XCTAssertEqual(ticket.controlDetail?.infoText, "cd")

        // Assert ExtensionData
        XCTAssertEqual(ticket.extensionData?.count, 2)
        XCTAssertEqual(ticket.extensionData?[0].extensionId, "1")
        XCTAssertEqual(ticket.extensionData?[0].extensionData, Data([0x82, 0xDA]))
        XCTAssertEqual(ticket.extensionData?[1].extensionId, "2")
        XCTAssertEqual(ticket.extensionData?[1].extensionData, Data([0x83, 0xDA]))
    }

    /// Test round-trip encoding of Voucher V3
    func testVoucherRoundTrip() throws {
        let data = TestTicketsV3.voucherData

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

    /// Test VoucherData field structure
    func testVoucherDataStructure() throws {
        var v = VoucherData()
        v.referenceIA5 = "REF123"
        v.productOwnerIA5 = "OWNER"
        v.validFromYear = 2023
        v.validFromDay = 100
        v.validUntilYear = 2023
        v.validUntilDay = 200
        v.value = 1000
        v.infoText = "test voucher"

        XCTAssertEqual(v.referenceIA5, "REF123")
        XCTAssertEqual(v.productOwnerIA5, "OWNER")
        XCTAssertEqual(v.validFromYear, 2023)
        XCTAssertEqual(v.validFromDay, 100)
        XCTAssertEqual(v.validUntilYear, 2023)
        XCTAssertEqual(v.validUntilDay, 200)
        XCTAssertEqual(v.value, 1000)
        XCTAssertEqual(v.infoText, "test voucher")
    }
}
