import Foundation
import CryptoKit

/// Static Frame version constants
public enum StaticFrameVersion: String {
    case v1 = "01"
    case v2 = "02"
}

/// Represents a decoded UIC Static Frame barcode (#UT format)
public struct StaticFrame {
    // MARK: - Header Fields

    /// The barcode format version (1 or 2)
    public var version: Int

    /// Security provider code (4 characters)
    public var securityProvider: String

    /// Signature key ID (5 characters)
    public var signatureKeyId: String

    /// The digital signature
    public var signature: Data

    /// The signed (compressed) data
    public var signedData: Data

    // MARK: - Decoded Content

    /// Header record (U_HEAD) if present
    public var headerRecord: UHEADDataRecord?

    /// Flex record (U_FLEX) containing FCB ticket data
    public var flexRecord: UFLEXDataRecord?

    /// Layout record (U_TLAY) for ticket layout
    public var layoutRecords: [UTLAYDataRecord] = []

    /// Generic/bilateral data records
    public var dataRecords: [GenericDataRecord] = []

    // MARK: - Initialization

    public init() {
        self.version = 1
        self.securityProvider = ""
        self.signatureKeyId = ""
        self.signature = Data()
        self.signedData = Data()
    }

    /// Initialize by decoding from raw barcode data
    public init(data: Data) throws {
        self.init()
        try decode(data: data)
    }

    // MARK: - Decoding

    /// Decode the static frame from raw data
    public mutating func decode(data: Data) throws {
        var offset = 0

        // Check header tag "#UT"
        guard data.count >= 68 else {
            throw UICBarcodeError.invalidFrameSize(expected: 68, actual: data.count)
        }

        guard let headerTag = data.readASCIIString(at: offset, length: 3), headerTag == "#UT" else {
            throw UICBarcodeError.invalidHeader("Not a UIC barcode - missing #UT header")
        }
        offset += 3

        // Version (2 characters)
        guard let versionStr = data.readASCIIString(at: offset, length: 2),
              let ver = Int(versionStr) else {
            throw UICBarcodeError.unsupportedVersion("Invalid version format")
        }
        self.version = ver
        offset += 2

        guard version == 1 || version == 2 else {
            throw UICBarcodeError.unsupportedVersion("UIC barcode version \(version) not supported")
        }

        // Security provider (4 characters)
        guard let provider = data.readASCIIString(at: offset, length: 4) else {
            throw UICBarcodeError.invalidHeader("Missing security provider")
        }
        self.securityProvider = provider
        offset += 4

        // Signature key ID (5 characters)
        guard let keyId = data.readASCIIString(at: offset, length: 5) else {
            throw UICBarcodeError.invalidHeader("Missing signature key ID")
        }
        self.signatureKeyId = keyId
        offset += 5

        // Signature
        let signatureLength = version == 1 ? 50 : 64

        guard offset + signatureLength <= data.count else {
            throw UICBarcodeError.invalidFrameSize(expected: offset + signatureLength, actual: data.count)
        }

        let rawSignature = data[offset..<(offset + signatureLength)]
        self.signature = try processSignature(Data(rawSignature), version: version)
        offset += signatureLength

        // Data length (4 characters)
        guard let lengthStr = data.readASCIIString(at: offset, length: 4)?.trimmingCharacters(in: .whitespaces),
              let dataLength = Int(lengthStr) else {
            throw UICBarcodeError.invalidHeader("Invalid data length")
        }
        offset += 4

        // Signed data (compressed)
        guard offset + dataLength <= data.count else {
            throw UICBarcodeError.invalidFrameSize(expected: offset + dataLength, actual: data.count)
        }

        self.signedData = Data(data[offset..<(offset + dataLength)])

        // Decompress the data
        let decompressedData = try CompressionUtility.decompress(signedData)

        // Parse data records
        try parseDataRecords(decompressedData)
    }

    // MARK: - Signature Processing

    /// Process the raw signature bytes
    private func processSignature(_ rawSignature: Data, version: Int) throws -> Data {
        if version == 1 {
            // Version 1: DSA signature in DER format, padded to 50 bytes
            return try trimDsaSignature(rawSignature)
        } else {
            // Version 2: ECDSA signature split into r and s components (32 bytes each)
            return try recombineDsaSignature(rawSignature)
        }
    }

    /// Trim trailing zeros from DSA signature (version 1)
    private func trimDsaSignature(_ data: Data) throws -> Data {
        // Try to decode as DER SEQUENCE
        guard data.count >= 8,
              data[0] == 0x30 else { // SEQUENCE tag
            throw UICBarcodeError.signatureInvalid("Not a valid DER signature")
        }

        let sequenceLength = Int(data[1])
        guard sequenceLength + 2 <= data.count else {
            throw UICBarcodeError.signatureInvalid("Invalid DER sequence length")
        }

        // Return just the valid portion
        return Data(data.prefix(sequenceLength + 2))
    }

    /// Recombine split r and s components into DER format (version 2)
    private func recombineDsaSignature(_ data: Data) throws -> Data {
        guard data.count == 64 else {
            throw UICBarcodeError.signatureInvalid("Invalid ECDSA signature length")
        }

        // Check if already in DER format (some implementations encode it incorrectly)
        if data[0] == 0x30 {
            // Try to decode as DER
            if let decoded = try? decodeSignatureIntegerSequence(data) {
                return try encodeSignatureIntegerSequence(r: decoded.0, s: decoded.1)
            }
        }

        // Split into r and s (32 bytes each)
        let rBytes = Data(data[0..<32])
        let sBytes = Data(data[32..<64])

        // Convert to integers (removing leading zeros)
        let r = trimLeadingZeros(rBytes)
        let s = trimLeadingZeros(sBytes)

        // Encode as DER
        return try encodeSignatureIntegerSequence(r: r, s: s)
    }

    /// Trim leading zeros from a byte array
    private func trimLeadingZeros(_ data: Data) -> Data {
        var result = data
        while result.count > 1 && result[0] == 0 {
            result = Data(result.dropFirst())
        }
        return result
    }

    /// Decode a DER-encoded signature integer sequence
    private func decodeSignatureIntegerSequence(_ data: Data) throws -> (Data, Data) {
        guard data.count >= 8,
              data[0] == 0x30 else { // SEQUENCE tag
            throw UICBarcodeError.signatureInvalid("Not a DER sequence")
        }

        _ = Int(data[1]) // sequence length
        var offset = 2

        // First INTEGER
        guard data[offset] == 0x02 else { // INTEGER tag
            throw UICBarcodeError.signatureInvalid("Expected INTEGER tag for r")
        }
        offset += 1
        let rLength = Int(data[offset])
        offset += 1
        let r = Data(data[offset..<(offset + rLength)])
        offset += rLength

        // Second INTEGER
        guard data[offset] == 0x02 else { // INTEGER tag
            throw UICBarcodeError.signatureInvalid("Expected INTEGER tag for s")
        }
        offset += 1
        let sLength = Int(data[offset])
        offset += 1
        let s = Data(data[offset..<(offset + sLength)])

        return (r, s)
    }

    /// Encode r and s as DER-formatted signature
    private func encodeSignatureIntegerSequence(r: Data, s: Data) throws -> Data {
        var rBytes = r
        var sBytes = s

        // Add leading zero if high bit is set (to indicate positive number)
        if !rBytes.isEmpty && (rBytes[0] & 0x80) != 0 {
            rBytes.insert(0, at: 0)
        }
        if !sBytes.isEmpty && (sBytes[0] & 0x80) != 0 {
            sBytes.insert(0, at: 0)
        }

        // Build DER structure
        let sequenceLength = 2 + rBytes.count + 2 + sBytes.count
        var result = Data()
        result.append(0x30) // SEQUENCE tag
        result.append(UInt8(sequenceLength))
        result.append(0x02) // INTEGER tag
        result.append(UInt8(rBytes.count))
        result.append(rBytes)
        result.append(0x02) // INTEGER tag
        result.append(UInt8(sBytes.count))
        result.append(sBytes)

        return result
    }

    // MARK: - Data Record Parsing

    /// Parse the decompressed data records
    private mutating func parseDataRecords(_ data: Data) throws {
        var offset = 0

        while offset + 12 < data.count {
            // Each record has: tag (6), version (2), length (4), content (length - 12)
            guard let tag = data.readASCIIString(at: offset, length: 6) else {
                break
            }

            // Read version (just validate it exists)
            guard data.readASCIIString(at: offset + 6, length: 2) != nil else {
                break
            }

            // Read length
            guard let lengthStr = data.readASCIIString(at: offset + 8, length: 4)?.trimmingCharacters(in: .whitespaces),
                  let recordLength = Int(lengthStr) else {
                break
            }

            guard offset + recordLength <= data.count else {
                break
            }

            let recordData = Data(data[offset..<(offset + recordLength)])

            // Parse based on tag
            if tag.hasPrefix("U_TLAY") {
                let record = try UTLAYDataRecord(data: recordData)
                layoutRecords.append(record)
            } else if tag.hasPrefix("U_FLEX") {
                flexRecord = try UFLEXDataRecord(data: recordData)
            } else if tag.hasPrefix("U_HEAD") {
                headerRecord = try UHEADDataRecord(data: recordData)
            } else {
                // Generic record
                let record = try GenericDataRecord(data: recordData)
                dataRecords.append(record)
            }

            offset += recordLength
        }

        // Update security provider from ticket data if available
        // 3-stage priority cascade matching Java's StaticFrame.decodeContent():
        // Each stage overwrites the previous if it has a non-empty value.

        // Stage 1: U_HEAD issuer
        if let header = headerRecord, !header.issuer.isEmpty {
            self.securityProvider = header.issuer
        }

        // Stage 2: ticket issuer (issuerIA5 preferred, fallback to issuerNum)
        if let detail = flexRecord?.ticket?.issuingDetail {
            if let ia5 = detail.issuerIA5, !ia5.isEmpty {
                self.securityProvider = ia5
            } else if let num = detail.issuerNum {
                self.securityProvider = String(num)
            }
        }

        // Stage 3: ticket security provider (securityProviderIA5 preferred, fallback to securityProviderNum)
        if let detail = flexRecord?.ticket?.issuingDetail {
            if let ia5 = detail.securityProviderIA5, !ia5.isEmpty {
                self.securityProvider = ia5
            } else if let num = detail.securityProviderNum {
                self.securityProvider = String(num)
            }
        }
    }
}

// MARK: - StaticFrame Encoding

extension StaticFrame {

    /// Encode the static frame to raw barcode data.
    /// Note: The signature field must already be set (either raw DER or will be converted).
    /// - Returns: The complete barcode bytes (#UT header + signature + compressed data)
    public func encode() throws -> Data {
        // Build data records
        let recordsData = try encodeDataRecords()

        // Compress data records
        let compressedData = try CompressionUtility.compress(recordsData)

        // Build the complete frame
        var result = Data()

        // Header tag "#UT"
        result.append(contentsOf: [0x23, 0x55, 0x54]) // "#UT"

        // Version (2 chars, zero-padded)
        let versionStr = String(format: "%02d", version)
        result.append(contentsOf: versionStr.utf8)

        // Security provider (4 chars, space-padded)
        let providerStr = securityProvider.padding(toLength: 4, withPad: " ", startingAt: 0)
        result.append(contentsOf: providerStr.utf8)

        // Signature key ID (5 chars, zero-padded)
        let keyIdStr = signatureKeyId.padding(toLength: 5, withPad: "0", startingAt: 0)
        result.append(contentsOf: keyIdStr.utf8)

        // Signature (version-dependent size)
        let signatureData = try encodeSignature()
        result.append(signatureData)

        // Data length (4 chars, zero-padded)
        let lengthStr = String(format: "%04d", compressedData.count)
        result.append(contentsOf: lengthStr.utf8)

        // Compressed data
        result.append(compressedData)

        return result
    }

    /// Encode all data records into a single Data blob (before compression).
    public func encodeDataRecords() throws -> Data {
        var result = Data()

        // U_HEAD record
        if let header = headerRecord {
            result.append(try header.encode())
        }

        // U_TLAY records
        for layout in layoutRecords {
            result.append(try layout.encode())
        }

        // U_FLEX record
        if let flex = flexRecord {
            result.append(try flex.encode())
        }

        // Generic records
        for record in dataRecords {
            result.append(record.encode())
        }

        return result
    }

    /// Build the data that should be signed (compressed data records).
    public func buildDataForSignature() throws -> Data {
        let recordsData = try encodeDataRecords()
        return try CompressionUtility.compress(recordsData)
    }

    // MARK: - Signature Encoding

    /// Encode the signature to the format expected by the static frame.
    /// V1: DER format padded to 50 bytes
    /// V2: raw r||s format, 32 bytes each = 64 bytes total
    private func encodeSignature() throws -> Data {
        if version == 1 {
            // V1: DER signature padded to 50 bytes with trailing zeros
            var padded = signature
            if padded.count < 50 {
                padded.append(Data(repeating: 0, count: 50 - padded.count))
            } else if padded.count > 50 {
                padded = Data(padded.prefix(50))
            }
            return padded
        } else {
            // V2: ECDSA signature as r||s (32+32 = 64 bytes)
            // If signature is in DER format, convert to raw r||s
            if !signature.isEmpty && signature[0] == 0x30 {
                return try derToRawSignature(signature)
            }
            // Already in raw format, pad/trim to 64 bytes
            var padded = signature
            if padded.count < 64 {
                padded.append(Data(repeating: 0, count: 64 - padded.count))
            } else if padded.count > 64 {
                padded = Data(padded.prefix(64))
            }
            return padded
        }
    }

    /// Convert a DER-encoded ECDSA signature to raw r||s format (32+32 bytes)
    private func derToRawSignature(_ derSig: Data) throws -> Data {
        guard derSig.count >= 8, derSig[0] == 0x30 else {
            throw UICBarcodeError.signatureInvalid("Not a DER sequence")
        }

        var offset = 2

        // Parse r
        guard derSig[offset] == 0x02 else {
            throw UICBarcodeError.signatureInvalid("Expected INTEGER tag for r")
        }
        offset += 1
        let rLength = Int(derSig[offset])
        offset += 1
        var r = Data(derSig[offset..<(offset + rLength)])
        offset += rLength

        // Parse s
        guard derSig[offset] == 0x02 else {
            throw UICBarcodeError.signatureInvalid("Expected INTEGER tag for s")
        }
        offset += 1
        let sLength = Int(derSig[offset])
        offset += 1
        var s = Data(derSig[offset..<(offset + sLength)])

        // Remove leading zero padding (DER sign byte)
        while r.count > 32 && r[0] == 0 { r = Data(r.dropFirst()) }
        while s.count > 32 && s[0] == 0 { s = Data(s.dropFirst()) }

        // Left-pad to 32 bytes
        if r.count < 32 { r = Data(repeating: 0, count: 32 - r.count) + r }
        if s.count < 32 { s = Data(repeating: 0, count: 32 - s.count) + s }

        return r + s
    }
}

// MARK: - StaticFrame Signing

extension StaticFrame {

    /// Sign the static frame with an ECDSA P-256 private key.
    /// Builds the data for signature, signs it, and sets the signature field.
    /// - Parameter privateKey: The ECDSA P-256 private key
    public mutating func sign(privateKey: P256.Signing.PrivateKey) throws {
        let dataToSign = try buildDataForSignature()
        let derSignature = try SignatureSigner.signECDSA_P256(data: dataToSign, privateKey: privateKey)
        self.signature = derSignature
    }

    /// Sign the static frame using the specified algorithm OID and raw private key bytes.
    /// - Parameters:
    ///   - privateKeyData: The raw private key bytes
    ///   - algorithmOID: The signing algorithm OID
    public mutating func sign(privateKeyData: Data, algorithmOID: String) throws {
        let dataToSign = try buildDataForSignature()
        let derSignature = try SignatureSigner.sign(data: dataToSign, privateKeyData: privateKeyData, algorithmOID: algorithmOID)
        self.signature = derSignature
    }
}
