import Foundation

/// A buffer for reading and writing individual bits from/to a byte array.
/// This is essential for ASN.1 UPER decoding which operates at the bit level.
public struct BitBuffer {
    /// Bit masks for accessing individual bits within a byte
    private static let masks: [UInt8] = [
        0b1000_0000,
        0b0100_0000,
        0b0010_0000,
        0b0001_0000,
        0b0000_1000,
        0b0000_0100,
        0b0000_0010,
        0b0000_0001
    ]

    /// The underlying byte data
    private var bytes: [UInt8]

    /// Current bit position (0-indexed)
    private(set) public var position: Int = 0

    /// Total number of bits available
    public private(set) var limit: Int

    /// Number of remaining bits that can be read
    public var remaining: Int {
        return limit - position
    }

    // MARK: - Initialization

    /// Initialize with raw byte data
    public init(data: Data) {
        self.bytes = Array(data)
        self.limit = bytes.count * 8
    }

    /// Initialize with byte array
    public init(bytes: [UInt8]) {
        self.bytes = bytes
        self.limit = bytes.count * 8
    }

    /// Allocate a buffer with the specified number of bits
    public static func allocate(bits: Int) -> BitBuffer {
        let byteCount = (bits + 7) / 8
        return BitBuffer(bytes: [UInt8](repeating: 0, count: byteCount))
    }

    /// Double the buffer capacity, preserving existing content.
    private mutating func grow() {
        let newByteCount = max(bytes.count * 2, 256)
        bytes.append(contentsOf: [UInt8](repeating: 0, count: newByteCount - bytes.count))
        limit = newByteCount * 8
    }

    // MARK: - Reading

    /// Read a single bit and advance position
    public mutating func getBit() throws -> Bool {
        guard position < limit else {
            throw UICBarcodeError.bufferUnderflow(needed: 1, available: remaining)
        }
        let byteIndex = position / 8
        let bitIndex = position % 8
        let result = (bytes[byteIndex] & Self.masks[bitIndex]) != 0
        position += 1
        return result
    }

    /// Read multiple bits as a UInt64 and advance position
    /// - Parameter count: Number of bits to read (max 64)
    public mutating func getBits(_ count: Int) throws -> UInt64 {
        guard count <= 64 else {
            throw UICBarcodeError.invalidData("Cannot read more than 64 bits at once")
        }
        guard count <= remaining else {
            throw UICBarcodeError.bufferUnderflow(needed: count, available: remaining)
        }

        var result: UInt64 = 0
        for _ in 0..<count {
            result = (result << 1) | (try getBit() ? 1 : 0)
        }
        return result
    }

    /// Read multiple bits as an Int64 and advance position
    public mutating func getSignedBits(_ count: Int) throws -> Int64 {
        let unsigned = try getBits(count)
        // Sign extend if needed
        if count < 64 && (unsigned & (1 << (count - 1))) != 0 {
            // Negative number - sign extend
            let signExtension = ~((1 << count) - 1)
            return Int64(bitPattern: unsigned | UInt64(bitPattern: Int64(signExtension)))
        }
        return Int64(unsigned)
    }

    /// Read a specified number of complete bytes
    public mutating func getBytes(_ count: Int) throws -> Data {
        guard count * 8 <= remaining else {
            throw UICBarcodeError.bufferUnderflow(needed: count * 8, available: remaining)
        }

        var result = Data(capacity: count)
        for _ in 0..<count {
            result.append(try getByte())
        }
        return result
    }

    /// Read a single byte
    public mutating func getByte() throws -> UInt8 {
        guard remaining >= 8 else {
            throw UICBarcodeError.bufferUnderflow(needed: 8, available: remaining)
        }

        var result: UInt8 = 0
        for i in 0..<8 {
            if try getBit() {
                result |= Self.masks[i]
            }
        }
        return result
    }

    /// Get bit at specific index without advancing position
    public func getBit(at index: Int) throws -> Bool {
        guard index >= 0 && index < limit else {
            throw UICBarcodeError.invalidBitPosition(index)
        }
        let byteIndex = index / 8
        let bitIndex = index % 8
        return (bytes[byteIndex] & Self.masks[bitIndex]) != 0
    }

    /// Read an integer value from specific position (for SSB fixed-position reading)
    public func getInteger(at position: Int, length: Int) throws -> Int {
        guard position >= 0 && position + length <= limit else {
            throw UICBarcodeError.bufferUnderflow(needed: length, available: limit - position)
        }

        var result = 0
        for i in 0..<length {
            let byteIndex = (position + i) / 8
            let bitIndex = (position + i) % 8
            if (bytes[byteIndex] & Self.masks[bitIndex]) != 0 {
                result |= (1 << (length - 1 - i))
            }
        }
        return result
    }

    /// Read a 6-bit character string (SSB format)
    public func getChar6String(at position: Int, length: Int) throws -> String {
        let charCount = length / 6
        var result = ""

        for i in 0..<charCount {
            let charPosition = position + i * 6
            let value = try getInteger(at: charPosition, length: 6)
            let scalar = UnicodeScalar(value + 32)!
            result.append(Character(scalar))
        }

        return result.trimmingCharacters(in: .whitespaces)
    }

    /// Read a 5-bit character string (SSB format)
    public func getChar5String(at position: Int, length: Int) throws -> String {
        let charCount = length / 5
        var result = ""

        for i in 0..<charCount {
            let charPosition = position + i * 5
            let value = try getInteger(at: charPosition, length: 5)
            let scalar = UnicodeScalar(value + 42)!
            result.append(Character(scalar))
        }

        return result.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Writing

    /// Set a bit at the current position and advance
    public mutating func putBit(_ value: Bool) throws {
        if position >= limit {
            grow()
        }
        let byteIndex = position / 8
        let bitIndex = position % 8
        if value {
            bytes[byteIndex] |= Self.masks[bitIndex]
        } else {
            bytes[byteIndex] &= ~Self.masks[bitIndex]
        }
        position += 1
    }

    /// Set a bit at a specific index
    public mutating func putBit(_ value: Bool, at index: Int) throws {
        guard index >= 0 && index < limit else {
            throw UICBarcodeError.invalidBitPosition(index)
        }
        let byteIndex = index / 8
        let bitIndex = index % 8
        if value {
            bytes[byteIndex] |= Self.masks[bitIndex]
        } else {
            bytes[byteIndex] &= ~Self.masks[bitIndex]
        }
    }

    /// Write multiple bits from a UInt64
    public mutating func putBits(_ value: UInt64, count: Int) throws {
        guard count <= 64 else {
            throw UICBarcodeError.invalidData("Cannot write more than 64 bits at once")
        }
        for i in (0..<count).reversed() {
            try putBit((value & (1 << i)) != 0)
        }
    }

    /// Write a byte
    public mutating func putByte(_ value: UInt8) throws {
        for i in 0..<8 {
            try putBit((value & Self.masks[i]) != 0)
        }
    }

    /// Write an integer value at a specific bit position (for SSB fixed-position writing)
    public mutating func putInteger(_ value: Int, at position: Int, length: Int) throws {
        guard position >= 0 && position + length <= limit else {
            throw UICBarcodeError.bufferOverflow("Cannot write \(length) bits at position \(position)")
        }
        for i in 0..<length {
            let bitValue = (value >> (length - 1 - i)) & 1
            try putBit(bitValue != 0, at: position + i)
        }
    }

    /// Write a 6-bit character string at a specific position (SSB format)
    public mutating func putChar6String(_ string: String, at position: Int, length: Int) throws {
        let charCount = length / 6
        let padded = string.padding(toLength: charCount, withPad: " ", startingAt: 0)
        for (i, char) in padded.enumerated() {
            let value = Int(char.asciiValue ?? 32) - 32
            try putInteger(value, at: position + i * 6, length: 6)
        }
    }

    // MARK: - Position Management

    /// Skip a specified number of bits
    public mutating func skip(_ bits: Int) throws {
        guard position + bits <= limit else {
            throw UICBarcodeError.bufferUnderflow(needed: bits, available: remaining)
        }
        position += bits
    }

    /// Reset position to the beginning
    public mutating func rewind() {
        position = 0
    }

    /// Set position to a specific bit
    public mutating func seek(to newPosition: Int) throws {
        guard newPosition >= 0 && newPosition <= limit else {
            throw UICBarcodeError.invalidBitPosition(newPosition)
        }
        position = newPosition
    }

    /// Align position to the next byte boundary
    public mutating func alignToByte() {
        let remainder = position % 8
        if remainder != 0 {
            position += (8 - remainder)
        }
    }

    // MARK: - Data Access

    /// Get the underlying byte array
    public func toArray() -> [UInt8] {
        return bytes
    }

    /// Get the underlying data
    public func toData() -> Data {
        return Data(bytes)
    }

    /// Get remaining bytes from current position (byte-aligned)
    public mutating func getRemainingBytes() throws -> Data {
        alignToByte()
        let remainingByteCount = (limit - position) / 8
        return try getBytes(remainingByteCount)
    }

    /// Extract raw bytes covering the bit range [startBit, endBit).
    /// The returned Data contains the underlying bytes that span this bit range,
    /// starting from the byte containing startBit through the byte containing (endBit-1).
    /// This is useful for capturing encoded data for signature verification.
    public func extractBytes(startBit: Int, endBit: Int) -> Data {
        guard endBit > startBit else { return Data() }
        let startByte = startBit / 8
        let endByte = (endBit + 7) / 8
        guard startByte < bytes.count else { return Data() }
        let clampedEnd = min(endByte, bytes.count)
        return Data(bytes[startByte..<clampedEnd])
    }

    // MARK: - Debug

    /// Get a binary string representation for debugging
    public func toBinaryString() -> String {
        return bytes.map { byte in
            String(byte, radix: 2).leftPadded(toLength: 8, withPad: "0")
        }.joined(separator: " ")
    }

    /// Get a binary string from position for debugging
    public func toBinaryString(from startIndex: Int, length: Int) -> String {
        var result = ""
        for i in startIndex..<min(startIndex + length, limit) {
            let byteIndex = i / 8
            let bitIndex = i % 8
            result += (bytes[byteIndex] & Self.masks[bitIndex]) != 0 ? "1" : "0"
        }
        return result
    }
}

// MARK: - String Extension for Padding

private extension String {
    func leftPadded(toLength length: Int, withPad pad: String) -> String {
        guard count < length else { return self }
        return String(repeating: pad, count: length - count) + self
    }
}
