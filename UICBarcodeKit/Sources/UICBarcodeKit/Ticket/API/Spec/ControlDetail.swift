import Foundation

/// Control/verification information
public protocol ControlDetail: AnyObject {
    var identificationByCardReference: [CardReferenceAPI] { get set }
    var identificationByIdCard: Bool { get set }
    var identificationByPassportId: Bool { get set }
    var passportValidationRequired: Bool { get set }
    var onlineValidationRequired: Bool { get set }
    var ageCheckRequired: Bool { get set }
    var reductionCardCheckRequired: Bool { get set }
    var infoText: String? { get set }
    var includedTickets: [TicketLinkAPI] { get set }
    var extensionData: TicketExtension? { get set }
}
