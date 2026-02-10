import XCTest
import CryptoKit
@testable import UICBarcodeKit

/// Tests for DSA signature verification
/// Based on SignatureValidationDBTicketTest.java and StaticFrameBarcodeSignatureAlgorithmDetectionTest.java
final class DSAVerifierTests: XCTestCase {

    // MARK: - BigUInt Basic Arithmetic Tests

    func testBigUIntFromUInt() {
        let a = BigUInt(42)
        let b = BigUInt(0)
        XCTAssertEqual(a, BigUInt(42))
        XCTAssertTrue(b.isZero)
        XCTAssertFalse(a.isZero)
    }

    func testBigUIntFromData() {
        // Big-endian bytes: 0x0100 = 256
        let data = Data([0x01, 0x00])
        let n = BigUInt(data: data)
        XCTAssertEqual(n, BigUInt(256))

        // Single byte
        let data2 = Data([0xFF])
        let n2 = BigUInt(data: data2)
        XCTAssertEqual(n2, BigUInt(255))

        // Empty data
        let empty = BigUInt(data: Data())
        XCTAssertTrue(empty.isZero)

        // Leading zeros should be ignored
        let data3 = Data([0x00, 0x00, 0x01])
        let n3 = BigUInt(data: data3)
        XCTAssertEqual(n3, BigUInt(1))
    }

    func testBigUIntComparison() {
        let a = BigUInt(100)
        let b = BigUInt(200)
        let c = BigUInt(100)

        XCTAssertTrue(a < b)
        XCTAssertFalse(b < a)
        XCTAssertFalse(a < c)
        XCTAssertEqual(a, c)
        XCTAssertTrue(a <= c)
        XCTAssertTrue(a >= c)
    }

    func testBigUIntBasicArithmetic() {
        let a = BigUInt(100)
        let b = BigUInt(42)

        // Addition
        XCTAssertEqual(a + b, BigUInt(142))
        XCTAssertEqual(BigUInt(0) + a, a)

        // Subtraction
        XCTAssertEqual(a - b, BigUInt(58))
        XCTAssertEqual(a - a, BigUInt(0))

        // Multiplication
        XCTAssertEqual(a * b, BigUInt(4200))
        XCTAssertEqual(a * BigUInt(0), BigUInt(0))
        XCTAssertEqual(a * BigUInt(1), a)

        // Division
        XCTAssertEqual(a / b, BigUInt(2))
        XCTAssertEqual(a / a, BigUInt(1))

        // Modulo
        XCTAssertEqual(a % b, BigUInt(16)) // 100 % 42 = 16
        XCTAssertEqual(BigUInt(10) % BigUInt(3), BigUInt(1))
    }

    func testBigUIntLargeArithmetic() {
        // Test with values that overflow a single UInt
        let a = BigUInt(data: Data([0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])) // 2^64
        let b = BigUInt(1)
        let c = a + b // 2^64 + 1

        XCTAssertTrue(c > a)
        XCTAssertEqual(c - a, b)
        XCTAssertEqual(c - b, a)

        // Multiplication of large numbers
        let d = BigUInt(data: Data([0xFF, 0xFF, 0xFF, 0xFF])) // 2^32 - 1
        let e = d * d // (2^32 - 1)^2
        let expected = BigUInt(data: Data([0xFF, 0xFF, 0xFF, 0xFE, 0x00, 0x00, 0x00, 0x01]))
        XCTAssertEqual(e, expected)
    }

    func testBigUIntModPow() {
        // 2^10 mod 1000 = 1024 mod 1000 = 24
        let result = BigUInt.modPow(BigUInt(2), BigUInt(10), BigUInt(1000))
        XCTAssertEqual(result, BigUInt(24))

        // 3^7 mod 50 = 2187 mod 50 = 37
        let result2 = BigUInt.modPow(BigUInt(3), BigUInt(7), BigUInt(50))
        XCTAssertEqual(result2, BigUInt(37))

        // Edge case: anything^0 mod n = 1 (for n > 1)
        let result3 = BigUInt.modPow(BigUInt(5), BigUInt(0), BigUInt(7))
        XCTAssertEqual(result3, BigUInt(1))

        // Large modPow: 7^256 mod 13
        let result4 = BigUInt.modPow(BigUInt(7), BigUInt(256), BigUInt(13))
        // 7^1 mod 13 = 7, 7^2 mod 13 = 10, 7^12 mod 13 = 1 (Fermat's)
        // 256 = 12*21 + 4, so 7^256 mod 13 = 7^4 mod 13 = 2401 mod 13 = 9
        XCTAssertEqual(result4, BigUInt(9))
    }

    func testBigUIntModInverse() {
        // 3 * x ≡ 1 (mod 7) → x = 5 (since 3*5 = 15 ≡ 1 mod 7)
        let inv = BigUInt.modInverse(BigUInt(3), BigUInt(7))
        XCTAssertNotNil(inv)
        XCTAssertEqual(inv, BigUInt(5))

        // Verify: 3 * 5 mod 7 = 1
        XCTAssertEqual((BigUInt(3) * inv!) % BigUInt(7), BigUInt(1))

        // 7 * x ≡ 1 (mod 11) → x = 8 (since 7*8 = 56 ≡ 1 mod 11)
        let inv2 = BigUInt.modInverse(BigUInt(7), BigUInt(11))
        XCTAssertNotNil(inv2)
        XCTAssertEqual(inv2, BigUInt(8))

        // No inverse: gcd(2, 4) = 2 ≠ 1
        let inv3 = BigUInt.modInverse(BigUInt(2), BigUInt(4))
        XCTAssertNil(inv3)
    }

    func testBigUIntBitLength() {
        XCTAssertEqual(BigUInt(0).bitLength, 0)
        XCTAssertEqual(BigUInt(1).bitLength, 1)
        XCTAssertEqual(BigUInt(2).bitLength, 2)
        XCTAssertEqual(BigUInt(255).bitLength, 8)
        XCTAssertEqual(BigUInt(256).bitLength, 9)
    }

    // MARK: - DSA Verification with Known Test Vectors

    func testDSAVerification_DirectVectors() {
        // Small test vector for DSA verification
        // Using small primes for quick testing
        // p = 23, q = 11, g = 4 (4 is a generator of order 11 mod 23)
        // Private key x = 7
        // Public key y = g^x mod p = 4^7 mod 23 = 16384 mod 23 = 18

        let p = BigUInt(23)
        let q = BigUInt(11)
        let g = BigUInt(4)
        let y = BigUInt(data: Data([18])) // g^x mod p

        // Verify g has order q mod p: g^q mod p should be 1
        let gOrder = BigUInt.modPow(g, q, p)
        XCTAssertEqual(gOrder, BigUInt(1), "g should have order q mod p")

        let publicKey = DSAPublicKey(p: p, q: q, g: g, y: y)

        // For the signature, we need: k (random), r = (g^k mod p) mod q, s = k^-1 * (H + x*r) mod q
        // Let's use k = 3
        // r = (4^3 mod 23) mod 11 = (64 mod 23) mod 11 = 18 mod 11 = 7
        // For H = 5 (our "hash"), x = 7:
        // s = k^-1 * (H + x*r) mod q = 3^-1 * (5 + 7*7) mod 11 = 4 * (5 + 49) mod 11 = 4 * (54 mod 11) mod 11 = 4 * 10 mod 11 = 40 mod 11 = 7
        // Note: 3^-1 mod 11 = 4 (since 3*4=12 ≡ 1 mod 11)

        let r = BigUInt(7)
        let s = BigUInt(7)
        let hashData = Data([5]) // H = 5

        let result = DSAVerifier.verifyRaw(hash: hashData, r: r, s: s, publicKey: publicKey)
        XCTAssertTrue(result, "DSA verification should succeed with correct parameters")

        // Test with wrong r value (signature tampering)
        let wrongR = BigUInt(3)
        let resultWrong = DSAVerifier.verifyRaw(hash: hashData, r: wrongR, s: s, publicKey: publicKey)
        XCTAssertFalse(resultWrong, "DSA verification should fail with wrong r")
    }

    // MARK: - DSA Public Key DER Parsing

    func testDSAPublicKeyParsing() throws {
        // Parse the DB certificate to extract DSA key
        guard let certData = Data(base64Encoded: Self.dbKey2Certificate) else {
            XCTFail("Failed to decode Base64 certificate")
            return
        }

        let dsaKey = try DSAVerifier.parsePublicKeyFromCertificate(certData)

        // Verify the key parameters are non-zero and have reasonable sizes
        XCTAssertFalse(dsaKey.p.isZero, "p should not be zero")
        XCTAssertFalse(dsaKey.q.isZero, "q should not be zero")
        XCTAssertFalse(dsaKey.g.isZero, "g should not be zero")
        XCTAssertFalse(dsaKey.y.isZero, "y should not be zero")

        // For a 2048-bit DSA key, p should be ~2048 bits
        XCTAssertGreaterThan(dsaKey.p.bitLength, 2000, "p should be approximately 2048 bits")
        XCTAssertLessThanOrEqual(dsaKey.p.bitLength, 2048, "p should be at most 2048 bits")

        // q should be ~256 bits for DSA-SHA256
        XCTAssertGreaterThan(dsaKey.q.bitLength, 200, "q should be approximately 256 bits")
        XCTAssertLessThanOrEqual(dsaKey.q.bitLength, 256, "q should be at most 256 bits")
    }

    func testDSAPublicKeyParsing_SecondCert() throws {
        guard let certData = Data(base64Encoded: Self.dbKey6Certificate) else {
            XCTFail("Failed to decode Base64 certificate")
            return
        }

        let dsaKey = try DSAVerifier.parsePublicKeyFromCertificate(certData)

        XCTAssertFalse(dsaKey.p.isZero)
        XCTAssertFalse(dsaKey.q.isZero)
        XCTAssertFalse(dsaKey.g.isZero)
        XCTAssertFalse(dsaKey.y.isZero)
        XCTAssertGreaterThan(dsaKey.p.bitLength, 2000)
    }

    // MARK: - DSA Signature Algorithm Detection

    func testDSAHashAlgorithmDetection() throws {
        // Parse the DB ticket to get the signature
        let barcodeData = Data(hexString: Self.dbTicketHex)!
        let decoder = UICBarcodeDecoder()
        let barcode = try decoder.decode(barcodeData)

        guard let signature = barcode.signatureData.signature else {
            XCTFail("Expected signature in barcode")
            return
        }

        // The DB ticket uses DSA-SHA256, so signature r,s should have > 224 bit components
        let detectedAlg = DSAHashAlgorithm.fromSignature(signature)
        XCTAssertEqual(detectedAlg, .sha256, "DB ticket should use DSA-SHA256 based on signature size")
    }

    // MARK: - Integration: DB Ticket DSA-SHA256 Verification

    /// Test from SignatureValidationDBTicketTest.java
    func testDBTicketDSA_SHA256() throws {
        // Decode the barcode
        let barcodeData = Data(hexString: Self.dbTicketHex)!
        let decoder = UICBarcodeDecoder()
        let barcode = try decoder.decode(barcodeData)

        // Verify key ID
        XCTAssertEqual(barcode.signatureData.keyId, "00002", "Key ID should be 00002")

        // Get the public key from the certificate
        guard let certData = Data(base64Encoded: Self.dbKey2Certificate) else {
            XCTFail("Failed to decode certificate")
            return
        }

        // Verify signature using DSA-SHA256
        guard let signature = barcode.signatureData.signature,
              let signedData = barcode.signatureData.signedData else {
            XCTFail("Expected signature and signed data")
            return
        }

        let isValid = try SignatureVerifier.verifyDSA(
            signature: signature,
            data: signedData,
            publicKey: certData,
            hashAlgorithm: .sha256
        )

        XCTAssertTrue(isValid, "DB ticket DSA-SHA256 signature should verify")
    }

    /// Test DSA-SHA256 verification via OID (using SignatureVerifier.verify)
    func testDSA_SHA256_VerificationViaOID() throws {
        let barcodeData = Data(hexString: Self.dbTicketHex)!
        let decoder = UICBarcodeDecoder()
        let barcode = try decoder.decode(barcodeData)

        guard let certData = Data(base64Encoded: Self.dbKey2Certificate) else {
            XCTFail("Failed to decode certificate")
            return
        }

        guard let signature = barcode.signatureData.signature,
              let signedData = barcode.signatureData.signedData else {
            XCTFail("Expected signature and signed data")
            return
        }

        let isValid = try SignatureVerifier.verify(
            signature: signature,
            data: signedData,
            publicKey: certData,
            algorithmOID: AlgorithmOID.dsa_sha256_oid
        )

        XCTAssertTrue(isValid, "DSA-SHA256 verification via OID should succeed")
    }

    // MARK: - DSA Signature DER Parsing

    func testDSASignatureParsing() {
        // Create a simple DER-encoded DSA signature: SEQUENCE { INTEGER 7, INTEGER 42 }
        let derSig = Data([
            0x30, 0x06,         // SEQUENCE, length 6
            0x02, 0x01, 0x07,   // INTEGER, length 1, value 7
            0x02, 0x01, 0x2A    // INTEGER, length 1, value 42
        ])

        let parsed = DSAVerifier.parseDERSignature(derSig)
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.r, BigUInt(7))
        XCTAssertEqual(parsed?.s, BigUInt(42))
    }

    func testDSASignatureParsing_LargeValues() {
        // DER signature with larger integer values (including leading zero for positive)
        let derSig = Data([
            0x30, 0x0A,                             // SEQUENCE, length 10
            0x02, 0x03, 0x00, 0xFF, 0xFF,           // INTEGER, length 3, value 0x00FFFF = 65535
            0x02, 0x03, 0x01, 0x00, 0x00            // INTEGER, length 3, value 0x010000 = 65536
        ])

        let parsed = DSAVerifier.parseDERSignature(derSig)
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.r, BigUInt(65535))
        XCTAssertEqual(parsed?.s, BigUInt(65536))
    }

    // MARK: - Test Data from Java (SignatureValidationDBTicketTest.java)

    /// DB ticket barcode hex from getEncodingV2Hex()
    static let dbTicketHex =
        "2355543032313038303030303032782e" +
        "2fe184a1d85e89e9338b298ec61aeba2" +
        "48ce722056ca940a967c8a1d39126e2c" +
        "628c4fcea91ba35216a0a350f894de5e" +
        "bd7b8909920fde947feede0e20c43031" +
        "3939789c01bc0043ff555f464c455831" +
        "333031383862b20086e10dc125ea2815" +
        "110881051c844464d985668e23a00a80" +
        "000e96c2e4e6e8cadc08aed2d8d90104" +
        "44d7be0100221ce610ea559b64364c38" +
        "a82361d1cb5e1e5d32a3d0979bd099c8" +
        "426b0b7373432b4b6852932baba3634b" +
        "733b2b715ab34b09d101e18981c181f1" +
        "424221521291521292a17a3a920a1152" +
        "5a095282314952b20a49529952826278" +
        "083001a4c38ae5bb303ace7003800700" +
        "14b00240400f53757065722053706172" +
        "7072656973c41e4a03"

    /// X.509 certificate with DSA public key from getDBKey2()
    static let dbKey2Certificate = "MIIFAzCCBKmgAwIBAgIJAL4b6YtdfC1HMAsGCWCGSAFlAwQDAjBkMQswCQYDVQQGEwJERTELMAkGA1UECAwCSEUxFzAVBgNVBAoMDkRCVmVydHJpZWJHbUJIMRswGQYDVQQLDBJNb2JpbGVUaWNrZXRpbmdPcHMxEjAQBgNVBAMMCVRob3JnZUxvaDAeFw0xOTA1MTMwODM3MzBaFw0yNDA1MTEwODM3MzBaMGQxCzAJBgNVBAYTAkRFMQswCQYDVQQIDAJIRTEXMBUGA1UECgwOREJWZXJ0cmllYkdtQkgxGzAZBgNVBAsMEk1vYmlsZVRpY2tldGluZ09wczESMBAGA1UEAwwJVGhvcmdlTG9oMIIDRzCCAjkGByqGSM44BAEwggIsAoIBAQDvBHnyGImsnwD+u7a+4y8Kds6pJvmicDx//g/SXkj366T81luFYw3qWU6fV2F/p81j2PGfKHGIhhS89CPtBtXdt1cntHhs2B6+08Hmtd5RGGvqQiUuun5WrSloxJVWPfZRIp5BVNYnkybi+J10TsAL4xf1Wy5uWIOa8pQsBAl1ARMSz0vtQ9vUARLzzJtkS1QpAy6XiNVF9LodFUgC17m76NxK7htHcyoPhEnwdkHXP0YCYAMoXZEdhBVHL4kuyAj/+S+d/Fr+k/jRRLUdevrpsTbVttOkhO/uDtiOs1Z2Ou8PHqZDUvV7p7QMM45KDMBEhjqqEaVfkqTxr4DU71jDAiEAxl+jg6oBinGD274AOiOgdpVEG+dPuEVc6Ckiyxgx3ycCggEANO//Pafo6cAEtMmR7EsLc1dq+H2Hf4cX0o5pU1wiA5bY5kibcnmwSZynphoxUPZXAsZdoXw0ugx9Zkj68A/RwVZAyg+tfApfaIZVKp9BIQVAGwyOOHaEJBsdUahshpkM2SvuMNCxmZScnq5rherQvebbvkf5bmLvK4ftrve03lhnu92LbF8F4XTV/vHLtDAvJGo/380EA6yQVwe1lIUNET5vU3GYSoOZNsDFIu7ijl/mt0m8sjduFPVK5ueE4XO+Hal9lc5hYpiQq4AwUqtRsA+A1HAR7h3tu+QsqMo8AhbuxGdY/bipGSWyRcSg1mvLDEctev0rpvN5fX8ZymiCIwOCAQYAAoIBAQCkDpFu1+QttJUDSMJPScErldgepOoTaVSWIEkc8UYAmVgxXr+hF4t5/MAHeh4+kO5VXUA2xYbTiV4aA6fUkDm+6LW1aIG0Z4hE+SX6C8Lt8u0hp1UzQhERCobl1kRgMktipKes5h3aLaQ2Spy7+t8wzb0jScWNirrgtVZGUajcyQCuaZb5QIaQdLCPm0q5qD3PTDKaLxI/eFuIHSvNoh5WYTw9bfXxN//UZ1I+KQn7JKRdnkTHBvPm7Ww40Yo5Kcc45cxyUU6WDtmUcahaFOdpmfVBhCkK3H0oFOkTEXUAEd3irW8d38yq1znv/I+W0sBNjbtRpc59g+aBZO4oX1kDo1MwUTAdBgNVHQ4EFgQUp/Ih719wqFM0rDWnrLE5rfXqGxEwHwYDVR0jBBgwFoAUp/Ih719wqFM0rDWnrLE5rfXqGxEwDwYDVR0TAQH/BAUwAwEB/zALBglghkgBZQMEAwIDRwAwRAIgWY1GPRhkC9r8QC7AD0/Meki49G7MTA8Z7PrSsLCUYLoCIA/Lsca8Bal5cWs7siFlTJKWefb77CNRjNLvWqKbVW28"

    /// Second X.509 certificate from getDBKey6()
    static let dbKey6Certificate = "MIIFAjCCBKigAwIBAgIJAMWX1K7tkYCOMAsGCWCGSAFlAwQDAjBkMQswCQYDVQQGEwJERTELMAkGA1UECAwCSEUxFzAVBgNVBAoMDkRCVmVydHJpZWJHbUJIMRswGQYDVQQLDBJNb2JpbGVUaWNrZXRpbmdPcHMxEjAQBgNVBAMMCVRob3JnZUxvaDAeFw0xOTA1MTMwODM3NDZaFw0zNDA1MDkwODM3NDZaMGQxCzAJBgNVBAYTAkRFMQswCQYDVQQIDAJIRTEXMBUGA1UECgwOREJWZXJ0cmllYkdtQkgxGzAZBgNVBAsMEk1vYmlsZVRpY2tldGluZ09wczESMBAGA1UEAwwJVGhvcmdlTG9oMIIDRjCCAjkGByqGSM44BAEwggIsAoIBAQCA13FkF+uphcQTeKnXOcr+j02+bfvaFyAdLu2rUunDHJAa+ZNBbvnCqOHlzcw+FSiE67AvoipudM4m2VFjFOH94i9XzwCBC7BlHxcM+VyZYZZ6D35Dy27A1trSRliJ/Tsuqj7hAlwUIuhUijHYmPGlPWBQ6s73uWqmCahlPu9Xp/Bq1YbZOaod8/TYRW45XHSDPDxCugQ93flN4eGwjcE9RHeIGSYXB8XvEuzDNdUScxf2VszBNTBIJBcgtWRWquSCt18Usn4wxSawM3vtPAVwIQ4tg25rUIl8nnGyKE7WhJEXnBogq0Y6WMtBo1hcoH7HyKJZFi3TWgT4112MSe+VAiEA16Qg9xFHhTTbEytYIG9B6R/6Om66EegQ+u+djQyuej8CggEAL6ILRNGiV8MAXppeMGpifv3IRmr7FH0oFt3tAE1dqPontnlal9rXI2q/lRH6jBdPyrmegJB9TpSWkAM+Oq3Gf3SNipAIaduMo0PB7q6vgJmA8xf9aXk1tFo2Ov42+cFFVHsN86PIlFsgrBDw/gH53Z82lAjbbkzHwVq0/+Ga2DeuD5OWmbvHSiPv4LM0rfEaE8dkTf09ikykDeyzY4PUwSDmLRLzmWjwzhcc0myek++g4JQJKvXuM5b5GYgEPE/WIs5AC9YUNeHUGb5Ntwfh6rvq/Vfmg4dqNkzwu9KuOh0IXttnSvV5HZVgrTJmdB6VhlIByoqXYSoWVffRNufg1wOCAQUAAoIBAAwe+TWzrxyNXBumUZBdhR4rs2SEbHKv3ygesYLEIsqCH4XfZiLZofYKRmM+DnqPOoGlhYuVONZ5vmuzUPqyyoc3Y6AjaeYDSuSo149VDBi5exVTx7CrboT+yQiKCRMQvibv9vPHIyRay0n2LXvCwUviWB15h4Yr1u+LeaipmiGAg7wYPwBPMZj9E+wWiSHyzS5yH0Is86Z5vNNXXbqO0fQKO51DK9RzBjnwpZW6BWgxnwLU2XnBGpPzXKIH5QuNOC5k8WQ6ZMkOsaPf2343t7bQPbfOFUPbfvu6ZU4J7ypRBoSU0lMZHFlyYJli4neiwrubAUCUKk+OBtJULbzwpnujUzBRMB0GA1UdDgQWBBSc4VnCd08w4F6Oi7kyeqRcxOc1dzAfBgNVHSMEGDAWgBSc4VnCd08w4F6Oi7kyeqRcxOc1dzAPBgNVHRMBAf8EBTADAQH/MAsGCWCGSAFlAwQDAgNHADBEAiBMDsJUndh/zb/hH6X96FS2kggFRHBdDHoppKXxQgfWBQIgZM2HSQioVs4V0eamCT8xUfKApsZmdU/fjqk8UsTz9io="
}

// MARK: - Data hex initializer for test data

private extension Data {
    init?(hexString: String) {
        let hex = hexString.filter { $0.isHexDigit }
        guard hex.count % 2 == 0 else { return nil }

        var data = Data(capacity: hex.count / 2)
        var index = hex.startIndex
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index..<nextIndex], radix: 16) else { return nil }
            data.append(byte)
            index = nextIndex
        }
        self = data
    }
}
