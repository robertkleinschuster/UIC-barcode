import Foundation

/// Version-independent rail pass
public class Pass {
    public var token: TokenAPI?
    public var reference: String?
    public var productId: String?
    public var productOwner: String?
    public var passType: Int = 0
    public var passDescription: String?
    public var classCode: TravelClassType?
    public var validFrom: Date?
    public var validUntil: Date?
    public var numberOfValidityDays: Int = 0
    public var numberOfPossibleTrips: Int = 0
    public var numberOfDaysOfTravel: Int = 0
    public var activatedDays: [Date] = []
    public var countries: [Int] = []
    public var includedCarriers: [String] = []
    public var excludedCarriers: [String] = []
    public var includedServiceBrands: [Int] = []
    public var excludedServiceBrands: [Int] = []
    public var validRegionList: [RegionalValidityAPI] = []
    public var tariffs: [TariffAPI] = []
    public var infoText: String?
    public var extensionData: TicketExtension?
    public var validityDetails: ValidityDetailsAPI?
    public var price: Int?
    public var vatDetails: [VatDetailAPI] = []
    public var validFromUTCoffset: Int?
    public var validUntilUTCoffset: Int?
    public var trainValidity: TrainValidityAPI?

    public init() {}
}
