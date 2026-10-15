import XCTest
@testable import UICBarcodeKit

/// DB (Deutsche Bahn) Signature Validation Tests
/// Translated from Java: SignatureValidationDBTicketTest.java
/// Tests Static Frame decoding with DSA-SHA256 signature validation
final class DBSignatureTests: XCTestCase {

    // MARK: - Test Data

    /// Static frame hex data from SignatureValidationDBTicketTest.java
    static let ticketHex =
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

    /// Public key 2 (X.509 certificate, DSA) from SignatureValidationDBTicketTest.java
    static let publicKey2Base64 = "MIIFAzCCBKmgAwIBAgIJAL4b6YtdfC1HMAsGCWCGSAFlAwQDAjBkMQswCQYDVQQGEwJERTELMAkGA1UECAwCSEUxFzAVBgNVBAoMDkRCVmVydHJpZWJHbUJIMRswGQYDVQQLDBJNb2JpbGVUaWNrZXRpbmdPcHMxEjAQBgNVBAMMCVRob3JnZUxvaDAeFw0xOTA1MTMwODM3MzBaFw0yNDA1MTEwODM3MzBaMGQxCzAJBgNVBAYTAkRFMQswCQYDVQQIDAJIRTEXMBUGA1UECgwOREJWZXJ0cmllYkdtQkgxGzAZBgNVBAsMEk1vYmlsZVRpY2tldGluZ09wczESMBAGA1UEAwwJVGhvcmdlTG9oMIIDRzCCAjkGByqGSM44BAEwggIsAoIBAQDvBHnyGImsnwD+u7a+4y8Kds6pJvmicDx//g/SXkj366T81luFYw3qWU6fV2F/p81j2PGfKHGIhhS89CPtBtXdt1cntHhs2B6+08Hmtd5RGGvqQiUuun5WrSloxJVWPfZRIp5BVNYnkybi+J10TsAL4xf1Wy5uWIOa8pQsBAl1ARMSz0vtQ9vUARLzzJtkS1QpAy6XiNVF9LodFUgC17m76NxK7htHcyoPhEnwdkHXP0YCYAMoXZEdhBVHL4kuyAj/+S+d/Fr+k/jRRLUdevrpsTbVttOkhO/uDtiOs1Z2Ou8PHqZDUvV7p7QMM45KDMBEhjqqEaVfkqTxr4DU71jDAiEAxl+jg6oBinGD274AOiOgdpVEG+dPuEVc6Ckiyxgx3ycCggEANO//Pafo6cAEtMmR7EsLc1dq+H2Hf4cX0o5pU1wiA5bY5kibcnmwSZynphoxUPZXAsZdoXw0ugx9Zkj68A/RwVZAyg+tfApfaIZVKp9BIQVAGwyOOHaEJBsdUahshpkM2SvuMNCxmZScnq5rherQvebbvkf5bmLvK4ftrve03lhnu92LbF8F4XTV/vHLtDAvJGo/380EA6yQVwe1lIUNET5vU3GYSoOZNsDFIu7ijl/mt0m8sjduFPVK5ueE4XO+Hal9lc5hYpiQq4AwUqtRsA+A1HAR7h3tu+QsqMo8AhbuxGdY/bipGSWyRcSg1mvLDEctev0rpvN5fX8ZymiCIwOCAQYAAoIBAQCkDpFu1+QttJUDSMJPScErldgepOoTaVSWIEkc8UYAmVgxXr+hF4t5/MAHeh4+kO5VXUA2xYbTiV4aA6fUkDm+6LW1aIG0Z4hE+SX6C8Lt8u0hp1UzQhERCobl1kRgMktipKes5h3aLaQ2Spy7+t8wzb0jScWNirrgtVZGUajcyQCuaZb5QIaQdLCPm0q5qD3PTDKaLxI/eFuIHSvNoh5WYTw9bfXxN//UZ1I+KQn7JKRdnkTHBvPm7Ww40Yo5Kcc45cxyUU6WDtmUcahaFOdpmfVBhCkK3H0oFOkTEXUAEd3irW8d38yq1znv/I+W0sBNjbtRpc59g+aBZO4oX1kDo1MwUTAdBgNVHQ4EFgQUp/Ih719wqFM0rDWnrLE5rfXqGxEwHwYDVR0jBBgwFoAUp/Ih719wqFM0rDWnrLE5rfXqGxEwDwYDVR0TAQH/BAUwAwEB/zALBglghkgBZQMEAwIDRwAwRAIgWY1GPRhkC9r8QC7AD0/Meki49G7MTA8Z7PrSsLCUYLoCIA/Lsca8Bal5cWs7siFlTJKWefb77CNRjNLvWqKbVW28"

    // MARK: - Helper

    static func hexToData(_ hex: String) -> Data {
        let cleanHex = hex.replacingOccurrences(of: " ", with: "")
                          .replacingOccurrences(of: "\n", with: "")
        var data = Data()
        var index = cleanHex.startIndex
        while index < cleanHex.endIndex {
            let nextIndex = cleanHex.index(index, offsetBy: 2)
            if let byte = UInt8(cleanHex[index..<nextIndex], radix: 16) {
                data.append(byte)
            }
            index = nextIndex
        }
        return data
    }

    // MARK: - Tests

    /// Test Static Frame decoding of DB ticket
    func testDBStaticFrameDecoding() throws {
        let data = Self.hexToData(Self.ticketHex)

        let barcodeDecoder = UICBarcodeDecoder()
        let barcode = try barcodeDecoder.decode(data)

        // Verify it's a static frame
        if case .staticFrame = barcode.frameType {
            // OK
        } else {
            XCTFail("Expected static frame")
        }

        // Get the static frame
        let frame = try XCTUnwrap(barcode.staticFrame)

        // The signature key should be "00002" from the static frame header
        XCTAssertEqual(frame.signatureKeyId, "00002")
    }

    /// Test DSA-SHA256 signature validation of DB ticket
    func testDBSignatureValidation() throws {
        let data = Self.hexToData(Self.ticketHex)
        let publicKeyData = Data(base64Encoded: Self.publicKey2Base64)!

        let barcodeDecoder = UICBarcodeDecoder()
        let barcode = try barcodeDecoder.decode(data)

        // Verify the signature using explicit DSA-SHA256 OID (Java passes algorithm explicitly)
        let frame = try XCTUnwrap(barcode.staticFrame)
        let result = try SignatureVerifier.verify(
            signature: frame.signature,
            data: frame.signedData,
            publicKey: publicKeyData,
            algorithmOID: AlgorithmOID.dsa_sha256_oid
        )
        XCTAssertTrue(result, "DSA-SHA256 signature should verify for DB ticket")
    }
}
