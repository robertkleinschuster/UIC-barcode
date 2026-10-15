import Foundation

/// Compartment gender type
/// Matches Java: CompartmentGenderType.java (5 values including unspecified)
public enum CompartmentGenderType: Int {
    case unspecified = 0
    case family = 1
    case female = 2
    case male = 3
    case mixed = 4
}
