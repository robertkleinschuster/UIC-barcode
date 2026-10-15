import Foundation

// MARK: - ASN.1 Encodable Protocol

/// Protocol for types that can be encoded to ASN.1 UPER encoding
public protocol ASN1Encodable {
    /// Encode to a UPER encoder
    func encode(to encoder: inout UPEREncoder) throws
}
