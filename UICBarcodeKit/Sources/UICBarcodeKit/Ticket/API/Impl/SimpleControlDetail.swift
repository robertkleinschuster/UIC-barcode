import Foundation

/// Concrete implementation of ControlDetail
public class SimpleControlDetail: ControlDetail {
    public var identificationByCardReference: [CardReferenceAPI] = []
    public var identificationByIdCard: Bool = false
    public var identificationByPassportId: Bool = false
    public var passportValidationRequired: Bool = false
    public var onlineValidationRequired: Bool = false
    public var ageCheckRequired: Bool = false
    public var reductionCardCheckRequired: Bool = false
    public var infoText: String?
    public var includedTickets: [TicketLinkAPI] = []
    public var extensionData: TicketExtension?

    public init() {}
}
