import Foundation

/// Collection of travelers
public protocol TravelerDetail: AnyObject {
    var travelers: [Traveler] { get set }
    var preferedLanguage: String? { get set }
    var groupName: String? { get set }
}
