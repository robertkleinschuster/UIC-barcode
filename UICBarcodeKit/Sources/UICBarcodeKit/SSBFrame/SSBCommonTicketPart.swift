import Foundation

/// Common fields shared by UIC ticket types (118 bits total)
/// Java ref: SsbCommonTicketPart.java
/// Layout: adults(7) + children(7) + specimen(1) + class(6) + ticketNumber(84) + year(4) + day(9)
public struct SSBCommonTicketPart {
    /// Total bit size of the common ticket part
    public static let bitSize = 118

    /// Number of adult passengers (7 bits, 0-99)
    public var numberOfAdults: Int = 0

    /// Number of child passengers (7 bits, 0-99)
    public var numberOfChildren: Int = 0

    /// Specimen flag (1 bit)
    public var specimen: Bool = false

    /// Class of travel (6 bits)
    public var classCode: SSBClass = .none

    /// Ticket number (14 alphanumeric chars = 84 bits)
    public var ticketNumber: String = ""

    /// Year of issue (4 bits, 0-9)
    public var year: Int = 0

    /// Day of issue from January 1st (9 bits, 0-511)
    public var day: Int = 0

    public init() {}

    public init(bitBuffer: BitBuffer, startOffset: Int = 27) throws {
        var offset = startOffset

        numberOfAdults = try bitBuffer.getInteger(at: offset, length: 7)
        offset += 7

        numberOfChildren = try bitBuffer.getInteger(at: offset, length: 7)
        offset += 7

        specimen = try bitBuffer.getBit(at: offset)
        offset += 1

        let classIndex = try bitBuffer.getInteger(at: offset, length: 6)
        classCode = SSBClass(rawValue: classIndex) ?? .none
        offset += 6

        ticketNumber = try bitBuffer.getChar6String(at: offset, length: 84)
        offset += 84

        year = try bitBuffer.getInteger(at: offset, length: 4)
        offset += 4

        day = try bitBuffer.getInteger(at: offset, length: 9)
    }
}

// MARK: - SSBCommonTicketPart Encoding

extension SSBCommonTicketPart {

    /// Encode common fields into the bit buffer (118 bits starting at startOffset).
    /// Layout: adults(7) + children(7) + specimen(1) + class(6) + ticketNumber(84) + year(4) + day(9)
    func encode(to bitBuffer: inout BitBuffer, startOffset: Int = 27) throws {
        var offset = startOffset

        try bitBuffer.putInteger(numberOfAdults, at: offset, length: 7)
        offset += 7

        try bitBuffer.putInteger(numberOfChildren, at: offset, length: 7)
        offset += 7

        try bitBuffer.putBit(specimen, at: offset)
        offset += 1

        try bitBuffer.putInteger(classCode.rawValue, at: offset, length: 6)
        offset += 6

        try bitBuffer.putChar6String(ticketNumber, at: offset, length: 84)
        offset += 84

        try bitBuffer.putInteger(year, at: offset, length: 4)
        offset += 4

        try bitBuffer.putInteger(day, at: offset, length: 9)
    }
}
