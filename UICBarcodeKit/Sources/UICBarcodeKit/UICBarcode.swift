import Foundation
import CryptoKit

// MARK: - Public API

/// Main decoder for UIC railway barcodes
///
/// Supports decoding of:
/// - Static Frame (U_HEAD, U_TLAY, U_FLEX records)
/// - Dynamic Frame (DOSIPAS U1/U2 format)
/// - SSB Frame (Standard Small Barcode)
///
/// Example usage:
/// ```swift
/// let decoder = UICBarcodeDecoder()
/// let result = try decoder.decode(barcodeData)
///
/// if let ticket = result.ticket {
///     print("Issuer: \(ticket.issuingDetail.issuerName ?? "Unknown")")
/// }
/// ```
public struct UICBarcodeDecoder {

    /// Configuration options for the decoder
    public struct Configuration {
        /// Whether to attempt signature verification when public key is embedded
        public var verifySignature: Bool

        /// Whether to strictly validate format (throws on unknown extensions)
        public var strictValidation: Bool

        public init(
            verifySignature: Bool = false,
            strictValidation: Bool = false
        ) {
            self.verifySignature = verifySignature
            self.strictValidation = strictValidation
        }

        /// Default configuration
        public static let `default` = Configuration()
    }

    private let configuration: Configuration
    private let decoder: BarcodeDecoder

    /// Initialize with default configuration
    public init() {
        self.configuration = .default
        self.decoder = BarcodeDecoder()
    }

    /// Initialize with custom configuration
    public init(configuration: Configuration) {
        self.configuration = configuration
        self.decoder = BarcodeDecoder()
    }

    /// Decode barcode data, auto-detecting the format
    /// - Parameter data: Raw barcode data bytes
    /// - Returns: Decoded barcode containing ticket data and signature information
    /// - Throws: UICBarcodeError if decoding fails
    public func decode(_ data: Data) throws -> DecodedBarcode {
        return try decoder.decode(data)
    }

    /// Decode a static frame barcode
    /// - Parameter data: Raw barcode data with #UT header
    /// - Returns: Decoded static frame
    /// - Throws: UICBarcodeError if decoding fails
    public func decodeStaticFrame(_ data: Data) throws -> StaticFrame {
        return try StaticFrame(data: data)
    }

    /// Decode a dynamic frame barcode
    /// - Parameter data: Raw UPER-encoded dynamic frame data
    /// - Returns: Decoded dynamic frame
    /// - Throws: UICBarcodeError if decoding fails
    public func decodeDynamicFrame(_ data: Data) throws -> DynamicFrame {
        return try DynamicFrame(data: data)
    }

    /// Decode an SSB frame barcode
    /// - Parameter data: 114-byte SSB frame data
    /// - Returns: Decoded SSB frame
    /// - Throws: UICBarcodeError if decoding fails
    public func decodeSSBFrame(_ data: Data) throws -> SSBFrame {
        return try SSBFrame(data: data)
    }

    /// Verify the signature of a decoded barcode
    /// - Parameters:
    ///   - barcode: Previously decoded barcode
    ///   - publicKey: Public key for verification (X.509, SPKI, or raw format)
    /// - Returns: true if signature is valid
    /// - Throws: UICBarcodeError if verification fails
    public func verifySignature(
        _ barcode: DecodedBarcode,
        publicKey: Data
    ) throws -> Bool {
        guard let signature = barcode.signatureData.signature,
              let signedData = barcode.signatureData.signedData else {
            throw UICBarcodeError.signatureInvalid("No signature or signed data available")
        }

        // Determine algorithm from barcode or default to P-256
        if let oid = barcode.signatureData.algorithmOID {
            return try SignatureVerifier.verify(
                signature: signature,
                data: signedData,
                publicKey: publicKey,
                algorithmOID: oid
            )
        }

        // No algorithm OID - try to detect from the public key type
        // Parse SubjectPublicKeyInfo to extract algorithm OID
        if let detectedOID = try? detectKeyAlgorithmOID(publicKey) {
            if detectedOID == "1.2.840.10040.4.1" {
                // DSA key - detect hash algorithm from signature size
                let hashAlg = DSAHashAlgorithm.fromSignature(signature)
                return try SignatureVerifier.verifyDSA(
                    signature: signature,
                    data: signedData,
                    publicKey: publicKey,
                    hashAlgorithm: hashAlg
                )
            } else if detectedOID == "1.2.840.10045.2.1" {
                // EC key - default to P-256
                return try SignatureVerifier.verifyECDSA_P256(
                    signature: signature,
                    data: signedData,
                    publicKey: publicKey
                )
            }
        }

        // Fallback: default to ECDSA P-256
        return try SignatureVerifier.verifyECDSA_P256(
            signature: signature,
            data: signedData,
            publicKey: publicKey
        )
    }

    /// Detect the algorithm OID from a SubjectPublicKeyInfo or X.509 certificate
    private func detectKeyAlgorithmOID(_ keyData: Data) throws -> String {
        // Try parsing as SubjectPublicKeyInfo
        if let tag = keyData.first, tag == 0x30 {
            var parser = DERParser(data: keyData)
            if let oid = try? parser.extractAlgorithmOID() {
                return oid
            }
        }
        throw UICBarcodeError.invalidPublicKey("Unable to detect key algorithm")
    }
}

// MARK: - Convenience Extensions

extension DecodedBarcode {

    /// Get the issuing railway company name
    public var issuerName: String? {
        ticket?.issuingDetail.issuerName
    }

    /// Get the issuing railway company code
    public var issuerCode: Int? {
        ticket?.issuingDetail.issuerNum
    }

    /// Get the ticket reference number
    public var ticketReference: String? {
        ticket?.issuingDetail.issuerPNR
    }

    /// Get the issuance date
    public var issuanceDate: Date? {
        guard let issuing = ticket?.issuingDetail else { return nil }
        return issuing.calculateIssuingDate()
    }

    /// Get the list of travelers
    public var travelers: [TravelerType]? {
        ticket?.travelerDetail?.traveler
    }

    /// Get the first/primary traveler
    public var primaryTraveler: TravelerType? {
        travelers?.first
    }

    /// Check if the barcode has a valid signature data
    public var hasSignature: Bool {
        signatureData.signature != nil && signatureData.signedData != nil
    }

    /// Dynamic content in FDC1 format (if applicable)
    public var dynamicContentFDC1: DynamicContentFDC1? {
        dynamicFrame?.dynamicContent?.fdc1Content
    }

    /// Validate Level 1 signature of a dynamic frame
    public func validateLevel1(publicKey: Data, algorithmOID: String? = nil) -> SignatureValidationResult? {
        dynamicFrame?.validateLevel1(publicKey: publicKey, algorithmOID: algorithmOID)
    }

    /// Version-independent ticket representation.
    /// Converts the V3 ASN.1 ticket data to the API abstraction layer.
    /// Returns nil for non-FCB barcodes (e.g. SSB).
    public var railTicket: SimpleUicRailTicket? {
        guard let ticket else { return nil }
        return UicRailTicketCoder.decode(ticket)
    }
}

extension IssuingData {

    /// Calculate the actual issuance date from days offset
    public func calculateIssuingDate() -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        // Year is offset from 2016
        let actualYear = 2016 + issuingYear

        // Create January 1st of the year
        var components = DateComponents()
        components.year = actualYear
        components.month = 1
        components.day = 1

        guard let startOfYear = calendar.date(from: components) else {
            return nil
        }

        // Add days (1-based, so subtract 1)
        return calendar.date(byAdding: .day, value: issuingDay - 1, to: startOfYear)
    }
}

// MARK: - Re-exports for Public API

// Core types are already public in their respective files:
// - StaticFrame, StaticFrameVersion
// - DynamicFrame, DynamicFrameVersion
// - SSBFrame, SSBHeader, SSBTicket types
// - UicRailTicketData and all FCB model types
// - UICBarcodeError
// - SignatureVerifier (for advanced use)
// - DecodedBarcode, FrameType, SignatureData
