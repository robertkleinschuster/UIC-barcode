import Foundation

public struct ReturnRouteDescriptionAPI {
    public var fromStation: String?
    public var toStation: String?
    public var fromStationName: String?
    public var toStationName: String?
    public var validRegionDesc: String?
    public var validRegionList: [RegionalValidityAPI] = []

    public init() {}
}
