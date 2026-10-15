import Foundation

public struct ViaStationAPI {
    public var stationCodeTable: CodeTableType?
    public var stationNum: Int?
    public var stationIA5: String?
    public var stationNameUTF8: String?
    public var carriersNum: [Int] = []
    public var carriersIA5: [String] = []
    public var route: [ViaStationAPI] = []
    public var border: Bool = false
    public var alternativeRoutes: [[ViaStationAPI]] = []
    public var seriesId: Int?
    public var routeId: Int?

    public init() {}
}
