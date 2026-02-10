import XCTest
import CryptoKit
@testable import UICBarcodeKit

/// Tests for Dynamic Frame validation, convenience accessors, and TimeStamp conversions
final class DynamicFrameValidationTests: XCTestCase {

    // MARK: - Helper: Build a signed Dynamic Frame

    /// Build a minimal V2 dynamic frame, encode + decode for round-trip, then sign Level 1.
    /// Returns (frame, publicKeyDER)
    private func buildSignedFrame() throws -> (DynamicFrame, Data) {
        let privateKey = P256.Signing.PrivateKey()
        let publicKeyDER = privateKey.publicKey.derRepresentation

        // Build frame
        var frame = DynamicFrame()
        frame.format = DynamicFrameVersion.v2.rawValue

        var level1 = DynamicFrameLevel1Data()
        level1.securityProviderNum = 1080
        level1.securityProviderIA5 = "1080"
        level1.keyId = 42
        level1.level1SigningAlg = "1.2.840.10045.4.3.2" // ECDSA SHA-256
        level1.endOfValidityYear = 2026
        level1.endOfValidityDay = 100
        level1.endOfValidityTime = 720 // 12:00
        level1.validityDuration = 3600

        var dataItem = DynamicFrameDataItem()
        dataItem.format = "FCB3"
        dataItem.data = Data([0x01, 0x02, 0x03])
        level1.dataList = [dataItem]

        frame.level1Data = level1

        var level2 = DynamicFrameLevel2Data()
        level2.level1Data = level1
        frame.level2SignedData = level2

        // Encode and decode to populate encodedData
        let encoded = try frame.encode()
        var decoded = try DynamicFrame(data: encoded)

        // Sign level 1
        try decoded.signLevel1(privateKey: privateKey)

        return (decoded, publicKeyDER)
    }

    // MARK: - validateLevel1 Tests

    func testValidateLevel1_valid() throws {
        let (frame, publicKey) = try buildSignedFrame()
        let result = frame.validateLevel1(publicKey: publicKey)
        XCTAssertEqual(result, .valid)
    }

    func testValidateLevel1_invalidSignature() throws {
        var (frame, publicKey) = try buildSignedFrame()

        // Corrupt the signature
        var sig = frame.level2SignedData!.level1Signature!
        sig[0] ^= 0xFF
        frame.level2SignedData?.level1Signature = sig

        let result = frame.validateLevel1(publicKey: publicKey)
        // Could be invalidSignature or encodingError depending on whether the corrupted DER is still parseable
        XCTAssertTrue(result == .invalidSignature || result == .encodingError)
    }

    func testValidateLevel1_signatureMissing() throws {
        var (frame, publicKey) = try buildSignedFrame()
        frame.level2SignedData?.level1Signature = nil

        let result = frame.validateLevel1(publicKey: publicKey)
        XCTAssertEqual(result, .signatureMissing)
    }

    func testValidateLevel1_signedDataMissing() throws {
        var frame = DynamicFrame()
        frame.format = DynamicFrameVersion.v2.rawValue
        // No level1Data → no encodedData

        let privateKey = P256.Signing.PrivateKey()
        let result = frame.validateLevel1(publicKey: privateKey.publicKey.derRepresentation)
        XCTAssertEqual(result, .signedDataMissing)
    }

    func testValidateLevel1_withExplicitAlgorithmOID() throws {
        let (frame, publicKey) = try buildSignedFrame()
        let result = frame.validateLevel1(publicKey: publicKey, algorithmOID: "1.2.840.10045.4.3.2")
        XCTAssertEqual(result, .valid)
    }

    func testValidateLevel1_wrongKey() throws {
        let (frame, _) = try buildSignedFrame()

        // Use a different key
        let otherKey = P256.Signing.PrivateKey()
        let result = frame.validateLevel1(publicKey: otherKey.publicKey.derRepresentation)
        XCTAssertTrue(result == .invalidSignature || result == .encodingError)
    }

    // MARK: - validateLevel2 Tests

    func testValidateLevel2_keyMissing() throws {
        var (frame, _) = try buildSignedFrame()
        frame.level1Data?.level2publicKey = nil
        let result = frame.validateLevel2()
        XCTAssertEqual(result, .keyMissing)
    }

    func testValidateLevel2_signatureMissing() throws {
        var (frame, _) = try buildSignedFrame()
        // Set a level2publicKey but no level2Signature
        frame.level1Data?.level2publicKey = P256.Signing.PrivateKey().publicKey.derRepresentation
        frame.level2Signature = nil
        let result = frame.validateLevel2()
        XCTAssertEqual(result, .signatureMissing)
    }

    func testValidateLevel2_valid() throws {
        let l2PrivateKey = P256.Signing.PrivateKey()
        let l2PublicKeyDER = l2PrivateKey.publicKey.derRepresentation

        let l1PrivateKey = P256.Signing.PrivateKey()

        // Build frame
        var frame = DynamicFrame()
        frame.format = DynamicFrameVersion.v2.rawValue

        var level1 = DynamicFrameLevel1Data()
        level1.securityProviderNum = 1080
        level1.level1SigningAlg = "1.2.840.10045.4.3.2"
        level1.level2SigningAlg = "1.2.840.10045.4.3.2"
        level1.level2publicKey = l2PublicKeyDER

        var dataItem = DynamicFrameDataItem()
        dataItem.format = "FCB3"
        dataItem.data = Data([0x01, 0x02, 0x03])
        level1.dataList = [dataItem]

        frame.level1Data = level1

        var level2 = DynamicFrameLevel2Data()
        level2.level1Data = level1
        frame.level2SignedData = level2

        // Encode + decode
        let encoded = try frame.encode()
        var decoded = try DynamicFrame(data: encoded)

        // Sign level 1 first
        try decoded.signLevel1(privateKey: l1PrivateKey)

        // Sign level 2
        try decoded.signLevel2(privateKey: l2PrivateKey)

        let result = decoded.validateLevel2()
        XCTAssertEqual(result, .valid)
    }

    // MARK: - TimeStamp Tests

    func testTimeStampToDate() {
        var ts = TimeStamp()
        ts.day = 45 // February 14
        ts.secondOfDay = 36000 // 10:00:00

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        // Use a reference date in the same year
        var refComponents = DateComponents()
        refComponents.year = 2026
        refComponents.month = 2
        refComponents.day = 1
        let refDate = calendar.date(from: refComponents)!

        let date = ts.toDate(referenceDate: refDate)

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 2)
        XCTAssertEqual(components.day, 14)
        XCTAssertEqual(components.hour, 10)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func testTimeStampToDate_yearBoundary() {
        // Day 360 referenced from January → previous year
        var ts = TimeStamp()
        ts.day = 360
        ts.secondOfDay = 0

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        // Reference date in January (day ~15)
        var refComponents = DateComponents()
        refComponents.year = 2026
        refComponents.month = 1
        refComponents.day = 15
        let refDate = calendar.date(from: refComponents)!

        let date = ts.toDate(referenceDate: refDate)

        let components = calendar.dateComponents([.year], from: date)
        XCTAssertEqual(components.year, 2025, "Day 360 in January should resolve to previous year")
    }

    func testTimeStampToDate_yearBoundaryForward() {
        // Day 5 referenced from late December → next year
        var ts = TimeStamp()
        ts.day = 5
        ts.secondOfDay = 0

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        // Reference date in late December (day ~360)
        var refComponents = DateComponents()
        refComponents.year = 2025
        refComponents.month = 12
        refComponents.day = 28
        let refDate = calendar.date(from: refComponents)!

        let date = ts.toDate(referenceDate: refDate)

        let components = calendar.dateComponents([.year], from: date)
        XCTAssertEqual(components.year, 2026, "Day 5 in late December should resolve to next year")
    }

    func testTimeStampInitFromDate() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 15
        components.hour = 14
        components.minute = 30
        components.second = 45
        let date = calendar.date(from: components)!

        let ts = TimeStamp(date: date)

        // March 15 = day 74
        XCTAssertEqual(ts.day, 74)
        XCTAssertEqual(ts.secondOfDay, 14 * 3600 + 30 * 60 + 45)
    }

    func testTimeStampRoundTrip() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        var components = DateComponents()
        components.year = 2026
        components.month = 6
        components.day = 20
        components.hour = 8
        components.minute = 15
        components.second = 30
        let originalDate = calendar.date(from: components)!

        let ts = TimeStamp(date: originalDate)
        let resultDate = ts.toDate(referenceDate: originalDate)

        // Should round-trip exactly (within 1 second tolerance)
        let diff = abs(resultDate.timeIntervalSince(originalDate))
        XCTAssertLessThan(diff, 1.0, "TimeStamp round-trip should preserve date")
    }

    func testTimeStampNow() {
        let ts = TimeStamp.now()

        // Day should be valid (1..366)
        XCTAssertGreaterThanOrEqual(ts.day, 1)
        XCTAssertLessThanOrEqual(ts.day, 366)

        // Second should be valid (0..86399)
        XCTAssertGreaterThanOrEqual(ts.secondOfDay, 0)
        XCTAssertLessThanOrEqual(ts.secondOfDay, 86399)
    }

    // MARK: - endOfValidity Tests

    func testEndOfValidity() throws {
        let (frame, _) = try buildSignedFrame()

        // Frame has endOfValidityYear=2026, endOfValidityDay=100, endOfValidityTime=720
        guard let eov = frame.endOfValidity else {
            XCTFail("endOfValidity should not be nil")
            return
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: eov)
        XCTAssertEqual(components.year, 2026)

        // Day 100 of 2026 = April 10
        XCTAssertEqual(components.month, 4)
        XCTAssertEqual(components.day, 10)

        // 720 minutes = 12:00
        XCTAssertEqual(components.hour, 12)
        XCTAssertEqual(components.minute, 0)
    }

    func testEndOfValidity_nilWhenNoYear() {
        var frame = DynamicFrame()
        frame.format = DynamicFrameVersion.v2.rawValue
        frame.level1Data = DynamicFrameLevel1Data()
        // No endOfValidityYear/Day set

        XCTAssertNil(frame.endOfValidity)
    }

    // MARK: - Convenience Accessor Tests

    func testSecurityProvider_prefersIA5() throws {
        let (frame, _) = try buildSignedFrame()

        // Frame has both securityProviderNum=1080 and securityProviderIA5="1080"
        XCTAssertEqual(frame.securityProvider, "1080")
    }

    func testSecurityProvider_fallsBackToNum() {
        var frame = DynamicFrame()
        frame.format = DynamicFrameVersion.v2.rawValue
        var level1 = DynamicFrameLevel1Data()
        level1.securityProviderNum = 1234
        // No IA5
        frame.level1Data = level1

        XCTAssertEqual(frame.securityProvider, "1234")
    }

    func testSecurityProvider_nilWhenNone() {
        var frame = DynamicFrame()
        frame.format = DynamicFrameVersion.v2.rawValue
        frame.level1Data = DynamicFrameLevel1Data()

        XCTAssertNil(frame.securityProvider)
    }

    func testLevel1KeyId() throws {
        let (frame, _) = try buildSignedFrame()
        XCTAssertEqual(frame.level1KeyId, 42)
    }

    func testFrameVersion() throws {
        let (frame, _) = try buildSignedFrame()
        XCTAssertEqual(frame.version, .v2)
    }

    func testValidityDurationSeconds() throws {
        let (frame, _) = try buildSignedFrame()
        XCTAssertEqual(frame.validityDurationSeconds, 3600)
    }

    // MARK: - DecodedBarcode Convenience Tests

    func testDecodedBarcode_dynamicContentFDC1() {
        // Build a DecodedBarcode with dynamic content
        var frame = DynamicFrame()
        frame.format = DynamicFrameVersion.v2.rawValue

        var fdc1 = DynamicContentFDC1()
        fdc1.appId = "TestApp"
        frame.dynamicContent = .fdc1(fdc1)

        let barcode = DecodedBarcode(
            frameType: .dynamicFrame(version: .v2),
            ticket: nil,
            signatureData: SignatureData(),
            fcbVersion: nil,
            rawFrame: frame
        )

        XCTAssertEqual(barcode.dynamicContentFDC1?.appId, "TestApp")
    }

    func testDecodedBarcode_dynamicContentFDC1_nil() {
        // Non-dynamic barcode
        let barcode = DecodedBarcode(
            frameType: .ssbFrame,
            ticket: nil,
            signatureData: SignatureData(),
            fcbVersion: nil,
            rawFrame: SSBFrame()
        )

        XCTAssertNil(barcode.dynamicContentFDC1)
    }

    func testDynamicContentFDC1_timeStampDate() {
        var fdc1 = DynamicContentFDC1()
        var ts = TimeStamp()
        ts.day = 1
        ts.secondOfDay = 0
        fdc1.timeStamp = ts

        XCTAssertNotNil(fdc1.timeStampDate)
    }

    func testDynamicContentFDC1_timeStampDate_nil() {
        let fdc1 = DynamicContentFDC1()
        XCTAssertNil(fdc1.timeStampDate)
    }

    // MARK: - SignatureValidationResult Enum Tests

    func testSignatureValidationResult_rawValues() {
        XCTAssertEqual(SignatureValidationResult.valid.rawValue, 0)
        XCTAssertEqual(SignatureValidationResult.invalidSignature.rawValue, 1)
        XCTAssertEqual(SignatureValidationResult.keyMissing.rawValue, 2)
        XCTAssertEqual(SignatureValidationResult.signatureMissing.rawValue, 3)
        XCTAssertEqual(SignatureValidationResult.signedDataMissing.rawValue, 4)
        XCTAssertEqual(SignatureValidationResult.algorithmMissing.rawValue, 5)
        XCTAssertEqual(SignatureValidationResult.encodingError.rawValue, 6)
    }
}
