import Foundation

/// Frame type enumeration
public enum FrameType {
    case staticFrame(version: StaticFrameVersion)
    case dynamicFrame(version: DynamicFrameVersion)
    case ssbFrame
    case unknown
}

/// Signature data extracted from barcode
public struct SignatureData {
    /// The signature bytes
    public let signature: Data?

    /// Security provider (numeric ID)
    public let securityProviderNum: Int?

    /// Security provider (IA5 string)
    public let securityProviderIA5: String?

    /// Key ID used for signing
    public let keyId: String?

    /// Signing algorithm OID (for dynamic frames)
    public let algorithmOID: String?

    /// Public key or certificate (if embedded)
    public let publicKey: Data?

    /// Data that was signed (for verification)
    public let signedData: Data?

    public init(
        signature: Data? = nil,
        securityProviderNum: Int? = nil,
        securityProviderIA5: String? = nil,
        keyId: String? = nil,
        algorithmOID: String? = nil,
        publicKey: Data? = nil,
        signedData: Data? = nil
    ) {
        self.signature = signature
        self.securityProviderNum = securityProviderNum
        self.securityProviderIA5 = securityProviderIA5
        self.keyId = keyId
        self.algorithmOID = algorithmOID
        self.publicKey = publicKey
        self.signedData = signedData
    }
}

/// Result of decoding a UIC barcode
public struct DecodedBarcode {
    /// The type of frame that was decoded
    public let frameType: FrameType

    /// The decoded ticket data (FCB format)
    public let ticket: UicRailTicketData?

    /// Signature information
    public let signatureData: SignatureData

    /// FCB version (1, 2, or 3), nil for non-FCB barcodes (e.g. SSB)
    public let fcbVersion: Int?

    /// Raw frame data (for advanced use)
    public let rawFrame: Any

    /// Static frame (if applicable)
    public var staticFrame: StaticFrame? {
        rawFrame as? StaticFrame
    }

    /// Dynamic frame (if applicable)
    public var dynamicFrame: DynamicFrame? {
        rawFrame as? DynamicFrame
    }

    /// SSB frame (if applicable)
    public var ssbFrame: SSBFrame? {
        rawFrame as? SSBFrame
    }
}

/// Internal decoder that handles all barcode formats
struct BarcodeDecoder {

    /// Decode barcode data, auto-detecting the format
    func decode(_ data: Data) throws -> DecodedBarcode {
        // Try to detect format from header
        let frameType = detectFrameType(data)

        switch frameType {
        case .staticFrame:
            return try decodeStaticFrame(data)
        case .dynamicFrame:
            return try decodeDynamicFrame(data)
        case .ssbFrame:
            return try decodeSSBFrame(data)
        case .unknown:
            // Try each format in order
            if let result = try? decodeStaticFrame(data) {
                return result
            }
            if let result = try? decodeDynamicFrame(data) {
                return result
            }
            if let result = try? decodeSSBFrame(data) {
                return result
            }
            throw UICBarcodeError.unsupportedFormat("Unable to detect barcode format")
        }
    }

    /// Detect the frame type from the data header
    private func detectFrameType(_ data: Data) -> FrameType {
        guard data.count >= 3 else { return .unknown }

        // Check for Static Frame header "#UT"
        if data.count >= 3 {
            let header = String(data: data[0..<3], encoding: .ascii)
            if header == "#UT" {
                // Determine version
                if data.count >= 5 {
                    let version = String(data: data[3..<5], encoding: .ascii)
                    if version == "01" {
                        return .staticFrame(version: .v1)
                    } else if version == "02" {
                        return .staticFrame(version: .v2)
                    }
                }
                return .staticFrame(version: .v1)
            }
        }

        // Check for SSB Frame (114 bytes, specific bit patterns)
        if data.count == 114 {
            // SSB has version in first 4 bits (should be 1-3)
            let version = (data[0] >> 4) & 0x0F
            if version >= 1 && version <= 3 {
                return .ssbFrame
            }
        }

        // Check for Dynamic Frame (UPER encoded, starts with format string)
        // Dynamic frames typically start with "U1" or "U2" encoded in UPER
        // The first bits would encode the length then the characters
        if data.count > 4 {
            // Try to detect U1/U2 pattern
            // In UPER, an unconstrained IA5String starts with length
            // "U1" or "U2" would be 2 characters
            return .dynamicFrame(version: .v2) // Default to V2, decoder will handle
        }

        return .unknown
    }

    /// Decode a static frame barcode
    private func decodeStaticFrame(_ data: Data) throws -> DecodedBarcode {
        let frame = try StaticFrame(data: data)

        // Extract FCB ticket data from flex record
        let ticket = frame.flexRecord?.ticket

        // Build signature data
        let signatureData = SignatureData(
            signature: frame.signature,
            securityProviderNum: Int(frame.securityProvider),
            securityProviderIA5: frame.securityProvider,
            keyId: frame.signatureKeyId,
            signedData: frame.signedData
        )

        let version: StaticFrameVersion = frame.version == 2 ? .v2 : .v1

        return DecodedBarcode(
            frameType: .staticFrame(version: version),
            ticket: ticket,
            signatureData: signatureData,
            fcbVersion: frame.flexRecord?.fcbVersion,
            rawFrame: frame
        )
    }

    /// Decode a dynamic frame barcode
    private func decodeDynamicFrame(_ data: Data) throws -> DecodedBarcode {
        let frame = try DynamicFrame(data: data)

        // Get ticket data
        let ticket = frame.getTicketData()

        // Determine FCB version from data format
        var fcbVer: Int?
        if let l1 = frame.level1Data {
            for item in l1.dataList {
                if let v = FCBVersionDecoder.parseFormatVersion(item.format) {
                    fcbVer = v
                    break
                }
            }
        }

        // Build signature data
        var signedData: Data?
        if let _ = frame.level1Data {
            signedData = try? frame.getLevel1SignedData()
        }

        let signatureData = SignatureData(
            signature: frame.getLevel1Signature(),
            securityProviderNum: frame.level1Data?.securityProviderNum,
            securityProviderIA5: frame.level1Data?.securityProviderIA5,
            keyId: frame.level1Data?.keyId.map { String($0) },
            algorithmOID: frame.level1Data?.level1SigningAlg,
            publicKey: frame.level1Data?.level2publicKey,
            signedData: signedData
        )

        let version: DynamicFrameVersion = frame.format == "U2" ? .v2 : .v1

        return DecodedBarcode(
            frameType: .dynamicFrame(version: version),
            ticket: ticket,
            signatureData: signatureData,
            fcbVersion: fcbVer,
            rawFrame: frame
        )
    }

    /// Decode an SSB frame barcode
    private func decodeSSBFrame(_ data: Data) throws -> DecodedBarcode {
        let frame = try SSBFrame(data: data)

        // Get signature as DER format
        let signature = try? frame.getSignature()

        // Build signature data
        let signatureData = SignatureData(
            signature: signature,
            securityProviderNum: frame.header.issuer,
            keyId: String(frame.header.keyId),
            signedData: frame.getDataForSignature(data)
        )

        return DecodedBarcode(
            frameType: .ssbFrame,
            ticket: nil,
            signatureData: signatureData,
            fcbVersion: nil,
            rawFrame: frame
        )
    }
}
