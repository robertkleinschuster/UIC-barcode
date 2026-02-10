import Foundation

/// Version-independent open ticket
public class OpenTicket {
    public var token: TokenAPI?
    public var reference: String?
    public var productId: String?
    public var productOwner: String?
    public var externalIssuer: Int?
    public var authorizationCode: Int?
    public var returnIncluded: Bool = false
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
    public var activatedDays: [Date] = []
    public var classCode: TravelClassType?
    public var includedCarriers: [String] = []
    public var includedServiceBrands: [Int] = []
    public var excludedServiceBrands: [Int] = []
    public var excludedTransportTypes: [Int] = []
    public var includedTransportTypes: [Int] = []
    public var tariffs: [TariffAPI] = []
    public var includedAddOns: [IncludedOpenTicketAPI] = []
    public var infoText: String?
    public var luggageRestriction: LuggageRestrictionAPI?
    public var extensionData: TicketExtension?
    public var serviceLevel: String?
    public var price: Int?
    public var vatDetails: [VatDetailAPI] = []
    public var validFromUTCoffset: Int?
    public var validUntilUTCoffset: Int?

    public init() {}
}
