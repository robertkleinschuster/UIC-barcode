import Foundation

/// Version-independent counter mark
public class CounterMarkAPI {
    public var token: TokenAPI?
    public var reference: String?
    public var productId: String?
    public var productOwner: String?
    public var stationCodeTable: CodeTableType?
    public var fromStation: String?
    public var toStation: String?
    public var fromStationName: String?
    public var toStationName: String?
    public var validRegionDesc: String?
    public var validRegionList: [RegionalValidityAPI] = []
    public var returnDescription: ReturnRouteDescriptionAPI?
    public var validFrom: Date?
    public var validUntil: Date?
    public var classCode: TravelClassType?
    public var carriers: [String] = []
    public var includedServiceBrands: [Int] = []
    public var excludedServiceBrands: [Int] = []
    public var infoText: String?
    public var extensionData: TicketExtension?
    public var numberOfCountermark: Int = 0
    public var totalOfCountermarks: Int = 0
    public var groupName: String?

    public init() {}
}
