import Foundation

/// UPER (Unaligned Packed Encoding Rules) encoder for ASN.1 types.
/// Symmetric counterpart to `UPERDecoder`.
public struct UPEREncoder {
    /// The underlying bit buffer
    public var buffer: BitBuffer

    /// Current bit position
    public var position: Int { buffer.position }

    // MARK: - Initialization

    /// Initialize with an estimated bit capacity
    public init(estimatedBits: Int = 2048) {
        self.buffer = BitBuffer.allocate(bits: estimatedBits)
    }

    /// Initialize with an existing BitBuffer
    public init(buffer: BitBuffer) {
        self.buffer = buffer
    }

    // MARK: - Basic Bit Operations

    /// Write a single bit
    public mutating func encodeBit(_ value: Bool) throws {
        try buffer.putBit(value)
    }

    /// Write multiple bits from a UInt64
    public mutating func encodeBits(_ value: UInt64, count: Int) throws {
        try buffer.putBits(value, count: count)
    }

    /// Align to byte boundary by writing zero bits
    public mutating func alignToByte() throws {
        while buffer.position % 8 != 0 {
            try buffer.putBit(false)
        }
    }

    // MARK: - Length Determinant

    /// Encode a length determinant (unconstrained)
    public mutating func encodeLengthDeterminant(_ length: Int) throws {
        if length < 128 {
            // bit(0) + 7-bit length
            try buffer.putBit(false)
            try buffer.putBits(UInt64(length), count: 7)
        } else if length < 16384 {
            // bits(10) + 14-bit length
            try buffer.putBit(true)
            try buffer.putBit(false)
            try buffer.putBits(UInt64(length), count: 14)
        } else {
            throw UICBarcodeError.asn1InvalidLength("Lengths >= 16384 are not supported")
        }
    }

    // MARK: - Integer Encoding

    /// Encode a constrained integer with known range
    public mutating func encodeConstrainedInt(_ value: Int, min: Int64, max: Int64, hasExtensionMarker: Bool = false) throws {
        guard max >= min else {
            throw UICBarcodeError.asn1ConstraintViolation("Invalid range: min \(min) > max \(max)")
        }

        // Extension marker: encode 0 (not extended)
        if hasExtensionMarker {
            try buffer.putBit(false)
        }

        let range = UInt64(max - min + 1)

        // Single value range - no bits needed
        if range == 1 {
            return
        }

        let bitWidth = BigIntOperations.bitsNeeded(for: range - 1)
        let offsetValue = Int64(value) - min
        guard offsetValue >= 0, Int64(value) <= max else {
            throw UICBarcodeError.asn1ConstraintViolation("Value \(value) out of range \(min)..\(max)")
        }
        let encoded = UInt64(offsetValue)
        try buffer.putBits(encoded, count: bitWidth)
    }

    /// Encode an integer with constraint descriptor
    public mutating func encodeConstrainedInt(_ value: Int, constraint: ASN1IntegerConstraint) throws {
        try encodeConstrainedInt(
            value,
            min: constraint.minValue,
            max: constraint.maxValue,
            hasExtensionMarker: constraint.hasExtensionMarker
        )
    }

    /// Encode an unconstrained integer (length-prefixed, two's complement)
    public mutating func encodeUnconstrainedInteger(_ value: Int64) throws {
        if value == 0 {
            try encodeLengthDeterminant(1)
            try buffer.putBits(0, count: 8)
            return
        }

        // Determine the number of octets needed for two's complement
        var octets = [UInt8]()
        var v = value

        if value > 0 {
            // Positive: encode in big-endian, add leading 0x00 if high bit set
            var temp = [UInt8]()
            while v > 0 {
                temp.append(UInt8(v & 0xFF))
                v >>= 8
            }
            // If high bit of most significant byte is set, prepend 0x00
            if temp.last! & 0x80 != 0 {
                temp.append(0x00)
            }
            octets = temp.reversed()
        } else {
            // Negative: encode in big-endian two's complement
            var temp = [UInt8]()
            while v < -1 {
                temp.append(UInt8(truncatingIfNeeded: v & 0xFF))
                v >>= 8
            }
            temp.append(UInt8(truncatingIfNeeded: v & 0xFF))
            // If high bit of most significant byte is NOT set, prepend 0xFF
            if temp.last! & 0x80 == 0 {
                temp.append(0xFF)
            }
            octets = temp.reversed()
        }

        try encodeLengthDeterminant(octets.count)
        for byte in octets {
            try buffer.putByte(byte)
        }
    }

    /// Encode a semi-constrained integer (has minimum, no maximum)
    public mutating func encodeSemiConstrainedInteger(_ value: Int64, min: Int64) throws {
        let offset = UInt64(value - min)

        // Determine number of octets needed
        var octets = [UInt8]()
        if offset == 0 {
            octets = [0]
        } else {
            var v = offset
            while v > 0 {
                octets.insert(UInt8(v & 0xFF), at: 0)
                v >>= 8
            }
        }

        try encodeLengthDeterminant(octets.count)
        for byte in octets {
            try buffer.putByte(byte)
        }
    }

    // MARK: - Boolean

    /// Encode a BOOLEAN
    public mutating func encodeBoolean(_ value: Bool) throws {
        try buffer.putBit(value)
    }

    // MARK: - Enumerated

    /// Encode an ENUMERATED value
    public mutating func encodeEnumerated(_ value: Int, rootCount: Int, hasExtensionMarker: Bool = false) throws {
        if hasExtensionMarker {
            if value >= rootCount {
                // Extension value
                try buffer.putBit(true)
                try encodeSmallNonNegativeInteger(value - rootCount)
                return
            }
            try buffer.putBit(false)
        }

        // Root value
        try encodeConstrainedInt(value, min: 0, max: Int64(rootCount - 1))
    }

    /// Encode an ENUMERATED value with descriptor
    public mutating func encodeEnumerated(_ value: Int, descriptor: ASN1EnumDescriptor) throws {
        try encodeEnumerated(value, rootCount: descriptor.rootValues, hasExtensionMarker: descriptor.hasExtensionMarker)
    }

    // MARK: - Normally Small Number

    /// Encode a normally small non-negative integer
    public mutating func encodeSmallNonNegativeInteger(_ value: Int) throws {
        if value <= 63 {
            try buffer.putBit(false)
            try buffer.putBits(UInt64(value), count: 6)
        } else {
            try buffer.putBit(true)
            try encodeUnconstrainedInteger(Int64(value))
        }
    }

    // MARK: - String Encoding

    /// Encode an IA5String (ASCII 0-127)
    public mutating func encodeIA5String(_ value: String, constraint: ASN1StringConstraint? = nil) throws {
        let length = value.count

        if let fixed = constraint?.fixedLength {
            // Fixed length — no length encoding
            _ = fixed
        } else if let minLen = constraint?.minLength, let maxLen = constraint?.maxLength {
            try encodeConstrainedInt(length, min: Int64(minLen), max: Int64(maxLen))
        } else {
            try encodeLengthDeterminant(length)
        }

        if let alphabet = constraint?.alphabet {
            let sortedAlphabet = String(alphabet.sorted())
            for ch in value {
                if let idx = sortedAlphabet.firstIndex(of: ch) {
                    let index = sortedAlphabet.distance(from: sortedAlphabet.startIndex, to: idx)
                    try encodeConstrainedInt(index, min: 0, max: Int64(sortedAlphabet.count - 1))
                }
            }
        } else {
            for ch in value {
                let charCode = Int(ch.asciiValue ?? 0)
                try encodeConstrainedInt(charCode, min: 0, max: 127)
            }
        }
    }

    /// Encode a UTF8String
    public mutating func encodeUTF8String(_ value: String, constraint: ASN1StringConstraint? = nil) throws {
        let bytes = Array(value.utf8)

        if let fixed = constraint?.fixedLength {
            // Fixed length — no length encoding
            _ = fixed
        } else {
            try encodeLengthDeterminant(bytes.count)
        }

        for byte in bytes {
            try buffer.putByte(byte)
        }
    }

    /// Encode a VisibleString (printable ASCII 32-126)
    public mutating func encodeVisibleString(_ value: String, constraint: ASN1StringConstraint? = nil) throws {
        let length = value.count

        if let fixed = constraint?.fixedLength {
            _ = fixed
        } else if let minLen = constraint?.minLength, let maxLen = constraint?.maxLength {
            try encodeConstrainedInt(length, min: Int64(minLen), max: Int64(maxLen))
        } else {
            try encodeLengthDeterminant(length)
        }

        if let alphabet = constraint?.alphabet {
            let sortedAlphabet = String(alphabet.sorted())
            for ch in value {
                if let idx = sortedAlphabet.firstIndex(of: ch) {
                    let index = sortedAlphabet.distance(from: sortedAlphabet.startIndex, to: idx)
                    try encodeConstrainedInt(index, min: 0, max: Int64(sortedAlphabet.count - 1))
                }
            }
        } else {
            for ch in value {
                let charCode = Int(ch.asciiValue ?? 0)
                try encodeConstrainedInt(charCode, min: 0, max: 126)
            }
        }
    }

    /// Encode a NumericString (digits 0-9 and space)
    public mutating func encodeNumericString(_ value: String, constraint: ASN1StringConstraint? = nil) throws {
        let numericAlphabet = " 0123456789"
        let length = value.count

        if let fixed = constraint?.fixedLength {
            _ = fixed
        } else if let minLen = constraint?.minLength, let maxLen = constraint?.maxLength {
            try encodeConstrainedInt(length, min: Int64(minLen), max: Int64(maxLen))
        } else {
            try encodeLengthDeterminant(length)
        }

        for ch in value {
            if let idx = numericAlphabet.firstIndex(of: ch) {
                let index = numericAlphabet.distance(from: numericAlphabet.startIndex, to: idx)
                try encodeConstrainedInt(index, min: 0, max: 10)
            }
        }
    }

    // MARK: - Octet String

    /// Encode an OCTET STRING
    public mutating func encodeOctetString(_ value: Data, minSize: Int? = nil, maxSize: Int? = nil) throws {
        let length = value.count

        if let min = minSize, let max = maxSize, min == max {
            // Fixed size — no length encoding
        } else if let min = minSize, let max = maxSize {
            try encodeConstrainedInt(length, min: Int64(min), max: Int64(max))
        } else {
            try encodeLengthDeterminant(length)
        }

        for byte in value {
            try buffer.putByte(byte)
        }
    }

    // MARK: - Bit String

    /// Encode a BIT STRING
    public mutating func encodeBitString(_ value: [Bool], minSize: Int? = nil, maxSize: Int? = nil) throws {
        let length = value.count

        if let min = minSize, let max = maxSize, min == max {
            // Fixed size
        } else if let min = minSize, let max = maxSize {
            try encodeConstrainedInt(length, min: Int64(min), max: Int64(max))
        } else {
            try encodeLengthDeterminant(length)
        }

        for bit in value {
            try buffer.putBit(bit)
        }
    }

    // MARK: - Sequence Of

    /// Encode a SEQUENCE OF count
    public mutating func encodeSequenceOfCount(_ count: Int, constraint: ASN1SequenceOfConstraint = .unconstrained) throws {
        if let min = constraint.minSize, let max = constraint.maxSize, min == max {
            // Fixed size — no count encoding
        } else if let min = constraint.minSize, let max = constraint.maxSize {
            try encodeConstrainedInt(
                count,
                min: Int64(min),
                max: Int64(max),
                hasExtensionMarker: constraint.hasExtensionMarker
            )
        } else {
            try encodeLengthDeterminant(count)
        }
    }

    /// Encode a SEQUENCE OF ASN1Encodable elements
    public mutating func encodeSequenceOf<T: ASN1Encodable>(
        _ elements: [T],
        constraint: ASN1SequenceOfConstraint = .unconstrained
    ) throws {
        try encodeSequenceOfCount(elements.count, constraint: constraint)
        for element in elements {
            try element.encode(to: &self)
        }
    }

    /// Encode a SEQUENCE OF integers
    public mutating func encodeSequenceOfInt(
        _ elements: [Int],
        elementConstraint: ASN1IntegerConstraint,
        sizeConstraint: ASN1SequenceOfConstraint = .unconstrained
    ) throws {
        try encodeSequenceOfCount(elements.count, constraint: sizeConstraint)
        for value in elements {
            try encodeConstrainedInt(value, constraint: elementConstraint)
        }
    }

    // MARK: - Choice

    /// Encode a CHOICE index
    public mutating func encodeChoiceIndex(_ index: Int, rootCount: Int, hasExtensionMarker: Bool = false) throws {
        if hasExtensionMarker {
            if index >= rootCount {
                try buffer.putBit(true)
                try encodeSmallNonNegativeInteger(index - rootCount)
                return
            }
            try buffer.putBit(false)
        }

        if rootCount == 1 {
            return
        }

        try encodeConstrainedInt(index, min: 0, max: Int64(rootCount - 1))
    }

    /// Encode a CHOICE index with descriptor
    public mutating func encodeChoiceIndex(_ index: Int, descriptor: ASN1ChoiceDescriptor) throws {
        try encodeChoiceIndex(index, rootCount: descriptor.rootAlternativeCount, hasExtensionMarker: descriptor.hasExtensionMarker)
    }

    // MARK: - Presence Bitmap

    /// Encode a presence bitmap for optional fields
    public mutating func encodePresenceBitmap(_ bitmap: [Bool]) throws {
        for bit in bitmap {
            try buffer.putBit(bit)
        }
    }

    // MARK: - Object Identifier

    /// Encode an OID string (e.g., "1.2.840.10045.4.3.2") as length + base-128 encoded bytes.
    public mutating func encodeObjectIdentifier(_ oid: String) throws {
        let components = oid.split(separator: ".").compactMap { UInt64($0) }
        guard components.count >= 2 else {
            throw UICBarcodeError.encodingFailed("Invalid OID: \(oid)")
        }

        // Encode to raw bytes
        var rawBytes = [UInt8]()

        // First two components combined: c0 * 40 + c1
        let first = components[0] * 40 + components[1]
        encodeBase128(first, into: &rawBytes)

        for i in 2..<components.count {
            encodeBase128(components[i], into: &rawBytes)
        }

        // Write as length-determinant + raw bytes
        try encodeLengthDeterminant(rawBytes.count)
        for byte in rawBytes {
            try buffer.putByte(byte)
        }
    }

    /// Encode a value using base-128 variable-length encoding
    private func encodeBase128(_ value: UInt64, into bytes: inout [UInt8]) {
        if value < 128 {
            bytes.append(UInt8(value))
            return
        }
        var temp = [UInt8]()
        var v = value
        temp.append(UInt8(v & 0x7F))
        v >>= 7
        while v > 0 {
            temp.append(UInt8(v & 0x7F) | 0x80)
            v >>= 7
        }
        bytes.append(contentsOf: temp.reversed())
    }

    // MARK: - Data Output

    /// Get the encoded data (trimmed to current position)
    public func toData() -> Data {
        let byteCount = (buffer.position + 7) / 8
        let allBytes = buffer.toArray()
        return Data(allBytes.prefix(byteCount))
    }

    /// Get the encoded data as byte array (trimmed to current position)
    public func toArray() -> [UInt8] {
        let byteCount = (buffer.position + 7) / 8
        return Array(buffer.toArray().prefix(byteCount))
    }
}

// MARK: - Generic Encode Method

extension UPEREncoder {
    /// Encode any ASN1Encodable type
    public mutating func encode<T: ASN1Encodable>(_ value: T) throws {
        try value.encode(to: &self)
    }
}
