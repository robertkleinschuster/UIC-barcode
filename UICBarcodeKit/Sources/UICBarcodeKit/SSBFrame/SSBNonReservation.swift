import Foundation

/// Non-reservation ticket (NRT)
/// Java ref: SsbNonReservation.java
public struct SSBNonReservation {
    public var common: SSBCommonTicketPart

    /// Is return journey (1 bit)
    public var isReturnJourney: Bool = false

    /// First day of validity (9 bits)
    public var firstDayOfValidity: Int = 0

    /// Last day of validity (9 bits)
    public var lastDayOfValidity: Int = 0

    /// Station information
    public var stations: SSBStations

    /// Info code (14 bits)
    public var infoCode: Int = 0

    /// Free text (37 chars = 222 bits in 6-bit encoding)
    public var text: String = ""

    public init(bitBuffer: BitBuffer) throws {
        // Common part starts at offset 27
        common = try SSBCommonTicketPart(bitBuffer: bitBuffer, startOffset: 27)

        // After header (27) + common part (118) = 145
        var offset = 27 + SSBCommonTicketPart.bitSize

        isReturnJourney = try bitBuffer.getBit(at: offset)
        offset += 1

        firstDayOfValidity = try bitBuffer.getInteger(at: offset, length: 9)
        offset += 9

        lastDayOfValidity = try bitBuffer.getInteger(at: offset, length: 9)
        offset += 9

        stations = try SSBStations(bitBuffer: bitBuffer, offset: offset)
        offset += stations.decodedBitCount

        infoCode = try bitBuffer.getInteger(at: offset, length: 14)
        offset += 14

        text = try bitBuffer.getChar6String(at: offset, length: 222)
    }
}

// MARK: - SSBNonReservation Encoding

extension SSBNonReservation {

    /// Encode NRT ticket data into the bit buffer.
    /// Layout: header(27) + common(118) + returnJourney(1) + firstDay(9) + lastDay(9)
    ///         + stations(61 or 65) + infoCode(14) + text(222)
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

        // infoCode (14 bits)
        try bitBuffer.putInteger(infoCode, at: offset, length: 14)
        offset += 14

        // text (37 chars = 222 bits)
        try bitBuffer.putChar6String(text, at: offset, length: 222)
    }
}
