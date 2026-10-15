import Foundation
import CryptoKit

/// Public API for encoding UIC barcodes.
/// Counterpart to `UICBarcodeDecoder` for creating barcode data.
public struct UICBarcodeEncoder {

    public init() {}

    // MARK: - Dynamic Frame Encoding

    /// Encode a Dynamic Frame (DOSIPAS U1/U2) to bytes.
    /// - Parameter frame: The Dynamic Frame to encode
    /// - Returns: UPER-encoded bytes
    public func encodeDynamic(_ frame: DynamicFrame) throws -> Data {
        return try frame.encode()
    }

    /// Encode a Dynamic Frame with signing.
    /// Signs Level 1 and Level 2 data, then encodes the complete frame.
    /// - Parameters:
    ///   - frame: The Dynamic Frame to encode (will be mutated with signatures)
    ///   - level1PrivateKey: P-256 private key for Level 1 signing
    ///   - level2PrivateKey: P-256 private key for Level 2 signing (optional)
    /// - Returns: UPER-encoded bytes with signatures
    public func encodeDynamic(
        _ frame: inout DynamicFrame,
        level1PrivateKey: P256.Signing.PrivateKey,
        level2PrivateKey: P256.Signing.PrivateKey? = nil
    ) throws -> Data {
        try frame.signLevel1(privateKey: level1PrivateKey)
        if let l2Key = level2PrivateKey {
            try frame.signLevel2(privateKey: l2Key)
        }
        return try frame.encode()
    }

    // MARK: - Static Frame Encoding

    /// Encode a Static Frame (#UT) to bytes.
    /// The frame's signature must already be set.
    /// - Parameter frame: The Static Frame to encode
    /// - Returns: Complete barcode bytes (#UT header + signature + compressed data)
    public func encodeStatic(_ frame: StaticFrame) throws -> Data {
        return try frame.encode()
    }

    /// Encode a Static Frame with signing.
    /// Signs the compressed data records, then encodes the complete frame.
    /// - Parameters:
    ///   - frame: The Static Frame to encode (will be mutated with signature)
    ///   - privateKey: P-256 private key for signing
    /// - Returns: Complete barcode bytes with signature
    public func encodeStatic(
        _ frame: inout StaticFrame,
        privateKey: P256.Signing.PrivateKey
    ) throws -> Data {
        try frame.sign(privateKey: privateKey)
        return try frame.encode()
    }

    // MARK: - SSB Frame Encoding

    /// Encode an SSB Frame to 114 bytes.
    /// The frame's signature parts must already be set.
    /// - Parameter frame: The SSB Frame to encode
    /// - Returns: 114-byte SSB frame data
    public func encodeSSB(_ frame: SSBFrame) throws -> Data {
        return try frame.encode()
    }

    /// Encode an SSB Frame with signing.
    /// Signs the data portion, then encodes the complete 114-byte frame.
    /// - Parameters:
    ///   - frame: The SSB Frame to encode (will be mutated with signature)
    ///   - privateKey: P-256 private key for signing
    /// - Returns: 114-byte SSB frame data with signature
    public func encodeSSB(
        _ frame: inout SSBFrame,
        privateKey: P256.Signing.PrivateKey
    ) throws -> Data {
        try frame.sign(privateKey: privateKey)
        return try frame.encode()
    }

    // MARK: - FCB Ticket Encoding

    /// Encode a V3 FCB ticket to UPER bytes.
    /// - Parameter ticket: The V3 ticket data
    /// - Returns: UPER-encoded bytes
    public func encodeFCB(_ ticket: UicRailTicketData) throws -> Data {
        return try FCBVersionEncoder.encode(ticket: ticket)
    }

    /// Encode a V1 FCB ticket to UPER bytes.
    /// - Parameter ticket: The V1 ticket data
    /// - Returns: UPER-encoded bytes
    func encodeFCB(_ ticket: UicRailTicketDataV1) throws -> Data {
        return try FCBVersionEncoder.encode(ticketV1: ticket)
    }

    /// Encode a V2 FCB ticket to UPER bytes.
    /// - Parameter ticket: The V2 ticket data
    /// - Returns: UPER-encoded bytes
    func encodeFCB(_ ticket: UicRailTicketDataV2) throws -> Data {
        return try FCBVersionEncoder.encode(ticketV2: ticket)
    }
}
