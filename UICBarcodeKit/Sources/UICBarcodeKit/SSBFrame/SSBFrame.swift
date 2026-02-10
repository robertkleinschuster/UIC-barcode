import Foundation
import CryptoKit

/// Represents a decoded SSB (Small Structured Barcode) frame
/// SSB frames are exactly 114 bytes with fixed-size fields encoded at bit level
/// Java ref: SsbFrame.java
public struct SSBFrame {
    /// SSB frame size in bytes
    public static let frameSize = 114

    /// Signature offset within the frame (byte 58)
    public static let signatureOffset = 58

    /// Signature size in bytes (56 bytes = 2 x 28 for r and s)
    public static let signatureSize = 56

    // MARK: - Header Fields

    /// SSB header containing version, issuer, key ID, and ticket type
    public var header: SSBHeader

    /// First part of signature (r value)
    public var signaturePart1: Data

    /// Second part of signature (s value)
    public var signaturePart2: Data

    // MARK: - Ticket Data (one of these will be populated based on ticket type)

    /// Non-UIC ticket data
    public var nonUicData: SSBNonUic?

    /// Non-reservation ticket data (NRT)
    public var nonReservationData: SSBNonReservation?

    /// Reservation ticket data (IRT/RES/BOA)
    public var reservationData: SSBReservation?

    /// Group ticket data
    public var groupData: SSBGroup?

    /// Pass ticket data (RPT)
    public var passData: SSBPass?

    // MARK: - Initialization

    public init() {
        self.header = SSBHeader()
        self.signaturePart1 = Data()
        self.signaturePart2 = Data()
    }

    /// Decode SSB frame from raw data
    public init(data: Data) throws {
        self.init()
        try decode(data: data)
    }

    // MARK: - Decoding

    /// Decode the SSB frame from raw data
    public mutating func decode(data: Data) throws {
        guard data.count == Self.frameSize else {
            throw UICBarcodeError.invalidFrameSize(expected: Self.frameSize, actual: data.count)
        }

        // Create bit buffer for bit-level access
        let bitBuffer = BitBuffer(data: data)

        // Decode header (27 bits starting at position 0)
        header = try SSBHeader(bitBuffer: bitBuffer)

        // Decode ticket data based on type
        let buffer = BitBuffer(data: data)

        switch header.ticketType {
        case .irtResBoa:
            reservationData = try SSBReservation(bitBuffer: buffer)
        case .nrt:
            nonReservationData = try SSBNonReservation(bitBuffer: buffer)
        case .grp:
            groupData = try SSBGroup(bitBuffer: buffer)
        case .rpt:
            passData = try SSBPass(bitBuffer: buffer)
        default:
            nonUicData = try SSBNonUic(bitBuffer: buffer)
        }

        // Decode signature (56 bytes starting at offset 58)
        let signatureBytes = Data(data[Self.signatureOffset..<(Self.signatureOffset + Self.signatureSize)])

        // Try to decode as DER first (some implementations encode incorrectly)
        if signatureBytes[0] == 0x30 {
            if let (r, s) = try? decodeSignatureIntegerSequence(signatureBytes) {
                signaturePart1 = r
                signaturePart2 = s
                return
            }
        }

        // Standard split: 28 bytes each
        signaturePart1 = Data(signatureBytes[0..<28])
        signaturePart2 = Data(signatureBytes[28..<56])
    }

    // MARK: - Signature

    /// Get the data that is signed (first 58 bytes)
    public func getDataForSignature(_ originalData: Data) -> Data {
        return Data(originalData[0..<Self.signatureOffset])
    }

    /// Get the combined signature in DER format
    public func getSignature() throws -> Data {
        let r = trimLeadingZeros(signaturePart1)
        let s = trimLeadingZeros(signaturePart2)
        return try encodeSignatureIntegerSequence(r: r, s: s)
    }

    // MARK: - Helpers

    private func trimLeadingZeros(_ data: Data) -> Data {
        var result = data
        while result.count > 1 && result[0] == 0 {
            result = Data(result.dropFirst())
        }
        return result
    }

    private func decodeSignatureIntegerSequence(_ data: Data) throws -> (Data, Data) {
        guard data.count >= 8, data[0] == 0x30 else {
            throw UICBarcodeError.signatureInvalid("Not a DER sequence")
        }

        var offset = 2

        guard data[offset] == 0x02 else {
            throw UICBarcodeError.signatureInvalid("Expected INTEGER tag for r")
        }
        offset += 1
        let rLength = Int(data[offset])
        offset += 1
        let r = Data(data[offset..<(offset + rLength)])
        offset += rLength

        guard data[offset] == 0x02 else {
            throw UICBarcodeError.signatureInvalid("Expected INTEGER tag for s")
        }
        offset += 1
        let sLength = Int(data[offset])
        offset += 1
        let s = Data(data[offset..<(offset + sLength)])

        return (r, s)
    }

    private func encodeSignatureIntegerSequence(r: Data, s: Data) throws -> Data {
        var rBytes = r
        var sBytes = s

        if !rBytes.isEmpty && (rBytes[0] & 0x80) != 0 {
            rBytes.insert(0, at: 0)
        }
        if !sBytes.isEmpty && (sBytes[0] & 0x80) != 0 {
            sBytes.insert(0, at: 0)
        }

        let sequenceLength = 2 + rBytes.count + 2 + sBytes.count
        var result = Data()
        result.append(0x30)
        result.append(UInt8(sequenceLength))
        result.append(0x02)
        result.append(UInt8(rBytes.count))
        result.append(rBytes)
        result.append(0x02)
        result.append(UInt8(sBytes.count))
        result.append(sBytes)

        return result
    }
}

// MARK: - SSBFrame Encoding

extension SSBFrame {

    /// Encode the SSB frame to a 114-byte Data.
    /// The signature parts must already be set.
    /// - Returns: 114 bytes: header(27 bits) + ticket data + signature(56 bytes at offset 58)
    public func encode() throws -> Data {
        var bitBuffer = BitBuffer.allocate(bits: SSBFrame.frameSize * 8)

        // Encode header (27 bits at offset 0)
        try header.encode(to: &bitBuffer)

        // Encode ticket data based on type
        if let data = reservationData {
            try data.encode(to: &bitBuffer)
        } else if let data = nonReservationData {
            try data.encode(to: &bitBuffer)
        } else if let data = groupData {
            try data.encode(to: &bitBuffer)
        } else if let data = passData {
            try data.encode(to: &bitBuffer)
        } else if let data = nonUicData {
            try data.encode(to: &bitBuffer)
        }

        // Encode signature at byte offset 58 (56 bytes = 28 + 28)
        var result = bitBuffer.toData()

        // Ensure we have 114 bytes
        if result.count < SSBFrame.frameSize {
            result.append(Data(repeating: 0, count: SSBFrame.frameSize - result.count))
        }

        // Write signature parts at offset 58
        let sig1 = padOrTrim(signaturePart1, to: 28)
        let sig2 = padOrTrim(signaturePart2, to: 28)
        result.replaceSubrange(SSBFrame.signatureOffset..<(SSBFrame.signatureOffset + 28), with: sig1)
        result.replaceSubrange((SSBFrame.signatureOffset + 28)..<(SSBFrame.signatureOffset + 56), with: sig2)

        return Data(result.prefix(SSBFrame.frameSize))
    }

    /// Get the data portion that should be signed (first 58 bytes from encoded frame).
    public func encodeDataForSignature() throws -> Data {
        let encoded = try encode()
        return Data(encoded.prefix(SSBFrame.signatureOffset))
    }

    private func padOrTrim(_ data: Data, to length: Int) -> Data {
        if data.count >= length {
            return Data(data.prefix(length))
        }
        var padded = Data(repeating: 0, count: length - data.count)
        padded.append(data)
        return padded
    }
}

// MARK: - SSBFrame Signing

extension SSBFrame {

    /// Sign the SSB frame with an ECDSA P-256 private key.
    /// Encodes the data portion, signs it, and stores the signature as r||s parts.
    /// - Parameter privateKey: The ECDSA P-256 private key
    public mutating func sign(privateKey: P256.Signing.PrivateKey) throws {
        let dataToSign = try encodeDataForSignature()
        let derSignature = try SignatureSigner.signECDSA_P256(data: dataToSign, privateKey: privateKey)

        // Convert DER signature to raw r||s and split into two 28-byte parts
        let rawSignature = try SignatureVerifier.derToRawSignature(derSignature, curveByteLength: 28)
        signaturePart1 = Data(rawSignature.prefix(28))
        signaturePart2 = Data(rawSignature.suffix(28))
    }

    /// Sign the SSB frame using the specified algorithm OID and raw private key bytes.
    /// - Parameters:
    ///   - privateKeyData: The raw private key bytes
    ///   - algorithmOID: The signing algorithm OID
    public mutating func sign(privateKeyData: Data, algorithmOID: String) throws {
        let dataToSign = try encodeDataForSignature()
        let derSignature = try SignatureSigner.sign(data: dataToSign, privateKeyData: privateKeyData, algorithmOID: algorithmOID)

        // Convert DER signature to raw r||s and split into two 28-byte parts
        let rawSignature = try SignatureVerifier.derToRawSignature(derSignature, curveByteLength: 28)
        signaturePart1 = Data(rawSignature.prefix(28))
        signaturePart2 = Data(rawSignature.suffix(28))
    }
}
