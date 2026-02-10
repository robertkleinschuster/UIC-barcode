import Foundation

/// Rail pass ticket (RPT)
/// Java ref: SsbPass.java
public struct SSBPass {
    public var common: SSBCommonTicketPart

    /// Pass sub-type (2 bits): 1=Interrail, 2=Eurail Europe, 3=Eurail Overseas
    public var passSubType: Int = 0

    /// First day of validity from issuing date (9 bits)
    public var firstDayOfValidity: Int = 0

    /// Maximum validity duration / last day of validity (9 bits)
    public var maximumValidityDuration: Int = 0

    /// Number of days of travel allowed (7 bits)
    public var numberOfTravels: Int = 0

    /// Country code 1 (7 bits) - 100 = all countries
    public var country1: Int = 0

    /// Country code 2 (7 bits)
    public var country2: Int = 0

    /// Country code 3 (7 bits)
    public var country3: Int = 0

    /// Country code 4 (7 bits)
    public var country4: Int = 0

    /// Country code 5 (7 bits)
    public var country5: Int = 0

    /// Second page flag (1 bit)
    public var hasSecondPage: Bool = false

    /// Info code (14 bits)
    public var infoCode: Int = 0

    /// Free text (40 chars = 240 bits in 6-bit encoding)
    public var text: String = ""

    public init(bitBuffer: BitBuffer) throws {
        common = try SSBCommonTicketPart(bitBuffer: bitBuffer, startOffset: 27)

        // After header (27) + common part (118) = 145
        var offset = 27 + SSBCommonTicketPart.bitSize

        // Pass sub-type (2 bits)
        passSubType = try bitBuffer.getInteger(at: offset, length: 2)
        offset += 2

        // First day of validity (9 bits)
        firstDayOfValidity = try bitBuffer.getInteger(at: offset, length: 9)
        offset += 9

        // Maximum validity duration (9 bits)
        maximumValidityDuration = try bitBuffer.getInteger(at: offset, length: 9)
        offset += 9

        // Number of travels (7 bits)
        numberOfTravels = try bitBuffer.getInteger(at: offset, length: 7)
        offset += 7

        // Country codes 1-5 (7 bits each)
        country1 = try bitBuffer.getInteger(at: offset, length: 7)
        offset += 7

        country2 = try bitBuffer.getInteger(at: offset, length: 7)
        offset += 7

        country3 = try bitBuffer.getInteger(at: offset, length: 7)
        offset += 7

        country4 = try bitBuffer.getInteger(at: offset, length: 7)
        offset += 7

        country5 = try bitBuffer.getInteger(at: offset, length: 7)
        offset += 7

        // Second page flag (1 bit)
        hasSecondPage = try bitBuffer.getBit(at: offset)
        offset += 1

        // Info code (14 bits)
        infoCode = try bitBuffer.getInteger(at: offset, length: 14)
        offset += 14

        // Text (40 chars = 240 bits, fixed size)
        text = try bitBuffer.getChar6String(at: offset, length: 240)
    }
}

// MARK: - SSBPass Encoding

extension SSBPass {

    /// Encode RPT ticket data into the bit buffer.
    func encode(to bitBuffer: inout BitBuffer) throws {
        // Common part at offset 27
        try common.encode(to: &bitBuffer, startOffset: 27)

        var offset = 27 + SSBCommonTicketPart.bitSize // 145

        // passSubType (2 bits)
        try bitBuffer.putInteger(passSubType, at: offset, length: 2)
        offset += 2

        // firstDayOfValidity (9 bits)
        try bitBuffer.putInteger(firstDayOfValidity, at: offset, length: 9)
        offset += 9

        // maximumValidityDuration (9 bits)
        try bitBuffer.putInteger(maximumValidityDuration, at: offset, length: 9)
        offset += 9

        // numberOfTravels (7 bits)
        try bitBuffer.putInteger(numberOfTravels, at: offset, length: 7)
        offset += 7

        // Country codes 1-5 (7 bits each)
        try bitBuffer.putInteger(country1, at: offset, length: 7)
        offset += 7
        try bitBuffer.putInteger(country2, at: offset, length: 7)
        offset += 7
        try bitBuffer.putInteger(country3, at: offset, length: 7)
        offset += 7
        try bitBuffer.putInteger(country4, at: offset, length: 7)
        offset += 7
        try bitBuffer.putInteger(country5, at: offset, length: 7)
        offset += 7

        // hasSecondPage (1 bit)
        try bitBuffer.putBit(hasSecondPage, at: offset)
        offset += 1

        // infoCode (14 bits)
        try bitBuffer.putInteger(infoCode, at: offset, length: 14)
        offset += 14

        // text (40 chars = 240 bits)
        try bitBuffer.putChar6String(text, at: offset, length: 240)
    }
}
