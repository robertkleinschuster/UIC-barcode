import Foundation

public struct TrainValidityAPI {
    public var validFrom: Date?
    public var validUntil: Date?
    public var bordingOrArrival: BoardingOrArrivalType?
    public var includedCarriersNum: [Int] = []
    public var includedCarriersIA5: [String] = []
    public var excludedCarriersNum: [Int] = []
    public var excludedCarriersIA5: [String] = []
    public var includedServiceBrands: [Int] = []
    public var excludedServiceBrands: [Int] = []

    public init() {}
}
