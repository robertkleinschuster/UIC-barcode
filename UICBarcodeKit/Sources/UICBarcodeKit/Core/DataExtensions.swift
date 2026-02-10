import Foundation

// MARK: - Data Extensions

public extension Data {
    /// Initialize from hex string
    init?(hexString: String) {
        let hex = hexString.replacingOccurrences(of: " ", with: "")
        guard hex.count % 2 == 0 else { return nil }

        var data = Data(capacity: hex.count / 2)
        var index = hex.startIndex

        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index..<nextIndex], radix: 16) else {
                return nil
            }
            data.append(byte)
            index = nextIndex
        }

        self = data
    }

    /// Convert to hex string
    func toHexString(separator: String = "") -> String {
        return map { String(format: "%02x", $0) }.joined(separator: separator)
    }

    /// Convert to binary string
    func toBinaryString(separator: String = " ") -> String {
        return map { byte in
            var result = ""
            for i in (0..<8).reversed() {
                result += (byte & (1 << i)) != 0 ? "1" : "0"
            }
            return result
        }.joined(separator: separator)
    }

    /// Read UInt8 at offset
    func readUInt8(at offset: Int) -> UInt8? {
        guard offset < count else { return nil }
        return self[offset]
    }

    /// Read UInt16 (big endian) at offset
    func readUInt16BE(at offset: Int) -> UInt16? {
        guard offset + 1 < count else { return nil }
        return UInt16(self[offset]) << 8 | UInt16(self[offset + 1])
    }

    /// Read UInt32 (big endian) at offset
    func readUInt32BE(at offset: Int) -> UInt32? {
        guard offset + 3 < count else { return nil }
        return UInt32(self[offset]) << 24 |
               UInt32(self[offset + 1]) << 16 |
               UInt32(self[offset + 2]) << 8 |
               UInt32(self[offset + 3])
    }

    /// Read ASCII string at offset with length
    func readASCIIString(at offset: Int, length: Int) -> String? {
        guard offset + length <= count else { return nil }
        let subdata = self[offset..<(offset + length)]
        return String(data: subdata, encoding: .ascii)
    }

    /// Read UTF-8 string at offset with length
    func readUTF8String(at offset: Int, length: Int) -> String? {
        guard offset + length <= count else { return nil }
        let subdata = self[offset..<(offset + length)]
        return String(data: subdata, encoding: .utf8)
    }

    /// Slice data
    func slice(from: Int, length: Int) -> Data? {
        guard from >= 0, from + length <= count else { return nil }
        return self[from..<(from + length)]
    }

    /// Slice data from offset to end
    func slice(from: Int) -> Data? {
        guard from >= 0, from < count else { return nil }
        return self[from...]
    }
}

// MARK: - Array<UInt8> Extensions

public extension Array where Element == UInt8 {
    /// Initialize from hex string
    init?(hexString: String) {
        guard let data = Data(hexString: hexString) else { return nil }
        self = Array(data)
    }

    /// Convert to hex string
    func toHexString(separator: String = "") -> String {
        return Data(self).toHexString(separator: separator)
    }

    /// Convert to Data
    func toData() -> Data {
        return Data(self)
    }
}

// MARK: - String Extensions

public extension String {
    /// Initialize from integer with leading zeros
    init(int: Int, minDigits: Int) {
        self = String(format: "%0\(minDigits)d", int)
    }

    /// Parse as integer, returning nil if invalid
    func toInt() -> Int? {
        return Int(self)
    }

    /// Convert hex string to Data
    func hexToData() -> Data? {
        return Data(hexString: self)
    }

    /// Trim whitespace and newlines
    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Integer Extensions

public extension FixedWidthInteger {
    /// Number of bits required to represent the value
    var bitWidth: Int {
        guard self > 0 else { return 1 }
        return Self.bitWidth - self.leadingZeroBitCount
    }
}

// MARK: - Date Extensions

public extension Date {
    /// Days since a reference date (used in UIC date calculations)
    func daysSince(_ referenceDate: Date) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.day], from: referenceDate, to: self)
        return components.day ?? 0
    }

    /// Create date from days since reference date
    static func fromDays(_ days: Int, since referenceDate: Date) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        return calendar.date(byAdding: .day, value: days, to: referenceDate) ?? referenceDate
    }

    /// Minutes since midnight
    var minutesSinceMidnight: Int {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.hour, .minute], from: self)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    /// Create date from minutes since midnight on a given date
    static func fromMinutes(_ minutes: Int, on date: Date) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = minutes / 60
        components.minute = minutes % 60
        return calendar.date(from: components) ?? date
    }
}

// MARK: - BigInteger-like Operations

/// Simple big integer operations needed for UPER encoding
public struct BigIntOperations {
    /// Calculate the number of bits needed to represent a range
    public static func bitsNeeded(for range: UInt64) -> Int {
        guard range > 0 else { return 0 }
        var n = range
        var bits = 0
        while n > 0 {
            bits += 1
            n >>= 1
        }
        return bits
    }

    /// Calculate the number of bits needed for (range - 1)
    public static func bitsNeededForRange(min: Int64, max: Int64) -> Int {
        let range = UInt64(max - min)
        return bitsNeeded(for: range)
    }
}
