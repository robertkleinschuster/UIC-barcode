import Foundation

/// Version-independent delay confirmation
public class DelayConfirmationAPI {
    public var token: TokenAPI?
    public var reference: String?
    public var train: String?
    public var plannedArrivalDate: Date?
    public var delay: Int = 0
    public var stationCodeTable: CodeTableType?
    public var stationNum: Int?
    public var stationIA5: String?
    public var stationNameUTF8: String?
    public var confirmationType: ConfirmationTypeType?
    public var affectedTickets: [TicketLinkAPI] = []
    public var infoText: String?
    public var extensionData: TicketExtension?

    public init() {}
}
