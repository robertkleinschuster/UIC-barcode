import Foundation

/// Reservation ticket (IRT/RES/BOA)
/// Java ref: SsbReservation.java
public struct SSBReservation {
    public var common: SSBCommonTicketPart

    /// Ticket sub-type (2 bits)
    public var ticketSubType: Int = 0

    /// Station information
    public var stations: SSBStations

    /// Departure date offset (9 bits)
    public var departureDateOffset: Int = 0

    /// Departure time (11 bits, minutes from midnight)
    public var departureTime: Int = 0

    /// Train identifier (5 chars = 30 bits in 6-bit encoding)
    public var train: String = ""

    /// Coach number (10 bits)
    public var coachNumber: Int = 0

    /// Place/seat number (3 chars = 18 bits in 6-bit encoding)
    public var place: String = ""

    /// Overbooking indicator (1 bit)
    public var overbooking: Bool = false

    /// Info code (14 bits)
    public var infoCode: Int = 0

    /// Free text (27 chars = 162 bits in 6-bit encoding)
    public var text: String = ""

    public init(bitBuffer: BitBuffer) throws {
        common = try SSBCommonTicketPart(bitBuffer: bitBuffer, startOffset: 27)

        // After header (27) + common part (118) = 145
        var offset = 27 + SSBCommonTicketPart.bitSize

        // Ticket sub-type (2 bits) - decoded first after common part
        ticketSubType = try bitBuffer.getInteger(at: offset, length: 2)
        offset += 2

        // Stations
        stations = try SSBStations(bitBuffer: bitBuffer, offset: offset)
        offset += stations.decodedBitCount

        // Departure date (9 bits)
        departureDateOffset = try bitBuffer.getInteger(at: offset, length: 9)
        offset += 9

        // Departure time (11 bits)
        departureTime = try bitBuffer.getInteger(at: offset, length: 11)
        offset += 11

        // Train (5 chars = 30 bits)
        train = try bitBuffer.getChar6String(at: offset, length: 30)
        offset += 30

        // Coach (10 bits)
        coachNumber = try bitBuffer.getInteger(at: offset, length: 10)
        offset += 10

        // Place (3 chars = 18 bits)
        place = try bitBuffer.getChar6String(at: offset, length: 18)
        offset += 18

        // Overbooking (1 bit)
        overbooking = try bitBuffer.getBit(at: offset)
        offset += 1

        // Info code (14 bits)
        infoCode = try bitBuffer.getInteger(at: offset, length: 14)
        offset += 14

        // Text (27 chars = 162 bits, fixed size)
        text = try bitBuffer.getChar6String(at: offset, length: 162)
    }
}

// MARK: - SSBReservation Encoding

extension SSBReservation {

    /// Encode IRT/RES/BOA ticket data into the bit buffer.
    func encode(to bitBuffer: inout BitBuffer) throws {
        // Common part at offset 27
        try common.encode(to: &bitBuffer, startOffset: 27)

        var offset = 27 + SSBCommonTicketPart.bitSize // 145

        // ticketSubType (2 bits)
        try bitBuffer.putInteger(ticketSubType, at: offset, length: 2)
        offset += 2

        // Stations
        let stationBits = try stations.encode(to: &bitBuffer, offset: offset)
        offset += stationBits

        // departureDateOffset (9 bits)
        try bitBuffer.putInteger(departureDateOffset, at: offset, length: 9)
        offset += 9

        // departureTime (11 bits)
        try bitBuffer.putInteger(departureTime, at: offset, length: 11)
        offset += 11

        // train (5 chars = 30 bits)
        try bitBuffer.putChar6String(train, at: offset, length: 30)
        offset += 30

        // coachNumber (10 bits)
        try bitBuffer.putInteger(coachNumber, at: offset, length: 10)
        offset += 10

        // place (3 chars = 18 bits)
        try bitBuffer.putChar6String(place, at: offset, length: 18)
        offset += 18

        // overbooking (1 bit)
        try bitBuffer.putBit(overbooking, at: offset)
        offset += 1

        // infoCode (14 bits)
        try bitBuffer.putInteger(infoCode, at: offset, length: 14)
        offset += 14

        // text (27 chars = 162 bits)
        try bitBuffer.putChar6String(text, at: offset, length: 162)
    }
}
