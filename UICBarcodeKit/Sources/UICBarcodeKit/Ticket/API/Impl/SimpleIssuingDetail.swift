import Foundation

/// Concrete implementation of IssuingDetail
public class SimpleIssuingDetail: IssuingDetail {
    public var issuingDate: Date?
    public var issuer: String?
    public var securityProvider: String?
    public var issuerName: String?
    public var specimen: Bool = false
    public var activated: Bool = true
    public var issuerPNR: String?
    public var issuedOnTrain: String?
    public var issuedOnLine: Int?
    public var pointOfSale: GeoCoordinateAPI?
    public var securePaperTicket: Bool = false
    public var currency: String?
    public var currencyFraction: Int?
    public var extensionData: TicketExtension?

    public init() {}
}
