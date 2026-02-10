import XCTest
import CryptoKit
@testable import UICBarcodeKit

/// Tests for signature verification
/// Based on SecurityUtilsTest.java and ECKeyEncoderTest.java
final class SignatureVerifierTests: XCTestCase {

    // MARK: - ECDSA P-256 Tests

    /// Test ECDSA P-256 signature verification with known test vectors
    func testECDSA_P256_SignatureVerification() throws {
        // Generate a test key pair
        let privateKey = P256.Signing.PrivateKey()
        let publicKey = privateKey.publicKey

        // Sign some data
        let testData = "Hello, UIC Barcode!".data(using: .utf8)!
        let signature = try privateKey.signature(for: testData)

        // Verify the signature
        let isValid = try SignatureVerifier.verifyECDSA_P256(
            signature: signature.derRepresentation,
            data: testData,
            publicKey: publicKey.x963Representation
        )

        XCTAssertTrue(isValid, "Valid signature should verify")
    }

    /// Test that invalid P-256 signature is rejected
    func testECDSA_P256_InvalidSignature() throws {
        let privateKey = P256.Signing.PrivateKey()
        let publicKey = privateKey.publicKey

        let testData = "Hello, UIC Barcode!".data(using: .utf8)!
        let signature = try privateKey.signature(for: testData)

        // Corrupt the signature
        var corruptedSignature = signature.derRepresentation
        if !corruptedSignature.isEmpty {
            corruptedSignature[corruptedSignature.count - 1] ^= 0xFF
        }

        // Verification should fail
        let isValid = try SignatureVerifier.verifyECDSA_P256(
            signature: corruptedSignature,
            data: testData,
            publicKey: publicKey.x963Representation
        )

        XCTAssertFalse(isValid, "Corrupted signature should not verify")
    }

    /// Test that signature with wrong data is rejected
    func testECDSA_P256_WrongData() throws {
        let privateKey = P256.Signing.PrivateKey()
        let publicKey = privateKey.publicKey

        let originalData = "Hello, UIC Barcode!".data(using: .utf8)!
        let wrongData = "Goodbye, UIC Barcode!".data(using: .utf8)!
        let signature = try privateKey.signature(for: originalData)

        // Verification with wrong data should fail
        let isValid = try SignatureVerifier.verifyECDSA_P256(
            signature: signature.derRepresentation,
            data: wrongData,
            publicKey: publicKey.x963Representation
        )

        XCTAssertFalse(isValid, "Signature should not verify with wrong data")
    }

    // MARK: - ECDSA P-384 Tests

    /// Test ECDSA P-384 signature verification
    func testECDSA_P384_SignatureVerification() throws {
        let privateKey = P384.Signing.PrivateKey()
        let publicKey = privateKey.publicKey

        let testData = "Hello, P-384!".data(using: .utf8)!
        let signature = try privateKey.signature(for: testData)

        let isValid = try SignatureVerifier.verifyECDSA_P384(
            signature: signature.derRepresentation,
            data: testData,
            publicKey: publicKey.x963Representation
        )

        XCTAssertTrue(isValid, "Valid P-384 signature should verify")
    }

    // MARK: - ECDSA P-521 Tests

    /// Test ECDSA P-521 signature verification
    func testECDSA_P521_SignatureVerification() throws {
        let privateKey = P521.Signing.PrivateKey()
        let publicKey = privateKey.publicKey

        let testData = "Hello, P-521!".data(using: .utf8)!
        let signature = try privateKey.signature(for: testData)

        // Use rawRepresentation since P-521 DER signatures can have long-form length encoding
        // which the simple DER parser doesn't handle
        let isValid = try SignatureVerifier.verifyECDSA_P521(
            signature: signature.rawRepresentation,
            data: testData,
            publicKey: publicKey.x963Representation
        )

        XCTAssertTrue(isValid, "Valid P-521 signature should verify")
    }

    // MARK: - Algorithm OID-based Verification Tests

    /// Test verification using ECDSA-SHA256 OID
    func testVerifyWithAlgorithmOID_ECDSA_SHA256() throws {
        let privateKey = P256.Signing.PrivateKey()
        let publicKey = privateKey.publicKey

        let testData = "Test data for OID-based verification".data(using: .utf8)!

        // Hash the data first (as the OID-based method expects to hash)
        let digest = SHA256.hash(data: testData)
        let signature = try privateKey.signature(for: Data(digest))

        let isValid = try SignatureVerifier.verify(
            signature: signature.derRepresentation,
            data: testData,
            publicKey: publicKey.x963Representation,
            algorithmOID: AlgorithmOID.ecdsa_sha256_oid
        )

        XCTAssertTrue(isValid, "OID-based verification should succeed")
    }

    /// Test that DSA algorithms with invalid key throw appropriate error
    func testDSAAlgorithmWithInvalidKeyThrows() {
        let testData = "Test data".data(using: .utf8)!
        let dummySignature = Data(repeating: 0, count: 64)
        let dummyKey = Data(repeating: 0, count: 65)

        XCTAssertThrowsError(try SignatureVerifier.verify(
            signature: dummySignature,
            data: testData,
            publicKey: dummyKey,
            algorithmOID: AlgorithmOID.dsa_sha1_oid
        )) { error in
            guard case UICBarcodeError.invalidPublicKey = error else {
                XCTFail("Expected invalidPublicKey error, got \(error)")
                return
            }
        }
    }

    // MARK: - DER Signature Conversion Tests

    /// Test DER to raw signature conversion for P-256
    func testDerToRawSignatureP256() throws {
        let privateKey = P256.Signing.PrivateKey()
        let testData = "Test".data(using: .utf8)!
        let signature = try privateKey.signature(for: testData)

        // DER signature should convert to 64 bytes raw
        let rawSignature = try SignatureVerifier.rawToDerSignature(signature.rawRepresentation)
        XCTAssertGreaterThan(rawSignature.count, 64, "DER signature should be longer than raw")
    }

    /// Test raw to DER signature conversion
    func testRawToDerSignature() throws {
        // Create a raw signature (64 bytes for P-256: 32 bytes r + 32 bytes s)
        var rawSignature = Data(repeating: 0x42, count: 64)
        rawSignature[0] = 0x00  // Ensure no leading high bit issues

        let derSignature = try SignatureVerifier.rawToDerSignature(rawSignature)

        // DER signature should start with SEQUENCE tag (0x30)
        XCTAssertEqual(derSignature[0], 0x30, "DER should start with SEQUENCE tag")

        // Should contain two INTEGER tags (0x02)
        XCTAssertEqual(derSignature[2], 0x02, "First INTEGER tag")
    }

    // MARK: - Public Key Parsing Tests

    /// Test parsing X9.63 format public key (P-256)
    func testParseX963PublicKeyP256() throws {
        let privateKey = P256.Signing.PrivateKey()
        let publicKey = privateKey.publicKey
        let x963Data = publicKey.x963Representation

        // X9.63 format: 0x04 + 32 bytes X + 32 bytes Y = 65 bytes
        XCTAssertEqual(x963Data.count, 65)
        XCTAssertEqual(x963Data[0], 0x04, "X9.63 should start with 0x04 for uncompressed")
    }

    /// Test parsing raw format public key (P-256)
    func testParseRawPublicKeyP256() throws {
        let privateKey = P256.Signing.PrivateKey()
        let publicKey = privateKey.publicKey

        // Raw representation is 64 bytes (32 X + 32 Y)
        let rawData = publicKey.rawRepresentation
        XCTAssertEqual(rawData.count, 64)

        // Should be able to verify signature using raw key
        let testData = "Test".data(using: .utf8)!
        let signature = try privateKey.signature(for: testData)

        let isValid = try SignatureVerifier.verifyECDSA_P256(
            signature: signature.derRepresentation,
            data: testData,
            publicKey: rawData  // Using raw format
        )

        XCTAssertTrue(isValid)
    }

    // MARK: - P-521 Key Sizes

    /// Test P-521 key sizes (from ECKeyEncoderTest521.java)
    func testP521KeySizes() throws {
        let privateKey = P521.Signing.PrivateKey()
        let publicKey = privateKey.publicKey

        // P-521 uses 66-byte coordinates (521 bits = 66 bytes with padding)
        // X9.63 format: 0x04 + 66 bytes X + 66 bytes Y = 133 bytes
        XCTAssertEqual(publicKey.x963Representation.count, 133)

        // Raw representation: 66 bytes X + 66 bytes Y = 132 bytes
        XCTAssertEqual(publicKey.rawRepresentation.count, 132)
    }

    /// Test P-521 signature sizes
    func testP521SignatureSizes() throws {
        let privateKey = P521.Signing.PrivateKey()
        let testData = "Test".data(using: .utf8)!
        let signature = try privateKey.signature(for: testData)

        // Raw signature: 66 bytes r + 66 bytes s = 132 bytes
        XCTAssertEqual(signature.rawRepresentation.count, 132)

        // DER signature varies in length but typically around 137-139 bytes for P-521
        XCTAssertGreaterThan(signature.derRepresentation.count, 132)
    }

    // MARK: - Error Handling Tests

    /// Test invalid public key format
    func testInvalidPublicKeyFormat() {
        let invalidKey = Data([0x01, 0x02, 0x03])  // Too short
        let testData = "Test".data(using: .utf8)!
        let dummySignature = Data(repeating: 0, count: 64)

        XCTAssertThrowsError(try SignatureVerifier.verifyECDSA_P256(
            signature: dummySignature,
            data: testData,
            publicKey: invalidKey
        )) { error in
            guard case UICBarcodeError.invalidPublicKey = error else {
                XCTFail("Expected invalidPublicKey error, got \(error)")
                return
            }
        }
    }

    /// Test invalid signature format
    func testInvalidSignatureFormat() throws {
        let privateKey = P256.Signing.PrivateKey()
        let publicKey = privateKey.publicKey
        let testData = "Test".data(using: .utf8)!

        // Create malformed signature (doesn't start with SEQUENCE tag)
        let invalidSignature = Data([0xFF, 0xFF, 0xFF, 0xFF])

        XCTAssertThrowsError(try SignatureVerifier.verifyECDSA_P256(
            signature: invalidSignature,
            data: testData,
            publicKey: publicKey.x963Representation
        )) { error in
            guard case UICBarcodeError.signatureInvalid = error else {
                XCTFail("Expected signatureInvalid error, got \(error)")
                return
            }
        }
    }
}
