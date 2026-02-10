import Foundation

/// Version-independent car carriage reservation
public class CarCarriageReservationAPI {
    public var token: TokenAPI?
    public var train: String?
    public var departureDate: Date?
    public var arrivalDate: Date?
    public var reference: String?
    public var productId: String?
    public var productOwner: String?
    public var serviceBrand: ServiceBrandAPI?
    public var stationCodeTable: CodeTableType?
    public var fromStation: String?
    public var toStation: String?
    public var fromStationName: String?
    public var toStationName: String?
    public var carriers: [String] = []
    public var classCode: TravelClassType?
    public var coachNumber: String?
    public var placeNumber: String?
    public var numberOfBoats: Int = 0
    public var roofRackType: RoofRackType?
    public var loadingDeck: LoadingDeckType?
    public var loadingListEntry: Int?
    public var boardingOrArrival: BoardingOrArrivalType?
    public var tariffs: [TariffAPI] = []
    public var priceType: PriceTypeType?
    public var infoText: String?
    public var extensionData: TicketExtension?
    public var price: Int?
    public var vatDetails: [VatDetailAPI] = []

    public init() {}
}
