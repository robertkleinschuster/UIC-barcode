import Foundation

/// ASN.1 Unaligned Packed Encoding Rules (UPER) Decoder
public struct UPERDecoder {
    /// The underlying bit buffer
    public var buffer: BitBuffer

    /// Current bit position (for debugging)
    public var position: Int { buffer.position }

    /// Remaining bits
    public var remaining: Int { buffer.remaining }

    // MARK: - Initialization

    /// Initialize with raw data
    public init(data: Data) {
        self.buffer = BitBuffer(data: data)
    }

    /// Initialize with byte array
    public init(bytes: [UInt8]) {
        self.buffer = BitBuffer(bytes: bytes)
    }

    /// Initialize with existing BitBuffer
    public init(buffer: BitBuffer) {
        self.buffer = buffer
    }

    // MARK: - Basic Bit Operations

    /// Read a single bit as boolean
    public mutating func decodeBit() throws -> Bool {
        return try buffer.getBit()
    }

    /// Read multiple bits as UInt64
    public mutating func decodeBits(_ count: Int) throws -> UInt64 {
        return try buffer.getBits(count)
    }

    /// Skip bits
    public mutating func skip(_ bits: Int) throws {
        try buffer.skip(bits)
    }

    /// Align to byte boundary
    public mutating func alignToByte() {
        buffer.alignToByte()
    }

    // MARK: - Length Determinant

    /// Decode a length determinant (unconstrained)
    /// - Returns: The decoded length
    public mutating func decodeLengthDeterminant() throws -> Int {
        // First bit indicates if length < 128
        let bit8 = try buffer.getBit()

        if !bit8 {
            // Length is < 128, encoded in 7 bits (we already read the first 0 bit)
            let length = try buffer.getBits(7)
            return Int(length)
        } else {
            // Second bit indicates if length < 16384
            let bit7 = try buffer.getBit()

            if !bit7 {
                // Length is < 16384, encoded in 14 bits (we already read the first 10 bits)
                let length = try buffer.getBits(14)
                return Int(length)
            } else {
                // Large length (fragmented encoding) - not commonly used in UIC barcodes
                throw UICBarcodeError.asn1InvalidLength("Lengths >= 16384 are not supported")
            }
        }
    }

    /// Decode a constrained length determinant
    public mutating func decodeConstrainedLength(min: Int, max: Int) throws -> Int {
        return try decodeConstrainedInt(min: Int64(min), max: Int64(max))
    }

    // MARK: - Normally Small Number

    /// Decode a normally small non-negative integer (for bitmask lengths, choice indexes in extensions)
    public mutating func decodeSmallNonNegativeInteger() throws -> Int {
        let isLarge = try buffer.getBit()

        if !isLarge {
            // Value is <= 63, encoded in 6 bits
            let value = try buffer.getBits(6)
            return Int(value)
        } else {
            // Value > 63, use length determinant
            let length = try decodeLengthDeterminant()
            // Read as unconstrained integer
            let value = try decodeUnconstrainedInteger(lengthInOctets: length)
            return Int(value)
        }
    }

    /// Decode length of a bitmask (for extensions)
    public mutating func decodeBitmaskLength() throws -> Int {
        // In UPER, bitmask length is encoded as normally-small-non-negative-integer + 1
        return try decodeSmallNonNegativeInteger() + 1
    }

    // MARK: - Integer Decoding

    /// Decode a constrained integer with known range
    public mutating func decodeConstrainedInt(min: Int64, max: Int64, hasExtensionMarker: Bool = false) throws -> Int {
        guard max >= min else {
            throw UICBarcodeError.asn1ConstraintViolation("Invalid range: min \(min) > max \(max)")
        }

        // Check extension marker if present
        if hasExtensionMarker {
            let extensionActive = try buffer.getBit()
            if extensionActive {
                throw UICBarcodeError.asn1UnsupportedExtension("Extended integer values not supported")
            }
        }

        let range = UInt64(max - min + 1)

        // Single value range - no bits needed
        if range == 1 {
            return Int(min)
        }

        // Calculate bits needed for the range
        let bitWidth = BigIntOperations.bitsNeeded(for: range - 1)

        // Read the value
        let encoded = try buffer.getBits(bitWidth)
        let value = Int64(encoded) + min

        // Validate result
        guard value >= min && value <= max else {
            throw UICBarcodeError.asn1ConstraintViolation(
                "Decoded value \(value) outside range \(min)..\(max)"
            )
        }

        return Int(value)
    }

    /// Decode an integer with constraint descriptor
    public mutating func decodeConstrainedInt(constraint: ASN1IntegerConstraint) throws -> Int {
        return try decodeConstrainedInt(
            min: constraint.minValue,
            max: constraint.maxValue,
            hasExtensionMarker: constraint.hasExtensionMarker
        )
    }

    /// Decode an unconstrained integer (length-prefixed)
    public mutating func decodeUnconstrainedInteger() throws -> Int64 {
        let lengthInOctets = try decodeLengthDeterminant()
        return try decodeUnconstrainedInteger(lengthInOctets: lengthInOctets)
    }

    /// Decode an unconstrained integer with known length
    private mutating func decodeUnconstrainedInteger(lengthInOctets: Int) throws -> Int64 {
        guard lengthInOctets > 0 else { return 0 }

        var result: Int64 = 0
        var isNegative = false

        for i in 0..<lengthInOctets {
            let byte = try buffer.getByte()
            if i == 0 {
                // Check sign bit
                isNegative = (byte & 0x80) != 0
                if isNegative {
                    result = -1 // Start with all 1s for sign extension
                }
            }
            result = (result << 8) | Int64(byte)
        }

        return result
    }

    /// Decode a semi-constrained integer (has minimum, no maximum)
    public mutating func decodeSemiConstrainedInteger(min: Int64) throws -> Int64 {
        let lengthInOctets = try decodeLengthDeterminant()
        var value: UInt64 = 0

        for _ in 0..<lengthInOctets {
            let byte = try buffer.getByte()
            value = (value << 8) | UInt64(byte)
        }

        return min + Int64(value)
    }

    // MARK: - Boolean

    /// Decode a BOOLEAN
    public mutating func decodeBoolean() throws -> Bool {
        return try buffer.getBit()
    }

    // MARK: - Enumerated

    /// Decode an ENUMERATED value
    public mutating func decodeEnumerated(descriptor: ASN1EnumDescriptor) throws -> Int {
        if descriptor.hasExtensionMarker {
            let extensionActive = try buffer.getBit()
            if extensionActive {
                // Extension value - decode as small non-negative integer
                return try decodeSmallNonNegativeInteger() + descriptor.rootValues
            }
        }

        // Root value
        return try decodeConstrainedInt(min: 0, max: Int64(descriptor.rootValues - 1))
    }

    /// Decode an ENUMERATED value with root count
    public mutating func decodeEnumerated(rootCount: Int, hasExtensionMarker: Bool = false) throws -> Int {
        return try decodeEnumerated(
            descriptor: ASN1EnumDescriptor(rootValues: rootCount, hasExtensionMarker: hasExtensionMarker)
        )
    }

    // MARK: - String Decoding

    /// Decode an IA5String (ASCII 0-127)
    public mutating func decodeIA5String(constraint: ASN1StringConstraint? = nil) throws -> String {
        let length: Int
        if let fixed = constraint?.fixedLength {
            length = fixed
        } else if let minLen = constraint?.minLength, let maxLen = constraint?.maxLength {
            length = try decodeConstrainedInt(min: Int64(minLen), max: Int64(maxLen))
        } else {
            length = try decodeLengthDeterminant()
        }

        var chars = [Character]()
        chars.reserveCapacity(length)

        if let alphabet = constraint?.alphabet {
            // Restricted alphabet
            let sortedAlphabet = String(alphabet.sorted())
            let alphabetSize = sortedAlphabet.count
            for _ in 0..<length {
                let index = try decodeConstrainedInt(min: 0, max: Int64(alphabetSize - 1))
                let charIndex = sortedAlphabet.index(sortedAlphabet.startIndex, offsetBy: index)
                chars.append(sortedAlphabet[charIndex])
            }
        } else {
            // Standard IA5 (7-bit ASCII)
            for _ in 0..<length {
                let charCode = try decodeConstrainedInt(min: 0, max: 127)
                if let scalar = UnicodeScalar(charCode) {
                    chars.append(Character(scalar))
                }
            }
        }

        return String(chars)
    }

    /// Decode a UTF8String
    public mutating func decodeUTF8String(constraint: ASN1StringConstraint? = nil) throws -> String {
        let numOctets: Int
        if let fixed = constraint?.fixedLength {
            numOctets = fixed
        } else {
            numOctets = try decodeLengthDeterminant()
        }

        var bytes = [UInt8]()
        bytes.reserveCapacity(numOctets)

        for _ in 0..<numOctets {
            bytes.append(try buffer.getByte())
        }

        guard let result = String(bytes: bytes, encoding: .utf8) else {
            throw UICBarcodeError.asn1DecodingError("Invalid UTF-8 sequence")
        }

        return result
    }

    /// Decode a VisibleString (printable ASCII 32-126)
    public mutating func decodeVisibleString(constraint: ASN1StringConstraint? = nil) throws -> String {
        let length: Int
        if let fixed = constraint?.fixedLength {
            length = fixed
        } else if let minLen = constraint?.minLength, let maxLen = constraint?.maxLength {
            length = try decodeConstrainedInt(min: Int64(minLen), max: Int64(maxLen))
        } else {
            length = try decodeLengthDeterminant()
        }

        var chars = [Character]()
        chars.reserveCapacity(length)

        if let alphabet = constraint?.alphabet {
            // Restricted alphabet
            let sortedAlphabet = String(alphabet.sorted())
            let alphabetSize = sortedAlphabet.count
            for _ in 0..<length {
                let index = try decodeConstrainedInt(min: 0, max: Int64(alphabetSize - 1))
                let charIndex = sortedAlphabet.index(sortedAlphabet.startIndex, offsetBy: index)
                chars.append(sortedAlphabet[charIndex])
            }
        } else {
            // Standard VisibleString (7-bit printable)
            for _ in 0..<length {
                let charCode = try decodeConstrainedInt(min: 0, max: 126)
                if let scalar = UnicodeScalar(charCode) {
                    chars.append(Character(scalar))
                }
            }
        }

        return String(chars)
    }

    /// Decode a NumericString (digits 0-9 and space)
    public mutating func decodeNumericString(constraint: ASN1StringConstraint? = nil) throws -> String {
        let numericAlphabet = " 0123456789"
        let length: Int
        if let fixed = constraint?.fixedLength {
            length = fixed
        } else if let minLen = constraint?.minLength, let maxLen = constraint?.maxLength {
            length = try decodeConstrainedInt(min: Int64(minLen), max: Int64(maxLen))
        } else {
            length = try decodeLengthDeterminant()
        }

        var chars = [Character]()
        chars.reserveCapacity(length)

        for _ in 0..<length {
            // 4 bits for numeric string (0-10 for space and digits)
            let index = try decodeConstrainedInt(min: 0, max: 10)
            let charIndex = numericAlphabet.index(numericAlphabet.startIndex, offsetBy: index)
            chars.append(numericAlphabet[charIndex])
        }

        return String(chars)
    }

    // MARK: - Octet String

    /// Decode an OCTET STRING
    public mutating func decodeOctetString(minSize: Int? = nil, maxSize: Int? = nil) throws -> Data {
        let length: Int
        if let min = minSize, let max = maxSize, min == max {
            // Fixed size
            length = min
        } else if let min = minSize, let max = maxSize {
            // Constrained size
            length = try decodeConstrainedInt(min: Int64(min), max: Int64(max))
        } else {
            // Unconstrained
            length = try decodeLengthDeterminant()
        }

        return try buffer.getBytes(length)
    }

    // MARK: - Bit String

    /// Decode a BIT STRING with known size constraint
    public mutating func decodeBitString(minSize: Int? = nil, maxSize: Int? = nil) throws -> [Bool] {
        let length: Int
        if let min = minSize, let max = maxSize, min == max {
            length = min
        } else if let min = minSize, let max = maxSize {
            length = try decodeConstrainedInt(min: Int64(min), max: Int64(max))
        } else {
            length = try decodeLengthDeterminant()
        }

        var bits = [Bool]()
        bits.reserveCapacity(length)

        for _ in 0..<length {
            bits.append(try buffer.getBit())
        }

        return bits
    }

    // MARK: - Sequence Of

    /// Decode a SEQUENCE OF with element decoder
    public mutating func decodeSequenceOf<T: ASN1Decodable>(
        constraint: ASN1SequenceOfConstraint = .unconstrained
    ) throws -> [T] {
        let count: Int

        if let min = constraint.minSize, let max = constraint.maxSize, min == max {
            count = min
        } else if let min = constraint.minSize, let max = constraint.maxSize {
            count = try decodeConstrainedInt(
                min: Int64(min),
                max: Int64(max),
                hasExtensionMarker: constraint.hasExtensionMarker
            )
        } else {
            count = try decodeLengthDeterminant()
        }

        var elements = [T]()
        elements.reserveCapacity(count)

        for _ in 0..<count {
            let element = try T(from: &self)
            elements.append(element)
        }

        return elements
    }

    /// Decode a SEQUENCE OF integers
    public mutating func decodeSequenceOfInt(
        elementConstraint: ASN1IntegerConstraint,
        sizeConstraint: ASN1SequenceOfConstraint = .unconstrained
    ) throws -> [Int] {
        let count: Int

        if let min = sizeConstraint.minSize, let max = sizeConstraint.maxSize, min == max {
            count = min
        } else if let min = sizeConstraint.minSize, let max = sizeConstraint.maxSize {
            count = try decodeConstrainedInt(
                min: Int64(min),
                max: Int64(max),
                hasExtensionMarker: sizeConstraint.hasExtensionMarker
            )
        } else {
            count = try decodeLengthDeterminant()
        }

        var elements = [Int]()
        elements.reserveCapacity(count)

        for _ in 0..<count {
            let value = try decodeConstrainedInt(constraint: elementConstraint)
            elements.append(value)
        }

        return elements
    }

    // MARK: - Choice

    /// Decode a CHOICE index
    public mutating func decodeChoiceIndex(descriptor: ASN1ChoiceDescriptor) throws -> Int {
        if descriptor.hasExtensionMarker {
            let extensionActive = try buffer.getBit()
            if extensionActive {
                // Extension choice - decode as small non-negative integer
                let extensionIndex = try decodeSmallNonNegativeInteger()
                return descriptor.rootAlternativeCount + extensionIndex
            }
        }

        // Root choice
        let rootCount = descriptor.rootAlternativeCount
        if rootCount == 1 {
            return 0
        }

        return try decodeConstrainedInt(min: 0, max: Int64(rootCount - 1))
    }

    /// Decode a CHOICE index with simple parameters
    public mutating func decodeChoiceIndex(rootCount: Int, hasExtensionMarker: Bool = false) throws -> Int {
        return try decodeChoiceIndex(
            descriptor: ASN1ChoiceDescriptor(
                alternatives: (0..<rootCount).map { ASN1ChoiceAlternative(index: $0, name: "alt\($0)") },
                hasExtensionMarker: hasExtensionMarker
            )
        )
    }

    // MARK: - Open Type (for extensions)

    /// Decode an open type wrapper (for extension fields)
    public mutating func decodeOpenType<T: ASN1Decodable>() throws -> T {
        // Open type is length-prefixed
        let lengthInOctets = try decodeLengthDeterminant()

        // Read the contained bytes
        let containedBytes = try buffer.getBytes(lengthInOctets)

        // Create a new decoder for the contained data
        var innerDecoder = UPERDecoder(data: containedBytes)

        // Decode the actual type
        return try T(from: &innerDecoder)
    }

    /// Skip an unknown extension element
    public mutating func skipOpenType() throws {
        let lengthInOctets = try decodeLengthDeterminant()
        try buffer.skip(lengthInOctets * 8)
    }

    // MARK: - Presence Bitmap

    /// Decode a presence bitmap for optional fields
    public mutating func decodePresenceBitmap(count: Int) throws -> [Bool] {
        var bitmap = [Bool]()
        bitmap.reserveCapacity(count)

        for _ in 0..<count {
            bitmap.append(try buffer.getBit())
        }

        return bitmap
    }
}

// MARK: - Generic Decode Method

extension UPERDecoder {
    /// Decode any ASN1Decodable type
    public mutating func decode<T: ASN1Decodable>(_ type: T.Type) throws -> T {
        return try T(from: &self)
    }
}
