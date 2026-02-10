import Foundation

/// Errors that can occur during UIC barcode processing
public enum UICBarcodeError: Error, LocalizedError {
    // MARK: - General Errors
    case invalidData(String)
    case unsupportedVersion(String)
    case decodingFailed(String)
    case encodingFailed(String)

    // MARK: - Frame Errors
    case invalidHeader(String)
    case invalidFrameType(String)
    case invalidFrameSize(expected: Int, actual: Int)
    case unsupportedFormat(String)
    case compressionFailed(String)
    case decompressionFailed(String)

    // MARK: - ASN.1 Errors
    case asn1DecodingError(String)
    case asn1InvalidSequence(String)
    case asn1InvalidChoice(String)
    case asn1ConstraintViolation(String)
    case asn1UnsupportedExtension(String)
    case asn1InvalidLength(String)

    // MARK: - Signature Errors
    case signatureInvalid(String)
    case signatureVerificationFailed(String)
    case unsupportedAlgorithm(String)
    case invalidPublicKey(String)

    // MARK: - Signing Errors
    case signingFailed(String)
    case missingData(String)

    // MARK: - BitBuffer Errors
    case bufferUnderflow(needed: Int, available: Int)
    case bufferOverflow(String)
    case invalidBitPosition(Int)

    public var errorDescription: String? {
        switch self {
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .unsupportedVersion(let version):
            return "Unsupported version: \(version)"
        case .decodingFailed(let message):
            return "Decoding failed: \(message)"
        case .encodingFailed(let message):
            return "Encoding failed: \(message)"
        case .invalidHeader(let message):
            return "Invalid header: \(message)"
        case .invalidFrameType(let type):
            return "Invalid frame type: \(type)"
        case .invalidFrameSize(let expected, let actual):
            return "Invalid frame size: expected \(expected) bytes, got \(actual)"
        case .unsupportedFormat(let message):
            return "Unsupported format: \(message)"
        case .compressionFailed(let message):
            return "Compression failed: \(message)"
        case .decompressionFailed(let message):
            return "Decompression failed: \(message)"
        case .asn1DecodingError(let message):
            return "ASN.1 decoding error: \(message)"
        case .asn1InvalidSequence(let message):
            return "ASN.1 invalid sequence: \(message)"
        case .asn1InvalidChoice(let message):
            return "ASN.1 invalid choice: \(message)"
        case .asn1ConstraintViolation(let message):
            return "ASN.1 constraint violation: \(message)"
        case .asn1UnsupportedExtension(let message):
            return "ASN.1 unsupported extension: \(message)"
        case .asn1InvalidLength(let message):
            return "ASN.1 invalid length: \(message)"
        case .signatureInvalid(let message):
            return "Invalid signature: \(message)"
        case .signatureVerificationFailed(let message):
            return "Signature verification failed: \(message)"
        case .unsupportedAlgorithm(let algorithm):
            return "Unsupported algorithm: \(algorithm)"
        case .invalidPublicKey(let message):
            return "Invalid public key: \(message)"
        case .signingFailed(let message):
            return "Signing failed: \(message)"
        case .missingData(let message):
            return "Missing data: \(message)"
        case .bufferUnderflow(let needed, let available):
            return "Buffer underflow: needed \(needed) bits, only \(available) available"
        case .bufferOverflow(let message):
            return "Buffer overflow: \(message)"
        case .invalidBitPosition(let position):
            return "Invalid bit position: \(position)"
        }
    }
}
