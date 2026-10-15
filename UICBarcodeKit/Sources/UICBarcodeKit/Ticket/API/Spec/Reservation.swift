import Foundation

/// Version-independent reservation ticket
public class Reservation {
    public var token: TokenAPI?
    public var train: String?
    public var departureDate: Date?
    public var arrivalDate: Date?
    public var reference: String?
    public var productId: String?
    public var productOwner: String?
    public var serviceBrand: ServiceBrandAPI?
    public var service: ServiceType?
    public var stationCodeTable: CodeTableType?
    public var fromStation: String?
    public var toStation: String?
    public var fromStationName: String?
    public var toStationName: String?
    public var carriers: [String] = []
    public var classCode: TravelClassType?
    public var serviceLevel: String?
    public var places: PlacesAPI?
    public var additionalPlaces: PlacesAPI?
    public var bicyclePlaces: PlacesAPI?
    public var compartmentDetails: CompartmentDetailsAPI?
    public var numberOfOverbooked: Int = 0
    public var berths: [BerthAPI] = []
    public var tariffs: [TariffAPI] = []
    public var priceType: PriceTypeType?
    public var typeOfSupplement: Int = 0
    public var numberOfSupplements: Int = 0
    public var infoText: String?
    public var luggageRestriction: LuggageRestrictionAPI?
    public var extensionData: TicketExtension?
    public var price: Int?
    public var vatDetails: [VatDetailAPI] = []
    public var departureUTCoffset: Int?
    public var arrivalUTCoffset: Int?

    public init() {}
}
