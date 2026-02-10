import Foundation

/// Security token
public struct TokenAPI {
    public var tokenProviderIA5: String?
    public var tokenProviderNum: Int?
    public var tokenSpecification: String?
    public var token: Data?

    public init() {}
}
