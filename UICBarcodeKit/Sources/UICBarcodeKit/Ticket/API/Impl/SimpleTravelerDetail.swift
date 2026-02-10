import Foundation

/// Concrete implementation of TravelerDetail
public class SimpleTravelerDetail: TravelerDetail {
    public var travelers: [Traveler] = []
    public var preferedLanguage: String?
    public var groupName: String?

    public init() {}
}
