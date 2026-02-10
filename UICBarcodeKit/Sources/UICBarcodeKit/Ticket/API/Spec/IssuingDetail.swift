import Foundation

/// Ticket issuing information
public protocol IssuingDetail: AnyObject {
    var issuingDate: Date? { get set }
    var issuer: String? { get set }
    var securityProvider: String? { get set }
    var issuerName: String? { get set }
    var specimen: Bool { get set }
    var activated: Bool { get set }
    var issuerPNR: String? { get set }
    var issuedOnTrain: String? { get set }
    var issuedOnLine: Int? { get set }
    var pointOfSale: GeoCoordinateAPI? { get set }
    var securePaperTicket: Bool { get set }
    var currency: String? { get set }
    var currencyFraction: Int? { get set }
    var extensionData: TicketExtension? { get set }
}
