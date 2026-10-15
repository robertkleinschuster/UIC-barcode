import Foundation

/// Version-independent station passage
public class StationPassageAPI {
    public var token: TokenAPI?
    public var reference: String?
    public var productId: String?
    public var productOwner: String?
    public var stationCodeTable: CodeTableType?
    public var stationNameUTF8: [String] = []
    public var stationNum: [Int] = []
    public var stationIA5: [String] = []
    public var validFrom: Date?
    public var validUntil: Date?
    public var numberOfDaysValid: Int = 0
    public var infoText: String?
    public var extensionData: TicketExtension?

    public init() {}
}
