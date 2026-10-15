import Foundation

public struct LineAPI {
    public var stationCodeTable: CodeTableType?
    public var lineId: [Int] = []
    public var carrierNum: Int?
    public var carrierIA5: String?

    public init() {}
}
