import Foundation

/// Date/time utilities for UIC barcode day-offset arithmetic.
/// Mirrors the Java DateTimeUtils class.
public enum DateTimeUtils {

    /// Calculate the number of days between two dates (UTC, ignoring time).
    /// Returns nil if either date is nil.
    public static func getDateDifference(_ referenceDate: Date?, _ targetDate: Date?) -> Int? {
        guard let referenceDate, let targetDate else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let startOfRef = calendar.startOfDay(for: referenceDate)
        let startOfTarget = calendar.startOfDay(for: targetDate)
        let components = calendar.dateComponents([.day], from: startOfRef, to: startOfTarget)
        return components.day
    }

    /// Calculate the number of days between two dates using local time zone.
    public static func getDateDifferenceLocal(_ referenceDate: Date?, _ targetDate: Date?) -> Int? {
        guard let referenceDate, let targetDate else { return nil }
        let calendar = Calendar(identifier: .gregorian)
        let startOfRef = calendar.startOfDay(for: referenceDate)
        let startOfTarget = calendar.startOfDay(for: targetDate)
        let components = calendar.dateComponents([.day], from: startOfRef, to: startOfTarget)
        return components.day
    }

    /// Create a date from a reference date plus a day offset and optional time (minutes since midnight).
    public static func getLocalDateFromDifference(_ referenceDate: Date?, dayOffset: Int, time: Int? = nil) -> Date? {
        guard let referenceDate else { return nil }
        let calendar = Calendar(identifier: .gregorian)
        guard var result = calendar.date(byAdding: .day, value: dayOffset, to: referenceDate) else { return nil }
        if let time {
            let hours = time / 60
            let minutes = time % 60
            var components = calendar.dateComponents([.year, .month, .day], from: result)
            components.hour = hours
            components.minute = minutes
            result = calendar.date(from: components) ?? result
        }
        return result
    }

    /// Get time as minutes since midnight from a Date (UTC).
    public static func getTime(_ date: Date?) -> Int? {
        guard let date else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = calendar.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour, let minute = components.minute else { return nil }
        return hour * 60 + minute
    }

    /// Create a date from reference date + day offset + time (minutes) using UTC calendar.
    public static func getDate(issuingDate: Date?, dayOffset: Int?, time: Int?) -> Date? {
        guard let issuingDate else { return nil }
        let offset = dayOffset ?? 0
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        guard let dayDate = calendar.date(byAdding: .day, value: offset, to: issuingDate) else { return nil }
        let minutes = time ?? 0
        let hours = minutes / 60
        let mins = minutes % 60
        var components = calendar.dateComponents([.year, .month, .day], from: dayDate)
        components.hour = hours
        components.minute = mins
        return calendar.date(from: components)
    }

    /// Get UTC offset in multiples of 15 minutes.
    /// The offset needs to be added to local time to get UTC time (UTC = local + offset).
    public static func getUTCOffset(_ localDate: Date) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let rawOffset = calendar.timeZone.secondsFromGMT(for: localDate)
        return -(rawOffset / (60 * 15))
    }

    /// Create a UTC date from reference date + day offset + time + UTC offset.
    public static func getUTCDate(issuingDate: Date?, dayOffset: Int?, time: Int?, utcOffset: Int?) -> Date? {
        guard let issuingDate, let utcOffset, let time else { return nil }
        let offset = dayOffset ?? 0
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        guard let dayDate = calendar.date(byAdding: .day, value: offset, to: issuingDate) else { return nil }
        let hours = time / 60
        let minutes = time % 60
        var components = calendar.dateComponents([.year, .month, .day], from: dayDate)
        components.hour = hours
        components.minute = minutes
        guard let localDate = calendar.date(from: components) else { return nil }
        return calendar.date(byAdding: .minute, value: utcOffset * 15, to: localDate)
    }

    /// Convert a collection of dates to day-offset values relative to a reference date.
    public static func getActivatedDays(referenceDate: Date?, dates: [Date]) -> [Int] {
        guard let referenceDate else { return [] }
        return dates.compactMap { getDateDifference(referenceDate, $0) }
    }

    /// Convert local date to UTC by subtracting the time zone offset.
    public static func dateToUTC(_ date: Date) -> Date {
        let offset = TimeZone.current.secondsFromGMT(for: date)
        return date.addingTimeInterval(TimeInterval(-offset))
    }
}
