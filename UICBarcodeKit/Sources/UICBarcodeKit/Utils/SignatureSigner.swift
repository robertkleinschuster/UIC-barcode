import Foundation
import CryptoKit

/// Signature creation utilities for UIC barcodes
///
/// Supported algorithms:
/// - ECDSA with P-256, P-384, P-521 curves (SHA-256, SHA-384, SHA-512)
public struct SignatureSigner {

    // MARK: - ECDSA Signing

    /// Sign data using ECDSA P-256 (SHA-256)
    /// - Parameters:
    ///   - data: The data to sign
    ///   - privateKey: The P-256 private key
    /// - Returns: DER-encoded signature
    public static func signECDSA_P256(data: Data, privateKey: P256.Signing.PrivateKey) throws -> Data {
        let signature = try privateKey.signature(for: data)
        return signature.derRepresentation
    }

    /// Sign data using ECDSA P-384 (SHA-384)
    /// - Parameters:
    ///   - data: The data to sign
    ///   - privateKey: The P-384 private key
    /// - Returns: DER-encoded signature
    public static func signECDSA_P384(data: Data, privateKey: P384.Signing.PrivateKey) throws -> Data {
        let signature = try privateKey.signature(for: data)
        return signature.derRepresentation
    }

    /// Sign data using ECDSA P-521 (SHA-512)
    /// - Parameters:
    ///   - data: The data to sign
    ///   - privateKey: The P-521 private key
    /// - Returns: DER-encoded signature
    public static func signECDSA_P521(data: Data, privateKey: P521.Signing.PrivateKey) throws -> Data {
        let signature = try privateKey.signature(for: data)
        return signature.derRepresentation
    }

    /// Sign data using the algorithm specified by OID
    /// - Parameters:
    ///   - data: The data to sign
    ///   - privateKeyData: The raw private key bytes
    ///   - algorithmOID: The algorithm OID string
    /// - Returns: DER-encoded signature
    public static func sign(data: Data, privateKeyData: Data, algorithmOID: String) throws -> Data {
        let algorithm = try AlgorithmOID.parse(algorithmOID)

        switch algorithm {
        case .ecdsaWithSHA256:
            let key = try P256.Signing.PrivateKey(rawRepresentation: privateKeyData)
            return try signECDSA_P256(data: data, privateKey: key)
        case .ecdsaWithSHA384:
            let key = try P384.Signing.PrivateKey(rawRepresentation: privateKeyData)
            return try signECDSA_P384(data: data, privateKey: key)
        case .ecdsaWithSHA512:
            let key = try P521.Signing.PrivateKey(rawRepresentation: privateKeyData)
            return try signECDSA_P521(data: data, privateKey: key)
        case .dsaWithSHA1, .dsaWithSHA224, .dsaWithSHA256:
            throw UICBarcodeError.unsupportedAlgorithm("DSA signing not supported")
        case .unknown:
            throw UICBarcodeError.unsupportedAlgorithm("Unknown algorithm OID: \(algorithmOID)")
        }
    }
}
