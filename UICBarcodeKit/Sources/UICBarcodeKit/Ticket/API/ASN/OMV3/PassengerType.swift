import Foundation

/// Passenger type
/// Matches Java: PassengerType.java
public enum PassengerType: Int {
    case adult = 0
    case senior = 1
    case child = 2
    case youth = 3
    case dog = 4
    case bicycle = 5
    case freeAddonPassenger = 6
    case freeAddonChild = 7
    // Extensions possible
}
