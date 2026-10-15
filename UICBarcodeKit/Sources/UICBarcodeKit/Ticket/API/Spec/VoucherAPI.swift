import Foundation

/// Version-independent voucher
public class VoucherAPI {
    public var token: TokenAPI?
    public var reference: String?
    public var productId: String?
    public var productOwner: String?
    public var validFrom: Date?
    public var validUntil: Date?
    public var amount: Int = 0
    public var infoText: String?
    public var extensionData: TicketExtension?
    public var type: Int = 0

    public init() {}
}
