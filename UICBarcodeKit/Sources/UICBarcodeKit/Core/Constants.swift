import Foundation

/// Constants for UIC barcode processing
public enum Constants {

    // MARK: - Algorithm OIDs

    /// Elliptic Curve key generation (P-256)
    public static let KG_EC_256 = "1.2.840.10045.3.1.7"
    /// Elliptic Curve key generation
    public static let KG_EC = "1.2.840.10045.2.1"
    /// ECDSA with SHA-256
    public static let ECDSA_SHA256 = "1.2.840.10045.4.3.2"

    /// DSA with SHA-1
    public static let DSA_SHA1 = "1.2.840.10040.4.3"
    /// DSA with SHA-224
    public static let DSA_SHA224 = "2.16.840.1.101.3.4.3.1"
    /// DSA with SHA-256
    public static let DSA_SHA256 = "2.16.840.1.101.3.4.3.2"

    // MARK: - FCB Format Tags

    public static let DATA_TYPE_FCB_VERSION_1 = "FCB1"
    public static let DATA_TYPE_FCB_VERSION_2 = "FCB2"
    public static let DATA_TYPE_FCB_VERSION_3 = "FCB3"

    // MARK: - Dynamic Barcode Format

    public static let DYNAMIC_BARCODE_FORMAT_DEFAULT = "U1"
    public static let DYNAMIC_BARCODE_FORMAT_VERSION_1 = "U1"
    public static let DYNAMIC_BARCODE_FORMAT_VERSION_2 = "U2"

    // MARK: - Validation Return Codes

    public enum Level2Validation {
        public static let ok = 0
        public static let noKey = 1
        public static let noSignature = 2
        public static let fraud = 3
        public static let sigAlgNotImplemented = 4
        public static let keyAlgNotImplemented = 5
        public static let encodingError = 6
    }

    public enum Level1Validation {
        public static let ok = 0
        public static let noKey = 1
        public static let noSignature = 2
        public static let fraud = 3
        public static let sigAlgNotImplemented = 4
        public static let keyAlgNotImplemented = 5
        public static let encodingError = 6
    }
}
