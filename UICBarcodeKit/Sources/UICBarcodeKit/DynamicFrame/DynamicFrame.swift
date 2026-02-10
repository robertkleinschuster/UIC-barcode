import Foundation
import CryptoKit

/// Dynamic Frame version constants
public enum DynamicFrameVersion: String {
    case v1 = "U1"
    case v2 = "U2"
}

/// Represents a decoded UIC Dynamic Frame barcode (DOSIPAS format)
/// Java ref: DynamicFrame.java (v1 and v2)
public struct DynamicFrame {
    // MARK: - Properties

    /// Frame format version ("U1" or "U2")
    public var format: String = ""

    /// Level 1 data containing the ticket payload
    public var level1Data: DynamicFrameLevel1Data?

    /// Level 2 signed data
    public var level2SignedData: DynamicFrameLevel2Data?

    /// Level 2 signature bytes
    public var level2Signature: Data?

    /// Dynamic content (FDC1 for GPS/Location data, etc.)
    public var dynamicContent: DynamicContent?

    // MARK: - Initialization

    public init() {}

    /// Decode from raw barcode data
    public init(data: Data) throws {
        try decode(data: data)
    }

    // MARK: - Decoding

    /// Decode the dynamic frame from raw data
    public mutating func decode(data: Data) throws {
        // Try V2 first, then V1 (V2 is more common in modern implementations)
        do {
            try decodeV2(data: data)
            return
        } catch {
            // Fall through to V1
        }

        do {
            try decodeV1(data: data)
            return
        } catch {
            throw UICBarcodeError.decodingFailed("Unable to decode dynamic frame as V1 or V2")
        }
    }

    /// Decode as V1 format
    /// ASN.1 (no extension marker):
    ///   UicBarcodeHeader ::= SEQUENCE {
    ///     format              IA5String,
    ///     level2SignedData     Level2DataType,
    ///     level2Signature     OCTET STRING OPTIONAL
    ///   }
    private mutating func decodeV1(data: Data) throws {
        var decoder = UPERDecoder(data: data)

        // No extension marker in V1 schema
        // 1 optional field => 1-bit presence bitmap
        let presence = try decoder.decodePresenceBitmap(count: 1)

        // Read format (mandatory)
        format = try decoder.decodeIA5String()
        guard format == DynamicFrameVersion.v1.rawValue else {
            throw UICBarcodeError.unsupportedVersion("Expected U1, got \(format)")
        }

        // Decode level 2 signed data (mandatory)
        level2SignedData = try DynamicFrameLevel2Data(from: &decoder, version: .v1)

        // Decode optional level 2 signature
        if presence[0] {
            level2Signature = try decoder.decodeOctetString()
        }

        // Extract level 1 data from level 2
        if let l2 = level2SignedData {
            level1Data = l2.level1Data
        }

        // Parse dynamic content from level 2 data if present
        parseDynamicContent()
    }

    /// Decode as V2 format
    /// Same top-level structure as V1 but Level1DataType has additional fields
    private mutating func decodeV2(data: Data) throws {
        var decoder = UPERDecoder(data: data)

        // No extension marker in V2 schema
        // 1 optional field => 1-bit presence bitmap
        let presence = try decoder.decodePresenceBitmap(count: 1)

        // Read format (mandatory)
        format = try decoder.decodeIA5String()
        guard format == DynamicFrameVersion.v2.rawValue else {
            throw UICBarcodeError.unsupportedVersion("Expected U2, got \(format)")
        }

        // Decode level 2 signed data (mandatory)
        level2SignedData = try DynamicFrameLevel2Data(from: &decoder, version: .v2)

        // Decode optional level 2 signature
        if presence[0] {
            level2Signature = try decoder.decodeOctetString()
        }

        // Extract level 1 data from level 2
        if let l2 = level2SignedData {
            level1Data = l2.level1Data
        }

        // Parse dynamic content from level 2 data if present
        parseDynamicContent()
    }

    /// Parse dynamic content (FDC1) from level2Data if present
    private mutating func parseDynamicContent() {
        guard let l2DataItem = level2SignedData?.level2Data else { return }

        if l2DataItem.format == DynamicContentFDC1.format {
            var contentDecoder = UPERDecoder(data: l2DataItem.data)
            dynamicContent = try? .fdc1(DynamicContentFDC1(from: &contentDecoder))
        } else {
            dynamicContent = .unknown(identifier: l2DataItem.format, data: l2DataItem.data)
        }
    }

    // MARK: - Data Access

    /// Get the FCB ticket data if present
    public func getTicketData() -> UicRailTicketData? {
        guard let l1 = level1Data else { return nil }

        for data in l1.dataList {
            if let version = FCBVersionDecoder.parseFormatVersion(data.format) {
                do {
                    return try FCBVersionDecoder.decode(data: data.data, version: version)
                } catch {
                    continue
                }
            }
        }
        return nil
    }

    /// Get the data to be verified for level 1 signature
    public func getLevel1SignedData() throws -> Data {
        guard let l1 = level1Data else {
            throw UICBarcodeError.invalidData("No level 1 data")
        }
        return l1.encodedData
    }

    /// Get the level 1 signature
    public func getLevel1Signature() -> Data? {
        return level2SignedData?.level1Signature
    }
}

// MARK: - DynamicFrame Encoding

extension DynamicFrame {

    /// Encode the dynamic frame to UPER bytes
    public func encode() throws -> Data {
        var encoder = UPEREncoder()

        // No extension marker
        // 1 optional field: level2Signature
        try encoder.encodePresenceBitmap([level2Signature != nil])

        // format (mandatory)
        try encoder.encodeIA5String(format)

        // level2SignedData (mandatory)
        guard let l2 = level2SignedData else {
            throw UICBarcodeError.encodingFailed("DynamicFrame has no level2SignedData")
        }

        let version: DynamicFrameVersion = format == DynamicFrameVersion.v2.rawValue ? .v2 : .v1
        try l2.encode(to: &encoder, version: version)

        // level2Signature (optional)
        if let sig = level2Signature {
            try encoder.encodeOctetString(sig)
        }

        return encoder.toData()
    }

    /// Encode level 1 data to UPER bytes (for signing)
    public func encodeLevel1() throws -> Data {
        guard let l1 = level1Data else {
            throw UICBarcodeError.encodingFailed("DynamicFrame has no level1Data")
        }
        let version: DynamicFrameVersion = format == DynamicFrameVersion.v2.rawValue ? .v2 : .v1
        var encoder = UPEREncoder()
        try l1.encode(to: &encoder, version: version)
        return encoder.toData()
    }

    /// Encode level 2 signed data to UPER bytes (for level 2 signing)
    public func encodeLevel2Data() throws -> Data {
        guard let l2 = level2SignedData else {
            throw UICBarcodeError.encodingFailed("DynamicFrame has no level2SignedData")
        }
        let version: DynamicFrameVersion = format == DynamicFrameVersion.v2.rawValue ? .v2 : .v1
        var encoder = UPEREncoder()
        try l2.encode(to: &encoder, version: version)
        return encoder.toData()
    }
}

// MARK: - DynamicFrame Signing

extension DynamicFrame {

    /// Sign Level 1 data with a P-256 private key and store the signature in level2SignedData.level1Signature.
    /// - Parameter privateKey: The ECDSA P-256 private key
    public mutating func signLevel1(privateKey: P256.Signing.PrivateKey) throws {
        let level1Bytes = try encodeLevel1()
        let signature = try SignatureSigner.signECDSA_P256(data: level1Bytes, privateKey: privateKey)
        level2SignedData?.level1Signature = signature
    }

    /// Sign Level 2 data with a P-256 private key and store the signature in level2Signature.
    /// - Parameter privateKey: The ECDSA P-256 private key
    public mutating func signLevel2(privateKey: P256.Signing.PrivateKey) throws {
        let level2Bytes = try encodeLevel2Data()
        let signature = try SignatureSigner.signECDSA_P256(data: level2Bytes, privateKey: privateKey)
        level2Signature = signature
    }

    /// Sign Level 1 data using the specified algorithm OID and raw private key bytes.
    /// - Parameters:
    ///   - privateKeyData: The raw private key bytes
    ///   - algorithmOID: The signing algorithm OID
    public mutating func signLevel1(privateKeyData: Data, algorithmOID: String) throws {
        let level1Bytes = try encodeLevel1()
        let signature = try SignatureSigner.sign(data: level1Bytes, privateKeyData: privateKeyData, algorithmOID: algorithmOID)
        level2SignedData?.level1Signature = signature
    }

    /// Sign Level 2 data using the specified algorithm OID and raw private key bytes.
    /// - Parameters:
    ///   - privateKeyData: The raw private key bytes
    ///   - algorithmOID: The signing algorithm OID
    public mutating func signLevel2(privateKeyData: Data, algorithmOID: String) throws {
        let level2Bytes = try encodeLevel2Data()
        let signature = try SignatureSigner.sign(data: level2Bytes, privateKeyData: privateKeyData, algorithmOID: algorithmOID)
        level2Signature = signature
    }
}
