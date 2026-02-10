import Foundation
import CryptoKit

/// DSA public key parameters
struct DSAPublicKey {
    let p: BigUInt  // Prime modulus
    let q: BigUInt  // Sub-prime (order of subgroup)
    let g: BigUInt  // Generator
    let y: BigUInt  // Public key value (g^x mod p)
}

/// DSA hash algorithm selection
public enum DSAHashAlgorithm {
    case sha1
    case sha224
    case sha256

    /// Detect DSA hash algorithm from DER-encoded signature, matching Java's getDsaAlgorithm().
    /// Decodes r and s from the DER signature and uses the max bit length to determine the algorithm.
    static func fromSignature(_ signature: Data) -> DSAHashAlgorithm {
        guard signature.count >= 8,
              signature[signature.startIndex] == 0x30 else {
            return .sha1
        }

        // Parse DER SEQUENCE to get r and s
        var offset = signature.startIndex + 2

        // Skip multi-byte length if needed
        if signature[signature.startIndex + 1] & 0x80 != 0 {
            let numLenBytes = Int(signature[signature.startIndex + 1] & 0x7F)
            offset = signature.startIndex + 2 + numLenBytes
        }

        guard offset < signature.endIndex, signature[offset] == 0x02 else {
            return .sha1
        }
        offset += 1
        let rLen = Int(signature[offset])
        offset += 1
        let rData = Data(signature[offset..<(offset + rLen)])
        offset += rLen

        guard offset < signature.endIndex, signature[offset] == 0x02 else {
            return .sha1
        }
        offset += 1
        let sLen = Int(signature[offset])
        offset += 1
        let sData = Data(signature[offset..<(offset + sLen)])

        let r = BigUInt(data: rData)
        let s = BigUInt(data: sData)

        let maxBitLen = Swift.max(r.bitLength, s.bitLength)

        if maxBitLen > 224 {
            return .sha256
        } else if maxBitLen > 160 {
            return .sha224
        } else {
            return .sha1
        }
    }

    /// Compute the hash of data using this algorithm
    func hash(_ data: Data) -> Data {
        switch self {
        case .sha1:
            return Data(Insecure.SHA1.hash(data: data))
        case .sha224:
            return sha224Hash(data)
        case .sha256:
            return Data(SHA256.hash(data: data))
        }
    }

    /// SHA-224 via CommonCrypto
    private func sha224Hash(_ data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: 28) // SHA-224 is 28 bytes
        _ = data.withUnsafeBytes { ptr in
            CC_SHA224(ptr.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }
}

// Import CommonCrypto for SHA-224
#if canImport(CommonCrypto)
import CommonCrypto
#endif

/// Pure Swift DSA signature verifier
struct DSAVerifier {

    /// Verify a DSA signature
    /// - Parameters:
    ///   - hash: The hash of the signed data (truncated to q's bit length)
    ///   - signature: DER-encoded signature containing (r, s) integers
    ///   - publicKey: DSA public key parameters
    /// - Returns: true if the signature is valid
    static func verify(hash: Data, signature: Data, publicKey: DSAPublicKey) -> Bool {
        // Parse r, s from DER signature
        guard let (r, s) = parseDERSignature(signature) else {
            return false
        }

        return verifyRaw(hash: hash, r: r, s: s, publicKey: publicKey)
    }

    /// Verify a DSA signature with raw r, s values
    static func verifyRaw(hash: Data, r: BigUInt, s: BigUInt, publicKey: DSAPublicKey) -> Bool {
        let p = publicKey.p
        let q = publicKey.q
        let g = publicKey.g
        let y = publicKey.y
        let zero = BigUInt(0)

        // Step 1: Check 0 < r < q and 0 < s < q
        guard r > zero, r < q, s > zero, s < q else {
            return false
        }

        // Step 2: w = s^(-1) mod q
        guard let w = BigUInt.modInverse(s, q) else {
            return false
        }

        // Truncate hash to q's bit length
        let qBitLen = q.bitLength
        var hashValue = BigUInt(data: hash)
        let hashBitLen = hash.count * 8
        if hashBitLen > qBitLen {
            hashValue = hashValue >> (hashBitLen - qBitLen)
        }

        // Step 3: u1 = (H(m) * w) mod q
        let u1 = (hashValue * w) % q

        // Step 4: u2 = (r * w) mod q
        let u2 = (r * w) % q

        // Step 5: v = ((g^u1 * y^u2) mod p) mod q
        let gu1 = BigUInt.modPow(g, u1, p)
        let yu2 = BigUInt.modPow(y, u2, p)
        let v = ((gu1 * yu2) % p) % q

        // Step 6: Signature is valid if v == r
        return v == r
    }

    /// Parse DER-encoded DSA signature into (r, s)
    static func parseDERSignature(_ data: Data) -> (r: BigUInt, s: BigUInt)? {
        guard data.count >= 8 else { return nil }

        var offset = data.startIndex

        // SEQUENCE tag
        guard data[offset] == 0x30 else { return nil }
        offset += 1

        // Length (handle multi-byte)
        if data[offset] & 0x80 != 0 {
            let numBytes = Int(data[offset] & 0x7F)
            offset += 1 + numBytes
        } else {
            offset += 1
        }

        // First INTEGER (r)
        guard offset < data.endIndex, data[offset] == 0x02 else { return nil }
        offset += 1
        let rLen = Int(data[offset])
        offset += 1
        guard offset + rLen <= data.endIndex else { return nil }
        let r = BigUInt(data: Data(data[offset..<(offset + rLen)]))
        offset += rLen

        // Second INTEGER (s)
        guard offset < data.endIndex, data[offset] == 0x02 else { return nil }
        offset += 1
        let sLen = Int(data[offset])
        offset += 1
        guard offset + sLen <= data.endIndex else { return nil }
        let s = BigUInt(data: Data(data[offset..<(offset + sLen)]))

        return (r, s)
    }

    /// Parse a DSA SubjectPublicKeyInfo DER structure into DSAPublicKey
    static func parsePublicKey(_ data: Data) throws -> DSAPublicKey {
        var parser = DERParser(data: data)
        let (params, yData) = try parser.parseDSAPublicKeyInfo()
        return DSAPublicKey(
            p: BigUInt(data: params.p),
            q: BigUInt(data: params.q),
            g: BigUInt(data: params.g),
            y: BigUInt(data: yData)
        )
    }

    /// Parse a DSA public key from an X.509 certificate
    static func parsePublicKeyFromCertificate(_ certData: Data) throws -> DSAPublicKey {
        var parser = DERParser(data: certData)
        let (params, yData) = try parser.parseCertificateDSAPublicKey()
        return DSAPublicKey(
            p: BigUInt(data: params.p),
            q: BigUInt(data: params.q),
            g: BigUInt(data: params.g),
            y: BigUInt(data: yData)
        )
    }
}
