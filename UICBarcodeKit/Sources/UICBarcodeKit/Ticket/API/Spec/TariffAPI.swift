import Foundation

public struct TariffAPI {
    public var numberOfPassengers: Int = 1
    public var passengerType: PassengerType?
    public var ageBelow: Int?
    public var ageAbove: Int?
    public var reductionCard: [CardReferenceAPI] = []
    public var tariffIdNum: Int?
    public var tariffIdIA5: String?
    public var tariffDesc: String?
    public var seriesDataDetails: SeriesDetailAPI?

    public init() {}
}
