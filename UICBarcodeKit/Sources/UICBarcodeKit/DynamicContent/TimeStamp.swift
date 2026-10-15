import Foundation

/// Timestamp for dynamic content - matches Java TimeStamp.java (fdc1 package)
/// @Sequence (no extension marker)
/// Both fields are MANDATORY
public struct TimeStamp: ASN1Decodable {
    /// Day of the year (1..366)
    public var day: Int = 1
    /// Second of the day (0..86399)
    public var secondOfDay: Int = 0

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        // No extension marker, no optional fields
        day = try decoder.decodeConstrainedInt(min: 1, max: 366)
        secondOfDay = try decoder.decodeConstrainedInt(min: 0, max: 86399)
    }
}

// MARK: - TimeStamp Convenience

extension TimeStamp {

    /// Convert to Date, using a reference date to determine the year.
    /// Matches Java TimeStamp.getTimeAsDate() logic:
    /// - If the timestamp day is >250 days ahead of the reference day, assume previous year
    /// - If the timestamp day is >250 days behind the reference day, assume next year
    public func toDate(referenceDate: Date = Date()) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        let refDayOfYear = calendar.ordinality(of: .day, in: .year, for: referenceDate) ?? 1
        var refYear = calendar.component(.year, from: referenceDate)

        // Year boundary logic (matches Java)
        if refDayOfYear - day > 250 {
            refYear += 1
        }
        if day - refDayOfYear > 250 {
            refYear -= 1
        }

        var components = DateComponents()
        components.year = refYear
        components.month = 1
        components.day = 1

        guard let startOfYear = calendar.date(from: components) else { return referenceDate }

        // Add day offset (1-based)
        guard let withDay = calendar.date(byAdding: .day, value: day - 1, to: startOfYear) else { return referenceDate }

        // Add seconds
        guard let result = calendar.date(byAdding: .second, value: secondOfDay, to: withDay) else { return referenceDate }

        return result
    }

    /// Create from a Date (matches Java TimeStamp.setDateTime)
    public init(date: Date) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        self.day = calendar.ordinality(of: .day, in: .year, for: date) ?? 1

        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)
        self.secondOfDay = hour * 3600 + minute * 60 + second
    }

    /// Create a timestamp for the current moment (UTC)
    public static func now() -> TimeStamp {
        TimeStamp(date: Date())
    }
}

// MARK: - TimeStamp Encoding

extension TimeStamp: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        // No extension marker, no optional fields
        try encoder.encodeConstrainedInt(day, min: 1, max: 366)
        try encoder.encodeConstrainedInt(secondOfDay, min: 0, max: 86399)
    }
}
