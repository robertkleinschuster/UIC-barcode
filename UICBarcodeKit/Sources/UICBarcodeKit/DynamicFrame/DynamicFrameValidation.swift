import Foundation

// MARK: - Validation Result

/// Validation result codes matching Java Constants (0-6)
public enum SignatureValidationResult: Int {
    case valid = 0
    case invalidSignature = 1
    case keyMissing = 2
    case signatureMissing = 3
    case signedDataMissing = 4
    case algorithmMissing = 5
    case encodingError = 6
}

// MARK: - Signature Validation

extension DynamicFrame {

    /// Validate Level 1 signature using an external public key.
    ///
    /// Uses the same signing convention as `signLevel1`: CryptoKit hashes internally.
    /// This means we call the curve-specific verify methods directly with raw data,
    /// NOT through `SignatureVerifier.verify()` which pre-hashes (double-hash convention
    /// used for real-world barcode verification with externally-signed data).
    ///
    /// - Parameters:
    ///   - publicKey: The public key in SPKI, X.509 certificate, or raw format
    ///   - algorithmOID: Optional signing algorithm OID override. If nil, uses level1SigningAlg or auto-detects from key.
    /// - Returns: Validation result code
    public func validateLevel1(publicKey: Data, algorithmOID: String? = nil) -> SignatureValidationResult {
        // Check signed data available — try re-encoding (matches what signLevel1 signed),
        // fall back to captured encodedData for externally-signed frames
        guard level1Data != nil else {
            return .signedDataMissing
        }

        let signedData: Data
        if let reEncoded = try? encodeLevel1() {
            signedData = reEncoded
        } else if !level1Data!.encodedData.isEmpty {
            signedData = level1Data!.encodedData
        } else {
            return .signedDataMissing
        }

        // Check signature available
        guard let signature = getLevel1Signature(), !signature.isEmpty else {
            return .signatureMissing
        }

        // Determine algorithm OID
        let oid: String
        if let provided = algorithmOID {
            oid = provided
        } else if let l1Alg = level1Data?.level1SigningAlg {
            oid = l1Alg
        } else {
            // Try auto-detect from public key
            var parser = DERParser(data: publicKey)
            guard let detectedOID = try? parser.extractAlgorithmOID() else {
                return .algorithmMissing
            }

            // Map key algorithm OID to signing algorithm OID
            if detectedOID == "1.2.840.10045.2.1" {
                oid = "1.2.840.10045.4.3.2"
            } else if detectedOID == "1.2.840.10040.4.1" {
                // DSA key - detect hash from signature size
                let hashAlg = DSAHashAlgorithm.fromSignature(signature)
                do {
                    let isValid = try SignatureVerifier.verifyDSA(
                        signature: signature,
                        data: signedData,
                        publicKey: publicKey,
                        hashAlgorithm: hashAlg
                    )
                    return isValid ? .valid : .invalidSignature
                } catch {
                    return .encodingError
                }
            } else {
                return .algorithmMissing
            }
        }

        // Verify using direct curve methods (matching signLevel1 convention)
        return verifySignature(signature: signature, data: signedData, publicKey: publicKey, algorithmOID: oid)
    }

    /// Validate Level 2 signature using the embedded level2publicKey from Level 1.
    /// - Returns: Validation result code
    public func validateLevel2() -> SignatureValidationResult {
        // Check level2publicKey available
        guard let l2Key = level1Data?.level2publicKey, !l2Key.isEmpty else {
            return .keyMissing
        }

        // Check level2Signature available
        guard let l2Sig = level2Signature, !l2Sig.isEmpty else {
            return .signatureMissing
        }

        // Encode level2 signed data (level1Data + level1Signature)
        let l2Data: Data
        do {
            l2Data = try encodeLevel2Data()
        } catch {
            return .signedDataMissing
        }

        // Determine algorithm
        let oid: String
        if let l2Alg = level1Data?.level2SigningAlg {
            oid = l2Alg
        } else {
            // Auto-detect from level2publicKey
            var parser = DERParser(data: l2Key)
            guard let detectedOID = try? parser.extractAlgorithmOID() else {
                return .algorithmMissing
            }

            if detectedOID == "1.2.840.10045.2.1" {
                oid = "1.2.840.10045.4.3.2"
            } else if detectedOID == "1.2.840.10040.4.1" {
                let hashAlg = DSAHashAlgorithm.fromSignature(l2Sig)
                do {
                    let isValid = try SignatureVerifier.verifyDSA(
                        signature: l2Sig,
                        data: l2Data,
                        publicKey: l2Key,
                        hashAlgorithm: hashAlg
                    )
                    return isValid ? .valid : .invalidSignature
                } catch {
                    return .encodingError
                }
            } else {
                return .algorithmMissing
            }
        }

        // Verify using direct curve methods (matching signLevel2 convention)
        return verifySignature(signature: l2Sig, data: l2Data, publicKey: l2Key, algorithmOID: oid)
    }

    /// Verify a signature by dispatching to curve-specific methods directly.
    /// Uses the same convention as SignatureSigner: CryptoKit hashes data internally.
    private func verifySignature(signature: Data, data: Data, publicKey: Data, algorithmOID: String) -> SignatureValidationResult {
        do {
            let algorithm = try AlgorithmOID.parse(algorithmOID)

            let isValid: Bool
            switch algorithm {
            case .ecdsaWithSHA256:
                isValid = try SignatureVerifier.verifyECDSA_P256(signature: signature, data: data, publicKey: publicKey)
            case .ecdsaWithSHA384:
                isValid = try SignatureVerifier.verifyECDSA_P384(signature: signature, data: data, publicKey: publicKey)
            case .ecdsaWithSHA512:
                isValid = try SignatureVerifier.verifyECDSA_P521(signature: signature, data: data, publicKey: publicKey)
            case .dsaWithSHA1:
                isValid = try SignatureVerifier.verifyDSA(signature: signature, data: data, publicKey: publicKey, hashAlgorithm: .sha1)
            case .dsaWithSHA224:
                isValid = try SignatureVerifier.verifyDSA(signature: signature, data: data, publicKey: publicKey, hashAlgorithm: .sha224)
            case .dsaWithSHA256:
                isValid = try SignatureVerifier.verifyDSA(signature: signature, data: data, publicKey: publicKey, hashAlgorithm: .sha256)
            case .unknown:
                return .algorithmMissing
            }

            return isValid ? .valid : .invalidSignature
        } catch {
            return .encodingError
        }
    }
}

// MARK: - Convenience Accessors

extension DynamicFrame {

    /// Security provider (prefers IA5 over numeric)
    public var securityProvider: String? {
        if let ia5 = level1Data?.securityProviderIA5 {
            return ia5
        }
        if let num = level1Data?.securityProviderNum {
            return String(num)
        }
        return nil
    }

    /// Key ID from Level 1
    public var level1KeyId: Int? {
        level1Data?.keyId
    }

    /// Frame version as enum
    public var version: DynamicFrameVersion {
        DynamicFrameVersion(rawValue: format) ?? .v1
    }

    /// End of barcode validity as Date (V2 only).
    /// Uses endOfValidityYear (offset from 0, actual year 2016+), endOfValidityDay, and optional endOfValidityTime.
    public var endOfValidity: Date? {
        guard let year = level1Data?.endOfValidityYear,
              let day = level1Data?.endOfValidityDay else {
            return nil
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        var components = DateComponents()
        components.year = year
        components.month = 1
        components.day = 1

        guard var date = calendar.date(from: components) else { return nil }

        // Add day offset (1-based, so subtract 1)
        guard let withDay = calendar.date(byAdding: .day, value: day - 1, to: date) else { return nil }
        date = withDay

        // Add time if present (minutes since midnight)
        if let minutes = level1Data?.endOfValidityTime {
            guard let withTime = calendar.date(byAdding: .minute, value: minutes, to: date) else { return nil }
            date = withTime
        }

        return date
    }

    /// Validity duration in seconds (V2 only)
    public var validityDurationSeconds: Int? {
        level1Data?.validityDuration
    }

    /// Get the Level 2 signed data (level1Data + level1Signature UPER encoded)
    public func getLevel2SignedData() throws -> Data {
        try encodeLevel2Data()
    }
}
