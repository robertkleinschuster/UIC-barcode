import Foundation

/// Concrete implementation of Traveler
public class SimpleTraveler: Traveler {
    public var firstName: String?
    public var secondName: String?
    public var lastName: String?
    public var idCard: String?
    public var passportId: String?
    public var title: String?
    public var gender: GenderType?
    public var customerId: String?
    public var dateOfBirth: Date?
    public var ticketHolder: Bool = false
    public var passengerType: PassengerType?
    public var passengerWithReducedMobility: Bool?
    public var countryOfResidence: Int?
    public var passportCountry: Int?
    public var idCardCountry: Int?
    public var status: [CustomerStatusDescription] = []

    public init() {}
}
