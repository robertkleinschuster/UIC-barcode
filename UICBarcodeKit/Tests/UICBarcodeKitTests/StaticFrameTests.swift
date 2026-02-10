import XCTest
@testable import UICBarcodeKit

/// Tests for Static Frame (Classic UIC barcode) decoding
/// Based on StaticFrameBarcodeTest.java
final class StaticFrameTests: XCTestCase {

    // MARK: - Version Tests

    func testStaticFrameVersionEnum() {
        XCTAssertEqual(StaticFrameVersion.v1.rawValue, "01")
        XCTAssertEqual(StaticFrameVersion.v2.rawValue, "02")
    }

    func testDynamicFrameVersionEnum() {
        XCTAssertEqual(DynamicFrameVersion.v1.rawValue, "U1")
        XCTAssertEqual(DynamicFrameVersion.v2.rawValue, "U2")
    }

    // MARK: - Header Tests

    func testInvalidHeader() {
        // Create data that's long enough but has wrong header
        var invalidData = Data(repeating: 0x41, count: 100)
        invalidData[0] = 0x58 // 'X' instead of '#'

        XCTAssertThrowsError(try StaticFrame(data: invalidData)) { error in
            switch error {
            case UICBarcodeError.invalidHeader, UICBarcodeError.invalidFrameSize:
                break
            default:
                XCTFail("Expected invalidHeader or invalidFrameSize error, got \(error)")
            }
        }
    }

    func testFrameTooShort() {
        let shortData = Data("#UT01".utf8)

        XCTAssertThrowsError(try StaticFrame(data: shortData)) { error in
            guard case UICBarcodeError.invalidFrameSize = error else {
                XCTFail("Expected invalidFrameSize error, got \(error)")
                return
            }
        }
    }

    // MARK: - Static Frame Structure Tests (from StaticFrameBarcodeTest.java)

    /// Test Static Frame header magic bytes
    func testStaticFrameHeaderMagic() {
        let headerMagic = "#UT"
        XCTAssertEqual(headerMagic.count, 3)

        let asciiData = headerMagic.data(using: .ascii)!
        XCTAssertEqual(asciiData.count, 3)
        XCTAssertEqual(asciiData[0], 0x23) // '#'
        XCTAssertEqual(asciiData[1], 0x55) // 'U'
        XCTAssertEqual(asciiData[2], 0x54) // 'T'
    }

    // MARK: - Provider/KeyID Tests

    /// Test extracting security provider from frame
    func testExtractSecurityProvider() throws {
        let frameData = createMinimalStaticFrame(version: 2, provider: "1080", keyId: "00001")
        let frame = try StaticFrame(data: frameData)

        XCTAssertEqual(frame.securityProvider, "1080")
    }

    /// Test extracting key ID from frame
    func testExtractKeyId() throws {
        let frameData = createMinimalStaticFrame(version: 2, provider: "1234", keyId: "00005")
        let frame = try StaticFrame(data: frameData)

        XCTAssertEqual(frame.signatureKeyId, "00005")
    }

    // MARK: - Version Detection Tests

    /// Test V1 frame decoding
    func testDecodeV1Frame() throws {
        let frameData = createMinimalStaticFrame(version: 1, provider: "1080", keyId: "00001")
        let frame = try StaticFrame(data: frameData)

        XCTAssertEqual(frame.version, 1)
    }

    /// Test V2 frame decoding
    func testDecodeV2Frame() throws {
        let frameData = createMinimalStaticFrame(version: 2, provider: "1080", keyId: "00001")
        let frame = try StaticFrame(data: frameData)

        XCTAssertEqual(frame.version, 2)
    }

    // MARK: - Signature Extraction Tests

    /// Test extracting signature from V1 frame (50 bytes)
    func testExtractSignatureV1() throws {
        var frameData = createMinimalStaticFrame(version: 1, provider: "1080", keyId: "00001")

        // Set known signature bytes at offset 14 (50 bytes for V1)
        // Need to create a valid DER signature structure
        var signature = Data()
        signature.append(0x30) // SEQUENCE
        signature.append(0x2E) // Length (46)
        signature.append(0x02) // INTEGER
        signature.append(0x15) // Length (21)
        signature.append(Data(repeating: 0x42, count: 21))
        signature.append(0x02) // INTEGER
        signature.append(0x15) // Length (21)
        signature.append(Data(repeating: 0x43, count: 21))

        // Pad to 50 bytes
        while signature.count < 50 {
            signature.append(0)
        }

        frameData.replaceSubrange(14..<64, with: signature)

        let frame = try StaticFrame(data: frameData)
        XCTAssertFalse(frame.signature.isEmpty)
    }

    /// Test extracting signature from V2 frame (64 bytes)
    func testExtractSignatureV2() throws {
        var frameData = createMinimalStaticFrame(version: 2, provider: "1080", keyId: "00001")

        // V2 signatures are split r||s format (32 bytes each)
        let signature = Data(repeating: 0x42, count: 64)
        frameData.replaceSubrange(14..<78, with: signature)

        let frame = try StaticFrame(data: frameData)
        XCTAssertFalse(frame.signature.isEmpty)
    }

    // MARK: - Data Record Tests

    /// Test Static Frame default initialization
    func testStaticFrameDefaultInit() {
        let frame = StaticFrame()

        XCTAssertEqual(frame.version, 1)
        XCTAssertEqual(frame.securityProvider, "")
        XCTAssertEqual(frame.signatureKeyId, "")
        XCTAssertTrue(frame.signature.isEmpty)
        XCTAssertTrue(frame.signedData.isEmpty)
    }

    /// Test data record protocol conformance
    func testDataRecordProtocol() throws {
        // Test GenericDataRecord
        var recordData = Data()
        recordData.append("TEST01".data(using: .ascii)!)  // tag
        recordData.append("01".data(using: .ascii)!)       // version
        recordData.append("0016".data(using: .ascii)!)     // length (16 bytes total)
        recordData.append(Data([0x00, 0x01, 0x02, 0x03]))  // content

        let record = try GenericDataRecord(data: recordData)
        XCTAssertEqual(record.tag, "TEST01")
        XCTAssertEqual(record.version, "01")
    }

    // MARK: - Full Decode Cycle Test

    /// Test basic decode cycle (similar to Java test)
    func testBasicDecodeCycle() throws {
        let frameData = createMinimalStaticFrame(version: 2, provider: "1080", keyId: "00001")
        let frame = try StaticFrame(data: frameData)

        XCTAssertEqual(frame.version, 2)
        XCTAssertEqual(frame.securityProvider, "1080")
        XCTAssertEqual(frame.signatureKeyId, "00001")
    }
}

// MARK: - Test Helpers

extension StaticFrameTests {

    /// Create minimal valid static frame for testing
    func createMinimalStaticFrame(version: Int, provider: String = "1080", keyId: String = "00001") -> Data {
        var data = Data()

        // Header "#UT" (3 bytes)
        data.append("#UT".data(using: .ascii)!)

        // Version (2 bytes)
        data.append(String(format: "%02d", version).data(using: .ascii)!)

        // Security provider (4 bytes)
        data.append(provider.padding(toLength: 4, withPad: "0", startingAt: 0).data(using: .ascii)!)

        // Key ID (5 bytes)
        data.append(keyId.padding(toLength: 5, withPad: "0", startingAt: 0).data(using: .ascii)!)

        // Signature (50 bytes for v1, 64 for v2)
        // Create a valid-looking DER signature
        let sigLength = version == 1 ? 50 : 64
        if version == 1 {
            // DER format for V1
            var sig = Data()
            sig.append(0x30) // SEQUENCE
            sig.append(0x2C) // Length
            sig.append(0x02) // INTEGER
            sig.append(0x14) // r length (20)
            sig.append(Data(repeating: 0x00, count: 20))
            sig.append(0x02) // INTEGER
            sig.append(0x14) // s length (20)
            sig.append(Data(repeating: 0x00, count: 20))
            while sig.count < sigLength {
                sig.append(0)
            }
            data.append(sig)
        } else {
            // Raw r||s format for V2
            data.append(Data(repeating: 0, count: sigLength))
        }

        // Data length (4 bytes)
        data.append("0008".data(using: .ascii)!)

        // Minimal DEFLATE compressed data (zlib header + empty block)
        data.append(Data([0x78, 0x9C, 0x03, 0x00, 0x00, 0x00, 0x00, 0x01]))

        return data
    }
}
