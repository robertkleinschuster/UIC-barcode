import Foundation

/// Resolves algorithm OIDs to algorithm names.
/// Simplified Swift equivalent of Java's AlgorithmNameResolver — no provider registry,
/// just a static OID→name mapping.
public enum AlgorithmResolver {

    /// Known signing algorithm OIDs → names
    private static let signatureAlgorithms: [String: String] = [
        "1.2.840.10045.4.3.1": "SHA224withECDSA",
        "1.2.840.10045.4.3.2": "SHA256withECDSA",
        "1.2.840.10045.4.3.3": "SHA384withECDSA",
        "1.2.840.10045.4.3.4": "SHA512withECDSA",
        "1.2.840.10040.4.3":   "SHA1withDSA",
        "2.16.840.1.101.3.4.3.1": "SHA224withDSA",
        "2.16.840.1.101.3.4.3.2": "SHA256withDSA",
    ]

    /// Known key generation algorithm OIDs → names
    private static let keyAlgorithms: [String: String] = [
        "1.2.840.10045.2.1":   "EC",
        "1.2.840.10045.3.1.7": "EC",
        "1.2.840.10040.4.1":   "DSA",
    ]

    /// Resolve a signing algorithm OID to a name.
    public static func getSignatureAlgorithmName(_ oid: String) -> String? {
        if let name = signatureAlgorithms[oid] {
            return name
        }
        return fallbackName(for: oid)
    }

    /// Resolve a key algorithm OID to a name.
    public static func getKeyAlgorithmName(_ oid: String) -> String? {
        if let name = keyAlgorithms[oid] {
            return name
        }
        return fallbackName(for: oid)
    }

    /// Fallback: determine algorithm family from OID prefix.
    private static func fallbackName(for oid: String) -> String? {
        if oid.hasPrefix("1.2.840.10045.4") {
            return "ECDSA"
        } else if oid.hasPrefix("1.2.840.10045.3") {
            return "EC"
        } else if oid.hasPrefix("1.2.840.10045") {
            return "ECDSA"
        } else if oid.hasPrefix("1.2.840.10040") {
            return "DSA"
        }
        return nil
    }
}
