import XCTest
@testable import UICBarcodeKit

/// TI (Trenitalia/Italy) Ticket Tests
/// Translated from Java: TIticketTest.java
/// Tests Dynamic V2 frame decoding of a real-world ticket
final class TITicketTests: XCTestCase {

    // MARK: - Test Data

    /// Dynamic V2 ticket base64 from TIticketTest.java
    static let ticketBase64 = "AVVlV4hJ4ABQCCRocJknuREASeB6KmwhTRgwYMGrRg4coAqB4ABOT01FB0NP" +
        "R05PTUVPAEAEEgFYWAAAFAO5r+0lA5zvA32uCITK5NwUtOrK5NLG0ECQxJ3AidwAAAQVQyRn" +
        "HoGAg4SwQyQAsoGCAYCEFUMkZx6CAYEtmCyYCYMDlUMkZx6BgIOBoQACIdM/" +
        "3NC/C94syIud9wO7mYNByejQ4l/ik6HEhi7t3XV7vuPZQox/T2r6zccEDw3Ri48MO0LAjOH6" +
        "sdzYk9CRfgMaOYIoEQM8jg15cDXzeO2ixAMSKKNvwfo2Fa5brPyMkyd0o0EpmBEIBRkK7smz" +
        "ZoF34ztlSrOxWZs5itVsgL3PIlWZ/yhVOgpo"

    // MARK: - Tests

    /// Test decoding Dynamic V2 frame
    func testDynamicV2FrameDecoding() throws {
        let data = Data(base64Encoded: Self.ticketBase64)!

        let barcodeDecoder = UICBarcodeDecoder()
        let barcode = try barcodeDecoder.decode(data)

        // Verify it's a dynamic frame
        if case .dynamicFrame(let version) = barcode.frameType {
            XCTAssertEqual(version, .v2, "Should be Dynamic Barcode Format V2")
        } else {
            XCTFail("Expected dynamic frame, got \(barcode.frameType)")
        }

        // Dynamic frame details
        let frame = try XCTUnwrap(barcode.dynamicFrame)

        // Level2 data must exist
        XCTAssertNotNil(frame.level2SignedData, "Level2 signed data should exist")

        // Level1 data must exist
        XCTAssertNotNil(frame.level1Data, "Level1 data should exist")

        // Level1 signature must exist
        XCTAssertNotNil(frame.level2SignedData?.level1Signature, "Level1 signature should exist")

        // Ticket data (may be nil if FCB version not fully supported)
        // Java test does not assert on ticket data either
    }
}
