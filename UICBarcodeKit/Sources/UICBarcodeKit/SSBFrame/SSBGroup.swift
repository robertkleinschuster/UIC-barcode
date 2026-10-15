import Foundation

/// Group ticket (GRP)
/// Java ref: SsbGroup.java
public struct SSBGroup {
    public var common: SSBCommonTicketPart

    /// Is return journey (1 bit)
    public var isReturnJourney: Bool = false

    /// First day of validity (9 bits)
    public var firstDayOfValidity: Int = 0

    /// Last day of validity (9 bits)
    public var lastDayOfValidity: Int = 0

    /// Station information
    public var stations: SSBStations

    /// Group name (12 chars = 72 bits in 6-bit encoding)
    public var groupName: String = ""

    /// Counter mark number (9 bits)
    public var counterMarkNumber: Int = 0

    /// Info code (14 bits)
    public var infoCode: Int = 0

    /// Free text (24 chars = 144 bits in 6-bit encoding)
    public var text: String = ""

    public init(bitBuffer: BitBuffer) throws {
        common = try SSBCommonTicketPart(bitBuffer: bitBuffer, startOffset: 27)

        // After header (27) + common part (118) = 145
        var offset = 27 + SSBCommonTicketPart.bitSize

        // Return journey flag (1 bit)
        isReturnJourney = try bitBuffer.getBit(at: offset)
        offset += 1

        // First day of validity (9 bits)
        firstDayOfValidity = try bitBuffer.getInteger(at: offset, length: 9)
        offset += 9

        // Last day of validity (9 bits)
        lastDayOfValidity = try bitBuffer.getInteger(at: offset, length: 9)
        offset += 9

        // Stations
        stations = try SSBStations(bitBuffer: bitBuffer, offset: offset)
        offset += stations.decodedBitCount

        // Group name (12 chars = 72 bits)
        groupName = try bitBuffer.getChar6String(at: offset, length: 72)
        offset += 72

        // Counter mark number (9 bits)
        counterMarkNumber = try bitBuffer.getInteger(at: offset, length: 9)
        offset += 9

        // Info code (14 bits)
        infoCode = try bitBuffer.getInteger(at: offset, length: 14)
        offset += 14

        // Text (24 chars = 144 bits, fixed size)
        text = try bitBuffer.getChar6String(at: offset, length: 144)
    }
}

// MARK: - SSBGroup Encoding

extension SSBGroup {

    /// Encode GRP ticket data into the bit buffer.
    func encode(to bitBuffer: inout BitBuffer) throws {
        // Common part at offset 27
        try common.encode(to: &bitBuffer, startOffset: 27)

        var offset = 27 + SSBCommonTicketPart.bitSize // 145

        // isReturnJourney (1 bit)
        try bitBuffer.putBit(isReturnJourney, at: offset)
        offset += 1

        // firstDayOfValidity (9 bits)
        try bitBuffer.putInteger(firstDayOfValidity, at: offset, length: 9)
        offset += 9

        // lastDayOfValidity (9 bits)
        try bitBuffer.putInteger(lastDayOfValidity, at: offset, length: 9)
        offset += 9

        // Stations
        let stationBits = try stations.encode(to: &bitBuffer, offset: offset)
        offset += stationBits

        // groupName (12 chars = 72 bits)
        try bitBuffer.putChar6String(groupName, at: offset, length: 72)
        offset += 72

        // counterMarkNumber (9 bits)
        try bitBuffer.putInteger(counterMarkNumber, at: offset, length: 9)
        offset += 9

        // infoCode (14 bits)
        try bitBuffer.putInteger(infoCode, at: offset, length: 14)
        offset += 14

        // text (24 chars = 144 bits)
        try bitBuffer.putChar6String(text, at: offset, length: 144)
    }
}
