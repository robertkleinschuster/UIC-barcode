import Foundation

/// Link between tickets
public struct TicketLinkAPI {
    public var referenceIA5: String?
    public var referenceNum: Int?
    public var issuerName: String?
    public var issuerPNR: String?
    public var productOwnerNum: Int?
    public var productOwnerIA5: String?
    public var ticketType: TicketType?
    public var linkMode: LinkMode?

    public init() {}
}
