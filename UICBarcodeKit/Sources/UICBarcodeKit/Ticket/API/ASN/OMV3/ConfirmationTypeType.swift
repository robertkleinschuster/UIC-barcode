import Foundation

/// Confirmation type for delay
/// Matches Java: ConfirmationTypeType.java
public enum ConfirmationTypeType: Int {
    case trainDelayConfirmation = 0
    case travelerDelayConfirmation = 1
    case trainLinkedTicketDelay = 2
}
