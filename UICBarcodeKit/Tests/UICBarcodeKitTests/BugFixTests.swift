import XCTest
@testable import UICBarcodeKit

/// Tests for specific bug fixes:
/// 1. Static Frame: 3-stage security provider priority cascade (was missing stage 2)
/// 2. Dynamic Frame: dynamicContent population from level2Data (was always nil)
///
/// Corresponding Java tests:
/// - SecurityProviderTestV1.java
/// - DynamicFrameDynamicContentTest.java / DynamicFrameDynamicContentApiTest.java
final class BugFixTests: XCTestCase {

    // MARK: - Security Provider Cascade Tests

    /// Test that all 3 stages work and securityProviderNum (stage 3) wins.
    /// Java equivalent: SecurityProviderTestV1.testSecurityProviderDecoding()
    /// which sets issuer="4711" and securityProvider="1080" then asserts securityProvider=="1080"
    func testSecurityProviderCascade_AllThreeStages() throws {
        let frame = try createStaticFrameWithFCB(
            headerIssuer: "9999",
            issuerNum: 4711,
            securityProviderNum: 1080
        )
        XCTAssertEqual(frame.securityProvider, "1080")
    }

    /// Test that issuerNum (stage 2) overrides U_HEAD issuer when no securityProviderNum
    func testSecurityProviderCascade_IssuerNumOverridesHeader() throws {
        let frame = try createStaticFrameWithFCB(
            headerIssuer: "9999",
            issuerNum: 4711
        )
        XCTAssertEqual(frame.securityProvider, "4711")
    }

    /// Test that U_HEAD issuer (stage 1) is used when ticket has no issuer/provider
    func testSecurityProviderCascade_HeaderIssuerFallback() throws {
        let frame = try createStaticFrameWithFCB(
            headerIssuer: "9999"
        )
        XCTAssertEqual(frame.securityProvider, "9999")
    }

    /// Test that issuerIA5 is preferred over issuerNum in stage 2
    func testSecurityProviderCascade_IssuerIA5PreferredOverNum() throws {
        let frame = try createStaticFrameWithFCB(
            headerIssuer: "9999",
            issuerNum: 4711,
            issuerIA5: "ABCD"
        )
        XCTAssertEqual(frame.securityProvider, "ABCD")
    }

    /// Test that securityProviderIA5 is preferred over securityProviderNum in stage 3
    func testSecurityProviderCascade_SecurityProviderIA5PreferredOverNum() throws {
        let frame = try createStaticFrameWithFCB(
            headerIssuer: "9999",
            issuerNum: 4711,
            securityProviderNum: 1080,
            securityProviderIA5: "WXYZ"
        )
        XCTAssertEqual(frame.securityProvider, "WXYZ")
    }

    // MARK: - Dynamic Content Tests

    /// Test that dynamicContent is populated from level2Data with FDC1 format.
    /// Java equivalent: DynamicFrameDynamicContentTest.testDynamicContentDecoding()
    func testDynamicContentFDC1Populated() throws {
        let frame = try createDynamicFrameWithFDC1(appId: "MyApp")

        guard let content = frame.dynamicContent,
              case .fdc1(let fdc1) = content else {
            XCTFail("Expected FDC1 dynamicContent")
            return
        }

        XCTAssertEqual(fdc1.appId, "MyApp")
    }

    /// Test FDC1 with a different appId
    func testDynamicContentFDC1AppId() throws {
        let frame = try createDynamicFrameWithFDC1(appId: "CHALLENGE")

        guard let content = frame.dynamicContent,
              case .fdc1(let fdc1) = content else {
            XCTFail("Expected FDC1 dynamicContent")
            return
        }

        XCTAssertEqual(fdc1.appId, "CHALLENGE")
    }

    /// Test that dynamicContent is nil when level2Data is absent
    func testDynamicContentNilWhenNoLevel2Data() throws {
        let frame = try createDynamicFrameV1WithoutLevel2Data()
        XCTAssertNil(frame.dynamicContent)
    }

    /// Test unknown dynamic content format stored as .unknown
    func testDynamicContentUnknownFormat() throws {
        let frame = try createDynamicFrameWithCustomLevel2Data(format: "XYZZ", data: Data([0x01, 0x02]))

        guard let content = frame.dynamicContent,
              case .unknown(let identifier, let data) = content else {
            XCTFail("Expected unknown dynamicContent")
            return
        }

        XCTAssertEqual(identifier, "XYZZ")
        XCTAssertEqual(data, Data([0x01, 0x02]))
    }

    // MARK: - Static Frame Helpers

    /// Build a complete static frame binary with U_HEAD and U_FLEX records
    private func createStaticFrameWithFCB(
        headerIssuer: String,
        issuerNum: Int? = nil,
        issuerIA5: String? = nil,
        securityProviderNum: Int? = nil,
        securityProviderIA5: String? = nil
    ) throws -> StaticFrame {
        // Build U_HEAD record
        let uheadContent = buildUHEADContent(issuer: headerIssuer)
        let uheadRecord = buildDataRecord(tag: "U_HEAD", version: "01", content: uheadContent)

        // Build U_FLEX record with UPER-encoded FCB v3 ticket
        let fcbData = try uperEncodeFCBv3(
            issuerNum: issuerNum,
            issuerIA5: issuerIA5,
            securityProviderNum: securityProviderNum,
            securityProviderIA5: securityProviderIA5
        )
        let uflexRecord = buildDataRecord(tag: "U_FLEX", version: "03", content: fcbData)

        // Combine records and compress
        var recordData = Data()
        recordData.append(uheadRecord)
        recordData.append(uflexRecord)
        let compressed = try recordData.compressed()

        // Build #UT frame (version 1)
        var frame = Data()
        frame.append("#UT".data(using: .ascii)!)
        frame.append("01".data(using: .ascii)!)
        frame.append(headerIssuer.padding(toLength: 4, withPad: " ", startingAt: 0).data(using: .ascii)!)
        frame.append("00001".data(using: .ascii)!)

        // Valid DER signature padded to 50 bytes (v1)
        var sig = Data()
        sig.append(0x30) // SEQUENCE
        sig.append(0x06) // length
        sig.append(0x02) // INTEGER
        sig.append(0x01) // r length
        sig.append(0x01) // r value
        sig.append(0x02) // INTEGER
        sig.append(0x01) // s length
        sig.append(0x01) // s value
        while sig.count < 50 { sig.append(0x00) }
        frame.append(sig)

        // Data length (4 chars) + compressed data
        frame.append(String(format: "%04d", compressed.count).data(using: .ascii)!)
        frame.append(compressed)

        return try StaticFrame(data: frame)
    }

    /// U_HEAD content: issuer(4) + identifier(20) + issuingDate(12) + flags(1) + language(2) + additionalLanguage(2)
    private func buildUHEADContent(issuer: String) -> Data {
        var content = Data()
        content.append(issuer.padding(toLength: 4, withPad: " ", startingAt: 0).data(using: .ascii)!)
        content.append(Data(repeating: 0x20, count: 20))
        content.append("010120240000".data(using: .ascii)!)
        content.append("0".data(using: .ascii)!)
        content.append("EN".data(using: .ascii)!)
        content.append("  ".data(using: .ascii)!)
        return content
    }

    /// Data record: tag(6) + version(2) + length(4) + content
    private func buildDataRecord(tag: String, version: String, content: Data) -> Data {
        let totalLength = 12 + content.count
        var record = Data()
        record.append(tag.padding(toLength: 6, withPad: " ", startingAt: 0).data(using: .ascii)!)
        record.append(version.padding(toLength: 2, withPad: "0", startingAt: 0).data(using: .ascii)!)
        record.append(String(format: "%04d", totalLength).data(using: .ascii)!)
        record.append(content)
        return record
    }

    /// UPER-encode a minimal FCB v3 UicRailTicketData with given IssuingData fields
    private func uperEncodeFCBv3(
        issuerNum: Int?,
        issuerIA5: String?,
        securityProviderNum: Int?,
        securityProviderIA5: String?
    ) throws -> Data {
        var buf = BitBuffer.allocate(bits: 512)

        // UicRailTicketData: extension marker (1 bit) + 4 optional field presence bits
        try buf.putBit(false)  // no extensions
        try buf.putBit(false)  // travelerDetail absent
        try buf.putBit(false)  // transportDocument absent
        try buf.putBit(false)  // controlDetail absent
        try buf.putBit(false)  // extensionData absent

        // IssuingData: extension marker (1 bit) + 13 optional field presence bits
        try buf.putBit(false) // no extensions
        try buf.putBit(securityProviderNum != nil) // [0] securityProviderNum
        try buf.putBit(securityProviderIA5 != nil) // [1] securityProviderIA5
        try buf.putBit(issuerNum != nil)           // [2] issuerNum
        try buf.putBit(issuerIA5 != nil)           // [3] issuerIA5
        for _ in 4..<13 {
            try buf.putBit(false) // [4]-[12] all absent
        }

        // Encode present optional fields in order
        if let num = securityProviderNum {
            try buf.putBits(UInt64(num - 1), count: 15) // 1..32000
        }
        if let ia5 = securityProviderIA5 {
            try uperEncodeIA5String(ia5, to: &buf)
        }
        if let num = issuerNum {
            try buf.putBits(UInt64(num - 1), count: 15) // 1..32000
        }
        if let ia5 = issuerIA5 {
            try uperEncodeIA5String(ia5, to: &buf)
        }

        // Mandatory fields
        try buf.putBits(UInt64(2024 - 2016), count: 8) // issuingYear: 2016..2269
        try buf.putBits(0, count: 9)                    // issuingDay: 1..366 (value=1)
        try buf.putBits(0, count: 11)                   // issuingTime: 0..1439
        try buf.putBit(false)                           // specimen
        try buf.putBit(false)                           // securePaperTicket
        try buf.putBit(true)                            // activated

        let byteCount = (buf.position + 7) / 8
        return Data(buf.toData().prefix(byteCount))
    }

    // MARK: - Dynamic Frame Helpers

    /// Create a Dynamic Frame V1 with FDC1 dynamic content in level2Data
    private func createDynamicFrameWithFDC1(appId: String) throws -> DynamicFrame {
        let fdc1Bytes = try uperEncodeFDC1(appId: appId)
        return try createDynamicFrameWithCustomLevel2Data(format: "FDC1", data: fdc1Bytes)
    }

    /// Create a Dynamic Frame V1 with custom level2Data
    private func createDynamicFrameWithCustomLevel2Data(format: String, data: Data) throws -> DynamicFrame {
        var buf = BitBuffer.allocate(bits: 4096)

        // UicBarcodeHeader: 1 optional field (level2Signature)
        try buf.putBit(false) // level2Signature absent

        // format: IA5String "U1"
        try uperEncodeIA5String("U1", to: &buf)

        // Level2DataType: 2 optional fields
        try buf.putBit(false) // level1Signature absent
        try buf.putBit(true)  // level2Data present

        // Level1DataType (V1): 8 optional fields, all absent
        for _ in 0..<8 { try buf.putBit(false) }
        // dataSequence: count = 0
        try buf.putBit(false)
        try buf.putBits(0, count: 7)

        // level2Data (DataType): format + data as OCTET STRING
        try uperEncodeIA5String(format, to: &buf)
        try uperEncodeOctetString(data, to: &buf)

        let byteCount = (buf.position + 7) / 8
        return try DynamicFrame(data: Data(buf.toData().prefix(byteCount)))
    }

    /// Create a Dynamic Frame V1 without level2Data
    private func createDynamicFrameV1WithoutLevel2Data() throws -> DynamicFrame {
        var buf = BitBuffer.allocate(bits: 2048)

        try buf.putBit(false) // level2Signature absent
        try uperEncodeIA5String("U1", to: &buf)

        // Level2DataType: both optional fields absent
        try buf.putBit(false) // level1Signature absent
        try buf.putBit(false) // level2Data absent

        // Level1DataType (V1): 8 optional fields, all absent
        for _ in 0..<8 { try buf.putBit(false) }
        try buf.putBit(false)
        try buf.putBits(0, count: 7)

        let byteCount = (buf.position + 7) / 8
        return try DynamicFrame(data: Data(buf.toData().prefix(byteCount)))
    }

    /// UPER-encode a minimal DynamicContentFDC1 with just appId
    private func uperEncodeFDC1(appId: String) throws -> Data {
        var buf = BitBuffer.allocate(bits: 1024)

        // Extension marker
        try buf.putBit(false)

        // 5 optional fields
        try buf.putBit(true)  // appId present
        try buf.putBit(false) // timeStamp absent
        try buf.putBit(false) // geoCoordinate absent
        try buf.putBit(false) // dynamicContentResponseToChallenge absent
        try buf.putBit(false) // dynamicContentExtension absent

        // appId: IA5String
        try uperEncodeIA5String(appId, to: &buf)

        let byteCount = (buf.position + 7) / 8
        return Data(buf.toData().prefix(byteCount))
    }

    // MARK: - UPER Encoding Primitives

    private func uperEncodeIA5String(_ value: String, to buf: inout BitBuffer) throws {
        try buf.putBit(false) // length < 128
        try buf.putBits(UInt64(value.count), count: 7)
        for byte in value.utf8 {
            try buf.putBits(UInt64(byte), count: 7)
        }
    }

    private func uperEncodeOctetString(_ data: Data, to buf: inout BitBuffer) throws {
        try buf.putBit(false) // length < 128
        try buf.putBits(UInt64(data.count), count: 7)
        for byte in data {
            try buf.putBits(UInt64(byte), count: 8)
        }
    }
}
