import Foundation

public struct TrainLinkAPI {
    public var trainNum: Int?
    public var trainIA5: String?
    public var departureDate: Date?
    public var departureTime: Int?
    public var stationCodeTable: CodeTableType?
    public var fromStation: String?
    public var toStation: String?
    public var fromStationName: String?
    public var toStationName: String?

    public init() {}
}
