import Foundation
import CryptoKit

/// Signature verification utilities for UIC barcodes
///
/// Supported algorithms:
/// - ECDSA with P-256, P-384, P-521 curves (SHA-256, SHA-384, SHA-512)
/// - DSA with SHA-1, SHA-224, SHA-256 (pure Swift implementation)
public struct SignatureVerifier {

    // MARK: - Public API

    /// Verify an ECDSA P-256 signature
    /// - Parameters:
    ///   - signature: The DER-encoded signature
    ///   - data: The data that was signed
    ///   - publicKey: The public key in X9.63 format or raw format
    /// - Returns: true if signature is valid
    public static func verifyECDSA_P256(
        signature: Data,
        data: Data,
        publicKey: Data
    ) throws -> Bool {
        // Parse the public key
        let key = try parseP256PublicKey(publicKey)

        // Parse the signature from DER to raw format
        let rawSignature = try derToRawSignature(signature, curveByteLength: 32)

        // Create CryptoKit signature
        guard let ecdsaSignature = try? P256.Signing.ECDSASignature(rawRepresentation: rawSignature) else {
            throw UICBarcodeError.signatureInvalid("Invalid signature format")
        }

        // Verify
        return key.isValidSignature(ecdsaSignature, for: data)
    }

    /// Verify an ECDSA P-384 signature
    public static func verifyECDSA_P384(
        signature: Data,
        data: Data,
        publicKey: Data
    ) throws -> Bool {
        let key = try parseP384PublicKey(publicKey)
        let rawSignature = try derToRawSignature(signature, curveByteLength: 48)

        guard let ecdsaSignature = try? P384.Signing.ECDSASignature(rawRepresentation: rawSignature) else {
            throw UICBarcodeError.signatureInvalid("Invalid signature format")
        }

        return key.isValidSignature(ecdsaSignature, for: data)
    }

    /// Verify an ECDSA P-521 signature
    /// - Parameters:
    ///   - signature: The DER-encoded signature
    ///   - data: The data that was signed (will be hashed with SHA-512)
    ///   - publicKey: The public key in X9.63 format or raw format
    /// - Returns: true if signature is valid
    public static func verifyECDSA_P521(
        signature: Data,
        data: Data,
        publicKey: Data
    ) throws -> Bool {
        let key = try parseP521PublicKey(publicKey)
        let rawSignature = try derToRawSignature(signature, curveByteLength: 66)

        guard let ecdsaSignature = try? P521.Signing.ECDSASignature(rawRepresentation: rawSignature) else {
            throw UICBarcodeError.signatureInvalid("Invalid P-521 signature format")
        }

        return key.isValidSignature(ecdsaSignature, for: data)
    }

    /// Verify a signature using the algorithm specified by OID
    public static func verify(
        signature: Data,
        data: Data,
        publicKey: Data,
        algorithmOID: String
    ) throws -> Bool {
        // Map OID to algorithm
        let algorithm = try AlgorithmOID.parse(algorithmOID)

        switch algorithm {
        case .ecdsaWithSHA256:
            return try verifyECDSA_P256(signature: signature, data: SHA256.hash(data: data).data, publicKey: publicKey)
        case .ecdsaWithSHA384:
            return try verifyECDSA_P384(signature: signature, data: SHA384.hash(data: data).data, publicKey: publicKey)
        case .ecdsaWithSHA512:
            return try verifyECDSA_P521(signature: signature, data: SHA512.hash(data: data).data, publicKey: publicKey)
        case .dsaWithSHA1:
            return try verifyDSA(signature: signature, data: data, publicKey: publicKey, hashAlgorithm: .sha1)
        case .dsaWithSHA224:
            return try verifyDSA(signature: signature, data: data, publicKey: publicKey, hashAlgorithm: .sha224)
        case .dsaWithSHA256:
            return try verifyDSA(signature: signature, data: data, publicKey: publicKey, hashAlgorithm: .sha256)
        case .unknown:
            throw UICBarcodeError.unsupportedAlgorithm("Unknown algorithm OID: \(algorithmOID)")
        }
    }

    /// Verify a DSA signature
    /// - Parameters:
    ///   - signature: DER-encoded DSA signature (SEQUENCE { INTEGER r, INTEGER s })
    ///   - data: The data that was signed
    ///   - publicKey: DSA public key in SubjectPublicKeyInfo or X.509 certificate format
    ///   - hashAlgorithm: The hash algorithm to use
    /// - Returns: true if signature is valid
    public static func verifyDSA(
        signature: Data,
        data: Data,
        publicKey: Data,
        hashAlgorithm: DSAHashAlgorithm
    ) throws -> Bool {
        // Parse DSA public key (try SubjectPublicKeyInfo, then certificate)
        let dsaKey: DSAPublicKey
        do {
            dsaKey = try DSAVerifier.parsePublicKey(publicKey)
        } catch {
            do {
                dsaKey = try DSAVerifier.parsePublicKeyFromCertificate(publicKey)
            } catch {
                throw UICBarcodeError.invalidPublicKey("Unable to parse DSA public key")
            }
        }

        // Hash the data
        let hash = hashAlgorithm.hash(data)

        // Verify
        return DSAVerifier.verify(hash: hash, signature: signature, publicKey: dsaKey)
    }

    // MARK: - Public Key Parsing

    /// Parse a P-256 public key from various formats
    private static func parseP256PublicKey(_ data: Data) throws -> P256.Signing.PublicKey {
        // Try X9.63 format first (starts with 04 for uncompressed)
        if data.count == 65 && data[0] == 0x04 {
            return try P256.Signing.PublicKey(x963Representation: data)
        }

        // Try raw format (64 bytes, x and y coordinates)
        if data.count == 64 {
            var x963Data = Data([0x04])
            x963Data.append(data)
            return try P256.Signing.PublicKey(x963Representation: x963Data)
        }

        // Try DER format
        if data.count > 65 {
            let parsed = try parseSubjectPublicKeyInfo(data)
            return try P256.Signing.PublicKey(x963Representation: parsed)
        }

        throw UICBarcodeError.invalidPublicKey("Unable to parse P-256 public key")
    }

    /// Parse a P-384 public key from various formats
    private static func parseP384PublicKey(_ data: Data) throws -> P384.Signing.PublicKey {
        if data.count == 97 && data[0] == 0x04 {
            return try P384.Signing.PublicKey(x963Representation: data)
        }

        if data.count == 96 {
            var x963Data = Data([0x04])
            x963Data.append(data)
            return try P384.Signing.PublicKey(x963Representation: x963Data)
        }

        if data.count > 97 {
            let parsed = try parseSubjectPublicKeyInfo(data)
            return try P384.Signing.PublicKey(x963Representation: parsed)
        }

        throw UICBarcodeError.invalidPublicKey("Unable to parse P-384 public key")
    }

    /// Parse a P-521 public key from various formats
    /// P-521 uses 66-byte coordinates (521 bits = 66 bytes with padding)
    private static func parseP521PublicKey(_ data: Data) throws -> P521.Signing.PublicKey {
        // X9.63 format: 0x04 + 66 bytes X + 66 bytes Y = 133 bytes
        if data.count == 133 && data[0] == 0x04 {
            return try P521.Signing.PublicKey(x963Representation: data)
        }

        // Raw format: 66 bytes X + 66 bytes Y = 132 bytes
        if data.count == 132 {
            var x963Data = Data([0x04])
            x963Data.append(data)
            return try P521.Signing.PublicKey(x963Representation: x963Data)
        }

        // DER format (SubjectPublicKeyInfo)
        if data.count > 133 {
            let parsed = try parseSubjectPublicKeyInfo(data)
            return try P521.Signing.PublicKey(x963Representation: parsed)
        }

        throw UICBarcodeError.invalidPublicKey("Unable to parse P-521 public key")
    }

    /// Parse SubjectPublicKeyInfo DER structure to extract raw key bytes
    private static func parseSubjectPublicKeyInfo(_ data: Data) throws -> Data {
        var parser = DERParser(data: data)
        return try parser.parseSubjectPublicKeyInfo()
    }

    // MARK: - Signature Format Conversion

    /// Convert DER-encoded signature to raw (r || s) format
    public static func derToRawSignature(_ der: Data, curveByteLength: Int) throws -> Data {
        guard der.count >= 8 else {
            throw UICBarcodeError.signatureInvalid("DER signature too short")
        }

        // Check for SEQUENCE tag
        guard der[0] == 0x30 else {
            // Maybe already in raw format?
            if der.count == curveByteLength * 2 {
                return der
            }
            throw UICBarcodeError.signatureInvalid("Invalid DER signature format")
        }

        var offset = 2 // Skip SEQUENCE tag and length

        // Read r
        guard der[offset] == 0x02 else {
            throw UICBarcodeError.signatureInvalid("Expected INTEGER tag for r")
        }
        offset += 1
        let rLength = Int(der[offset])
        offset += 1
        var rData = Data(der[offset..<(offset + rLength)])
        offset += rLength

        // Read s
        guard der[offset] == 0x02 else {
            throw UICBarcodeError.signatureInvalid("Expected INTEGER tag for s")
        }
        offset += 1
        let sLength = Int(der[offset])
        offset += 1
        var sData = Data(der[offset..<(offset + sLength)])

        // Remove leading zeros if present (DER integers are signed)
        if rData.count > curveByteLength && rData[0] == 0 {
            rData = Data(rData.dropFirst())
        }
        if sData.count > curveByteLength && sData[0] == 0 {
            sData = Data(sData.dropFirst())
        }

        // Pad to curve byte length if needed
        while rData.count < curveByteLength {
            rData.insert(0, at: 0)
        }
        while sData.count < curveByteLength {
            sData.insert(0, at: 0)
        }

        var result = rData
        result.append(sData)
        return result
    }

    /// Convert raw (r || s) signature to DER format
    public static func rawToDerSignature(_ raw: Data) throws -> Data {
        guard raw.count % 2 == 0 else {
            throw UICBarcodeError.signatureInvalid("Invalid raw signature length")
        }

        let halfLength = raw.count / 2
        var rData = Data(raw[0..<halfLength])
        var sData = Data(raw[halfLength..<raw.count])

        // Remove leading zeros
        while rData.count > 1 && rData[0] == 0 && (rData[1] & 0x80) == 0 {
            rData = Data(rData.dropFirst())
        }
        while sData.count > 1 && sData[0] == 0 && (sData[1] & 0x80) == 0 {
            sData = Data(sData.dropFirst())
        }

        // Add leading zero if high bit is set (to indicate positive)
        if (rData[0] & 0x80) != 0 {
            rData.insert(0, at: 0)
        }
        if (sData[0] & 0x80) != 0 {
            sData.insert(0, at: 0)
        }

        let sequenceLength = 2 + rData.count + 2 + sData.count

        var der = Data()
        der.append(0x30) // SEQUENCE tag
        der.append(UInt8(sequenceLength))
        der.append(0x02) // INTEGER tag
        der.append(UInt8(rData.count))
        der.append(rData)
        der.append(0x02) // INTEGER tag
        der.append(UInt8(sData.count))
        der.append(sData)

        return der
    }
}

// MARK: - Hash Extension

extension Digest {
    var data: Data {
        Data(Array(self))
    }
}

// MARK: - Algorithm OIDs

/// Known algorithm OIDs for signature verification
public enum AlgorithmOID {
    // ECDSA algorithms (supported)
    case ecdsaWithSHA256
    case ecdsaWithSHA384
    case ecdsaWithSHA512

    // DSA algorithms
    case dsaWithSHA1
    case dsaWithSHA224
    case dsaWithSHA256

    case unknown

    /// ECDSA OID strings
    public static let ecdsa_sha256_oid = "1.2.840.10045.4.3.2"
    public static let ecdsa_sha384_oid = "1.2.840.10045.4.3.3"
    public static let ecdsa_sha512_oid = "1.2.840.10045.4.3.4"

    /// DSA OID strings
    public static let dsa_sha1_oid   = "1.2.840.10040.4.3"
    public static let dsa_sha224_oid = "2.16.840.1.101.3.4.3.1"
    public static let dsa_sha256_oid = "2.16.840.1.101.3.4.3.2"

    /// Parse OID string to algorithm
    public static func parse(_ oid: String) throws -> AlgorithmOID {
        switch oid {
        // ECDSA
        case ecdsa_sha256_oid:
            return .ecdsaWithSHA256
        case ecdsa_sha384_oid:
            return .ecdsaWithSHA384
        case ecdsa_sha512_oid:
            return .ecdsaWithSHA512
        // DSA
        case dsa_sha1_oid:
            return .dsaWithSHA1
        case dsa_sha224_oid:
            return .dsaWithSHA224
        case dsa_sha256_oid:
            return .dsaWithSHA256
        default:
            return .unknown
        }
    }
}
