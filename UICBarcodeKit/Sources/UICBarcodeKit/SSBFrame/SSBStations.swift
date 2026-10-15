import Foundation

/// SSB Station information
/// Java ref: SsbStations.java
/// Matches Java SsbStations: 1-bit alphaNumeric flag first, then branching
public struct SSBStations {
    /// Whether stations are encoded as alphanumeric strings
    public var alphaNumeric: Bool = true

    /// Station code table type (4 bits, only present when numeric)
    public var codeTable: SSBStationCodeTable = .unknown0

    /// Departure station code (alphanumeric, 30 bits / 5 chars)
    public var departureStationCode: String = ""

    /// Arrival station code (alphanumeric, 30 bits / 5 chars)
    public var arrivalStationCode: String = ""

    /// Departure station number (numeric, 28 bits)
    public var departureStationNum: Int = 0

    /// Arrival station number (numeric, 28 bits)
    public var arrivalStationNum: Int = 0

    /// Total number of bits consumed by station decoding
    public private(set) var decodedBitCount: Int = 0

    public init() {}

    /// Decode station data from bit buffer starting at the given offset.
    /// Returns the number of bits consumed.
    public init(bitBuffer: BitBuffer, offset: Int) throws {
        var pos = offset

        // Read 1-bit alphanumeric flag FIRST (matches Java SsbStations.decode)
        alphaNumeric = try bitBuffer.getBit(at: pos)
        pos += 1

        if alphaNumeric {
            // Alphanumeric mode: no code table, read 30+30 bit char6 strings
            codeTable = .unknown0
            departureStationCode = try bitBuffer.getChar6String(at: pos, length: 30)
            departureStationNum = try bitBuffer.getInteger(at: pos, length: 30)
            pos += 30
            arrivalStationCode = try bitBuffer.getChar6String(at: pos, length: 30)
            arrivalStationNum = try bitBuffer.getInteger(at: pos, length: 30)
            pos += 30
        } else {
            // Numeric mode: read 4-bit code table + 28+28 bit station numbers
            let codeTableValue = try bitBuffer.getInteger(at: pos, length: 4)
            codeTable = SSBStationCodeTable(rawValue: codeTableValue) ?? .unknown0
            pos += 4
            departureStationNum = try bitBuffer.getInteger(at: pos, length: 28)
            departureStationCode = String(departureStationNum)
            pos += 28
            arrivalStationNum = try bitBuffer.getInteger(at: pos, length: 28)
            arrivalStationCode = String(arrivalStationNum)
            pos += 28
        }

        decodedBitCount = pos - offset
    }
}

// MARK: - SSBStations Encoding

extension SSBStations {

    /// Encode station data into the bit buffer starting at the given offset.
    /// Returns the number of bits written.
    @discardableResult
    func encode(to bitBuffer: inout BitBuffer, offset: Int) throws -> Int {
        var pos = offset

        // 1-bit alphanumeric flag
        try bitBuffer.putBit(alphaNumeric, at: pos)
        pos += 1

        if alphaNumeric {
            // Alphanumeric: 30+30 bit char6 strings (no code table)
            try bitBuffer.putChar6String(departureStationCode, at: pos, length: 30)
            pos += 30
            try bitBuffer.putChar6String(arrivalStationCode, at: pos, length: 30)
            pos += 30
        } else {
            // Numeric: 4-bit code table + 28+28 bit station numbers
            try bitBuffer.putInteger(codeTable.rawValue, at: pos, length: 4)
            pos += 4
            try bitBuffer.putInteger(departureStationNum, at: pos, length: 28)
            pos += 28
            try bitBuffer.putInteger(arrivalStationNum, at: pos, length: 28)
            pos += 28
        }

        return pos - offset
    }

    /// The number of bits this station encoding will produce.
    var encodedBitCount: Int {
        if alphaNumeric {
            return 1 + 30 + 30 // flag + departure + arrival
        } else {
            return 1 + 4 + 28 + 28 // flag + codeTable + departure + arrival
        }
    }
}
