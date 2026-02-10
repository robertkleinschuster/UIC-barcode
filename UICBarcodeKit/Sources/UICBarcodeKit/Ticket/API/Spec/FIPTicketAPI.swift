import Foundation

/// Version-independent FIP ticket
public class FIPTicketAPI {
    public var token: TokenAPI?
    public var reference: String?
    public var productId: String?
    public var productOwner: String?
    public var validFrom: Date?
    public var validUntil: Date?
    public var classCode: TravelClassType?
    public var carriers: [String] = []
    public var numberOfTravelDays: Int = 0
    public var includesSupplements: Bool = false
    public var infoText: String?
    public var extensionData: TicketExtension?
    public var activatedDays: [Date] = []

    public init() {}
}
