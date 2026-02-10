import Foundation

public struct ValidityDetailsAPI {
    public var validityPeriods: [ValidityPeriodAPI] = []
    public var excludedTimeRanges: [TimeRangeAPI] = []

    public init() {}
}
