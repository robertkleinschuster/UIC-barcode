import Foundation

/// Travel class type
/// Matches Java: TravelClassType.java (omv3)
/// Note: Java uses "notApplicabel" (with typo), Swift uses "notApplicable"
public enum TravelClassType: Int {
    case notApplicable = 0  // Java: notApplicabel
    case first = 1
    case second = 2
    case tourist = 3
    case comfort = 4
    case premium = 5
    case business = 6
    case all = 7
    case premiumFirst = 8
    case standardFirst = 9
    case premiumSecond = 10
    case standardSecond = 11
    // Extensions possible
}
