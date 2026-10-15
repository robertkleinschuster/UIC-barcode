import Foundation

/// Version-independent customer card
public class CustomerCardAPI {
    public var token: TokenAPI?
    public var reference: String?
    public var cardIssuer: String?
    public var cardIdNum: Int?
    public var cardIdIA5: String?
    public var cardType: Int?
    public var cardTypeDescr: String?
    public var classCode: TravelClassType?
    public var validFrom: Date?
    public var validUntil: Date?
    public var extensionData: TicketExtension?

    public init() {}
}
