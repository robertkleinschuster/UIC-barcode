import Foundation

/// Individual traveler information
public protocol Traveler: AnyObject {
    var firstName: String? { get set }
    var secondName: String? { get set }
    var lastName: String? { get set }
    var idCard: String? { get set }
    var passportId: String? { get set }
    var title: String? { get set }
    var gender: GenderType? { get set }
    var customerId: String? { get set }
    var dateOfBirth: Date? { get set }
    var ticketHolder: Bool { get set }
    var passengerType: PassengerType? { get set }
    var passengerWithReducedMobility: Bool? { get set }
    var countryOfResidence: Int? { get set }
    var passportCountry: Int? { get set }
    var idCardCountry: Int? { get set }
    var status: [CustomerStatusDescription] { get set }
}
