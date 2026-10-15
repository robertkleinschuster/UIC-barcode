import Foundation

/// Card reference for identification
public struct CardReferenceAPI {
    public var cardIssuerNum: Int?
    public var cardIssuerIA5: String?
    public var cardIdNum: Int?
    public var cardIdIA5: String?
    public var cardName: String?
    public var cardType: Int?
    public var leadingCardIdNum: Int?
    public var leadingCardIdIA5: String?
    public var trailingCardIdNum: Int?
    public var trailingCardIdIA5: String?

    public init() {}
}
