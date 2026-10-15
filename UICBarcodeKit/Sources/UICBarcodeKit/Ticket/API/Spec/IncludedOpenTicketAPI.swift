import Foundation

public struct IncludedOpenTicketAPI {
    public var productOwnerNum: Int?
    public var productOwnerIA5: String?
    public var productIdNum: Int?
    public var productIdIA5: String?
    public var externalIssuerId: Int?
    public var authorizationCode: Int?
    public var stationCodeTable: CodeTableType?
    public var validRegionList: [RegionalValidityAPI] = []
    public var validFrom: Date?
    public var validUntil: Date?
    public var classCode: TravelClassType?
    public var serviceLevel: String?
    public var includedCarriers: [String] = []
    public var includedServiceBrands: [Int] = []
    public var excludedServiceBrands: [Int] = []
    public var tariffs: [TariffAPI] = []
    public var infoText: String?
    public var extensionData: TicketExtension?
    public var includedTransportTypes: [Int] = []
    public var excludedTransportTypes: [Int] = []

    public init() {}
}
