import Foundation

/// Customer loyalty/status type
public struct CustomerStatusDescription {
    public var statusProviderNum: Int?
    public var statusProviderIA5: String?
    public var customerStatus: Int?
    public var customerStatusDescr: String?

    public init() {}
}
