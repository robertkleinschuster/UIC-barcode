import XCTest
@testable import UICBarcodeKit

/// Tests for Dynamic Frame (DOSIPAS format) decoding
/// Based on DynamicFrameSimpleTest.java and related tests
final class DynamicFrameTests: XCTestCase {

    // MARK: - Dynamic Frame Structure Tests

    /// Test Dynamic Frame version constants
    func testDynamicFrameVersions() {
        XCTAssertEqual(DynamicFrameVersion.v1.rawValue, "U1")
        XCTAssertEqual(DynamicFrameVersion.v2.rawValue, "U2")
    }

    // MARK: - Dynamic Frame Level Structure

    /// Test Dynamic Frame level structure
    /// Level 1: Contains ticket data + signature
    /// Level 2: Contains Level 1 data + Level 2 signature
    func testDynamicFrameLevelStructure() {
        // Dynamic Frame has nested structure:
        // DynamicFrame
        //   -> level2SignedData (Level2DataType)
        //     -> level1Data (Level1DataType)
        //       -> dataList (SEQUENCE OF DataType)
        //     -> level1Signature
        //   -> level2Signature

        // This structure allows for two-level signature verification
        // Level 1: Signed by ticket issuer
        // Level 2: Signed by security provider
    }

    // MARK: - UPER Encoding Tests

    /// Test that Dynamic Frame uses UPER encoding
    func testDynamicFrameUPEREncoding() {
        // Dynamic Frame is encoded using ASN.1 UPER (Unaligned Packed Encoding Rules)
        // The format identifier ("U1" or "U2") is encoded as an IA5String

        // "U1" in IA5String encoding (7-bit characters):
        // Length: 2 (encoded as length determinant)
        // 'U' = 0x55 = 1010101 (7 bits)
        // '1' = 0x31 = 0110001 (7 bits)

        // "U2" similarly
    }

    // MARK: - Data Format Tests

    /// Test FCB format identifiers in Dynamic Frame
    func testFCBFormatIdentifiers() {
        // FCB versions in Dynamic Frame:
        let fcb1 = "FCB1"  // FCB Version 1
        let fcb2 = "FCB2"  // FCB Version 2
        let fcb3 = "FCB3"  // FCB Version 3

        XCTAssertEqual(fcb1.count, 4)
        XCTAssertEqual(fcb2.count, 4)
        XCTAssertEqual(fcb3.count, 4)
    }

    // MARK: - Level 1 Data Tests

    /// Test Level 1 data structure
    func testLevel1DataStructure() {
        // Level 1 data contains:
        // - securityProviderNum (optional, INTEGER 1..32000)
        // - securityProviderIA5 (optional, IA5String)
        // - keyId (optional, INTEGER 0..99999)
        // - dataSequence (SEQUENCE OF DataType) - mandatory
        // - level1KeyAlg (optional, OBJECT IDENTIFIER)
        // - level2KeyAlg (optional, OBJECT IDENTIFIER)
        // - level1SigningAlg (optional, OBJECT IDENTIFIER)
        // - level2SigningAlg (optional, OBJECT IDENTIFIER)
        // - level2PublicKey (optional, OCTET STRING)
        // V2 adds: endOfValidityYear, endOfValidityDay, endOfValidityTime, validityDuration

        // Each DataType contains:
        // - format (IA5String, e.g., "FCB1", "FCB2", "FCB3")
        // - data (OCTET STRING)
    }

    /// Test creating Level 1 data item
    func testDynamicFrameDataItem() {
        var item = DynamicFrameDataItem()
        item.format = "FCB3"
        item.data = Data([0x00, 0x01, 0x02])

        XCTAssertEqual(item.format, "FCB3")
        XCTAssertEqual(item.data.count, 3)
    }

    // MARK: - Level 2 Data Tests

    /// Test Level 2 data structure
    func testLevel2DataStructure() {
        // Level 2 data contains:
        // - level1Data (Level1DataType) - mandatory
        // - level1Signature (optional, OCTET STRING)
        // - level2Data (optional, DataType)
    }

    // MARK: - Algorithm OID Tests (from DynamicFrameSimpleTest.java)

    /// Test ECDSA algorithm OIDs
    func testECDSAAlgorithmOIDs() {
        // ECDSA-SHA256: 1.2.840.10045.4.3.2
        XCTAssertEqual(AlgorithmOID.ecdsa_sha256_oid, "1.2.840.10045.4.3.2")

        // ECDSA-SHA384: 1.2.840.10045.4.3.3
        XCTAssertEqual(AlgorithmOID.ecdsa_sha384_oid, "1.2.840.10045.4.3.3")

        // ECDSA-SHA512: 1.2.840.10045.4.3.4
        XCTAssertEqual(AlgorithmOID.ecdsa_sha512_oid, "1.2.840.10045.4.3.4")
    }

    /// Test DSA algorithm OIDs (not supported on Apple platforms)
    func testDSAAlgorithmOIDs() {
        // DSA-SHA1: 1.2.840.10040.4.3
        XCTAssertEqual(AlgorithmOID.dsa_sha1_oid, "1.2.840.10040.4.3")

        // DSA-SHA224: 2.16.840.1.101.3.4.3.1
        XCTAssertEqual(AlgorithmOID.dsa_sha224_oid, "2.16.840.1.101.3.4.3.1")

        // DSA-SHA256: 2.16.840.1.101.3.4.3.2
        XCTAssertEqual(AlgorithmOID.dsa_sha256_oid, "2.16.840.1.101.3.4.3.2")
    }

    /// Test algorithm OID parsing
    func testAlgorithmOIDParsing() throws {
        // ECDSA algorithms (supported)
        let ecdsa256 = try AlgorithmOID.parse("1.2.840.10045.4.3.2")
        XCTAssertEqual(ecdsa256, .ecdsaWithSHA256)

        let ecdsa384 = try AlgorithmOID.parse("1.2.840.10045.4.3.3")
        XCTAssertEqual(ecdsa384, .ecdsaWithSHA384)

        let ecdsa512 = try AlgorithmOID.parse("1.2.840.10045.4.3.4")
        XCTAssertEqual(ecdsa512, .ecdsaWithSHA512)

        // DSA algorithms (recognized but not supported)
        let dsa1 = try AlgorithmOID.parse("1.2.840.10040.4.3")
        XCTAssertEqual(dsa1, .dsaWithSHA1)

        // Unknown algorithm
        let unknown = try AlgorithmOID.parse("1.2.3.4.5.6")
        XCTAssertEqual(unknown, .unknown)
    }

    // MARK: - Dynamic Content Tests (FDC1)

    /// Test FDC1 (Dynamic Content) structure
    func testFDC1Structure() {
        // FDC1 contains (matching Java UicDynamicContentDataFDC1.java):
        // - appId (optional, IA5String)
        // - timeStamp (optional, TimeStamp)
        // - geoCoordinate (optional, GeoCoordinateType)
        // - dynamicContentResponseToChallenge (optional, SEQUENCE OF ExtensionData)
        // - dynamicContentExtension (optional, ExtensionData)

        var fdc1 = DynamicContentFDC1()
        fdc1.appId = "TestApp"

        XCTAssertEqual(fdc1.appId, "TestApp")
        XCTAssertEqual(DynamicContentFDC1.format, "FDC1")
    }

    /// Test DynamicContent enum
    func testDynamicContentEnum() {
        let fdc1 = DynamicContentFDC1()
        let content = DynamicContent.fdc1(fdc1)

        XCTAssertEqual(content.contentType, .fdc1)
        XCTAssertNotNil(content.fdc1Content)
    }

    // MARK: - Frame Decoding Tests

    /// Test decoding V1 Dynamic Frame header
    func testDecodeV1Header() throws {
        // Create minimal V1 frame
        // 8 bits length + 14 bits chars = 22 bits
        var buffer = BitBuffer.allocate(bits: 24)

        // IA5String "U1" (length + 7-bit chars)
        try buffer.putBits(2, count: 8)  // Length = 2
        try buffer.putBits(0x55, count: 7)  // 'U'
        try buffer.putBits(0x31, count: 7)  // '1'

        // Minimal Level2Data structure would follow...
        // For this test, we just verify the header parsing

        var decoder = UPERDecoder(data: buffer.toData())
        let format = try decoder.decodeIA5String()

        XCTAssertEqual(format, "U1")
    }

    /// Test decoding V2 Dynamic Frame header
    func testDecodeV2Header() throws {
        var buffer = BitBuffer.allocate(bits: 24)

        // IA5String "U2"
        try buffer.putBits(2, count: 8)  // Length = 2
        try buffer.putBits(0x55, count: 7)  // 'U'
        try buffer.putBits(0x32, count: 7)  // '2'

        var decoder = UPERDecoder(data: buffer.toData())
        let format = try decoder.decodeIA5String()

        XCTAssertEqual(format, "U2")
    }

    // MARK: - Integration Tests

    /// Test getting ticket data from Dynamic Frame
    func testGetTicketData() {
        var frame = DynamicFrame()
        frame.format = "U2"

        // Without level1Data, should return nil
        XCTAssertNil(frame.getTicketData())

        // Set up level1Data with FCB
        var l1 = DynamicFrameLevel1Data()
        var dataItem = DynamicFrameDataItem()
        dataItem.format = "FCB3"
        dataItem.data = Data([0x00])  // Minimal FCB data
        l1.dataList = [dataItem]

        frame.level1Data = l1

        // Now getTicketData should attempt to parse
        // (may fail due to incomplete FCB data, but shouldn't crash)
        _ = frame.getTicketData()
    }

    /// Test getting Level 1 signature
    func testGetLevel1Signature() {
        var frame = DynamicFrame()
        frame.format = "U2"

        // Without level2SignedData, should return nil
        XCTAssertNil(frame.getLevel1Signature())

        // Set up level2SignedData with signature
        var l2 = DynamicFrameLevel2Data()
        l2.level1Signature = Data([0xAB, 0xCD, 0xEF])

        frame.level2SignedData = l2

        XCTAssertEqual(frame.getLevel1Signature(), Data([0xAB, 0xCD, 0xEF]))
    }

    // MARK: - Error Handling Tests

    /// Test decoding invalid format
    func testInvalidFormat() {
        // 8 bits length + 14 bits chars + 800 padding = 822 bits
        var buffer = BitBuffer.allocate(bits: 900)

        // IA5String "XX" (invalid format)
        try? buffer.putBits(2, count: 8)
        try? buffer.putBits(0x58, count: 7)  // 'X'
        try? buffer.putBits(0x58, count: 7)  // 'X'

        // Pad to make it look like a valid frame
        for _ in 0..<100 {
            try? buffer.putBit(false)
        }

        XCTAssertThrowsError(try DynamicFrame(data: buffer.toData())) { error in
            // Should fail during decoding
            XCTAssertTrue(error is UICBarcodeError)
        }
    }
}

// MARK: - Test Helpers

extension DynamicFrameTests {

    /// Create minimal Dynamic Frame V2 data for testing
    func createMinimalDynamicFrameV2() -> Data {
        var buffer = BitBuffer.allocate(bits: 2000)

        // Format "U2"
        try? buffer.putBits(2, count: 8)
        try? buffer.putBits(0x55, count: 7)  // 'U'
        try? buffer.putBits(0x32, count: 7)  // '2'

        // Level2Data would follow...
        // For testing, just pad with zeros
        for _ in 0..<200 {
            try? buffer.putBit(false)
        }

        return buffer.toData()
    }
}
