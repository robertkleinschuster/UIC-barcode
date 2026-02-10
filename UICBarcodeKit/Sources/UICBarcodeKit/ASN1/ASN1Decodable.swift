import Foundation

// MARK: - ASN.1 Decodable Protocol

/// Protocol for types that can be decoded from ASN.1 UPER encoding
public protocol ASN1Decodable {
    /// Decode from a UPER decoder
    init(from decoder: inout UPERDecoder) throws
}

// MARK: - ASN.1 Type Metadata

/// Describes the ASN.1 type structure for decoding
public protocol ASN1TypeDescriptor {
    /// Whether this type has an extension marker
    static var hasExtensionMarker: Bool { get }
}

/// Default implementation for types without extension marker
public extension ASN1TypeDescriptor {
    static var hasExtensionMarker: Bool { false }
}

// MARK: - Field Metadata

/// Describes an optional field in a SEQUENCE
public struct ASN1OptionalField {
    public let name: String
    public let isExtension: Bool
    public let defaultValue: Any?

    public init(name: String, isExtension: Bool = false, defaultValue: Any? = nil) {
        self.name = name
        self.isExtension = isExtension
        self.defaultValue = defaultValue
    }
}

// MARK: - Integer Constraints

/// Describes constraints for an ASN.1 INTEGER
public struct ASN1IntegerConstraint {
    public let minValue: Int64
    public let maxValue: Int64
    public let hasExtensionMarker: Bool

    public init(min: Int64, max: Int64, hasExtensionMarker: Bool = false) {
        self.minValue = min
        self.maxValue = max
        self.hasExtensionMarker = hasExtensionMarker
    }

    /// Range of possible values
    public var range: UInt64 {
        return UInt64(maxValue - minValue + 1)
    }

    /// Number of bits needed to encode values in this range
    public var bitWidth: Int {
        guard range > 1 else { return 0 }
        return BigIntOperations.bitsNeeded(for: range - 1)
    }

    /// Unconstrained integer
    public static let unconstrained = ASN1IntegerConstraint(min: Int64.min, max: Int64.max)
}

// MARK: - String Constraints

/// Type of ASN.1 string restriction
public enum ASN1StringType {
    case ia5String          // ASCII subset (0-127)
    case utf8String         // Full UTF-8
    case visibleString      // Printable ASCII (32-126)
    case numericString      // Digits and space only
    case objectIdentifier   // OID format
}

/// Describes constraints for an ASN.1 string
public struct ASN1StringConstraint {
    public let type: ASN1StringType
    public let minLength: Int?
    public let maxLength: Int?
    public let fixedLength: Int?
    public let alphabet: String?
    public let hasExtensionMarker: Bool

    public init(
        type: ASN1StringType,
        minLength: Int? = nil,
        maxLength: Int? = nil,
        fixedLength: Int? = nil,
        alphabet: String? = nil,
        hasExtensionMarker: Bool = false
    ) {
        self.type = type
        self.minLength = minLength
        self.maxLength = maxLength
        self.fixedLength = fixedLength
        self.alphabet = alphabet
        self.hasExtensionMarker = hasExtensionMarker
    }

    /// For IA5String with no size constraint
    public static let ia5Unconstrained = ASN1StringConstraint(type: .ia5String)

    /// For UTF8String with no size constraint
    public static let utf8Unconstrained = ASN1StringConstraint(type: .utf8String)
}

// MARK: - Sequence Of Constraints

/// Describes constraints for a SEQUENCE OF
public struct ASN1SequenceOfConstraint {
    public let minSize: Int?
    public let maxSize: Int?
    public let hasExtensionMarker: Bool

    public init(minSize: Int? = nil, maxSize: Int? = nil, hasExtensionMarker: Bool = false) {
        self.minSize = minSize
        self.maxSize = maxSize
        self.hasExtensionMarker = hasExtensionMarker
    }

    /// Unconstrained SEQUENCE OF
    public static let unconstrained = ASN1SequenceOfConstraint()
}

// MARK: - Choice Info

/// Information about a CHOICE alternative
public struct ASN1ChoiceAlternative {
    public let index: Int
    public let name: String
    public let isExtension: Bool

    public init(index: Int, name: String, isExtension: Bool = false) {
        self.index = index
        self.name = name
        self.isExtension = isExtension
    }
}

/// Describes an ASN.1 CHOICE type
public struct ASN1ChoiceDescriptor {
    public let alternatives: [ASN1ChoiceAlternative]
    public let hasExtensionMarker: Bool

    public init(alternatives: [ASN1ChoiceAlternative], hasExtensionMarker: Bool = false) {
        self.alternatives = alternatives
        self.hasExtensionMarker = hasExtensionMarker
    }

    /// Number of root alternatives (non-extension)
    public var rootAlternativeCount: Int {
        return alternatives.filter { !$0.isExtension }.count
    }

    /// Number of extension alternatives
    public var extensionAlternativeCount: Int {
        return alternatives.filter { $0.isExtension }.count
    }
}

// MARK: - Enumeration Info

/// Describes an ASN.1 ENUMERATED type
public struct ASN1EnumDescriptor {
    public let rootValues: Int
    public let hasExtensionMarker: Bool

    public init(rootValues: Int, hasExtensionMarker: Bool = false) {
        self.rootValues = rootValues
        self.hasExtensionMarker = hasExtensionMarker
    }

    /// Number of bits needed for root values
    public var rootBitWidth: Int {
        guard rootValues > 1 else { return 0 }
        return BigIntOperations.bitsNeeded(for: UInt64(rootValues - 1))
    }
}
