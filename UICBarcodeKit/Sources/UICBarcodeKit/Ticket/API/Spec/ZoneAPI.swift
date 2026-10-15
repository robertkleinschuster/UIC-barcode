import Foundation

public struct ZoneAPI {
    public var stationCodeTable: CodeTableType?
    public var zoneId: [Int] = []
    public var carrierNum: Int?
    public var carrierIA5: String?
    public var city: Int?
    public var binaryZoneId: Data?
    public var nutsCode: String?

    public init() {}
}
