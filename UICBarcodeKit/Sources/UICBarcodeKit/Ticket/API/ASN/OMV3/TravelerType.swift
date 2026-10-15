import Foundation

/// Individual traveler information
public struct TravelerType: ASN1Decodable {
    public var firstName: String?
    public var secondName: String?
    public var lastName: String?
    public var idCard: String?
    public var passportId: String?
    public var title: String?
    public var gender: GenderType?
    public var customerIdIA5: String?
    public var customerIdNum: Int?
    public var yearOfBirth: Int?
    public var monthOfBirth: Int?
    public var dayOfBirth: Int?
    public var ticketHolder: Bool = true
    public var passengerType: PassengerType?
    public var passengerWithReducedMobility: Bool?
    public var countryOfResidence: Int?
    public var countryOfPassport: Int?
    public var countryOfIdCard: Int?
    public var status: [CustomerStatusType]?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()

        // This is a complex structure with many optional fields
        // Simplified implementation - read presence bitmap and decode accordingly
        let optionalCount = 18 // Approximate number of optional fields
        let presence = try decoder.decodePresenceBitmap(count: optionalCount)
        var idx = 0

        if presence[idx] { firstName = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] { secondName = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] { lastName = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] { idCard = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { passportId = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { title = try decoder.decodeIA5String(constraint: ASN1StringConstraint(type: .ia5String, minLength: 1, maxLength: 3)) }; idx += 1
        if presence[idx] {
            let genderValue = try decoder.decodeEnumerated(rootCount: 4, hasExtensionMarker: true)
            gender = GenderType(rawValue: genderValue)
        }; idx += 1
        if presence[idx] { customerIdIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { customerIdNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { yearOfBirth = try decoder.decodeConstrainedInt(min: 1901, max: 2155) }; idx += 1
        if presence[idx] { monthOfBirth = try decoder.decodeConstrainedInt(min: 1, max: 12) }; idx += 1
        if presence[idx] { dayOfBirth = try decoder.decodeConstrainedInt(min: 1, max: 31) }; idx += 1
        ticketHolder = try decoder.decodeBoolean()
        if presence[idx] {
            let passengerValue = try decoder.decodeEnumerated(rootCount: 8, hasExtensionMarker: true)
            passengerType = PassengerType(rawValue: passengerValue)
        }; idx += 1
        if presence[idx] { passengerWithReducedMobility = try decoder.decodeBoolean() }; idx += 1
        if presence[idx] { countryOfResidence = try decoder.decodeConstrainedInt(min: 1, max: 999) }; idx += 1
        if presence[idx] { countryOfPassport = try decoder.decodeConstrainedInt(min: 1, max: 999) }; idx += 1
        if presence[idx] { countryOfIdCard = try decoder.decodeConstrainedInt(min: 1, max: 999) }; idx += 1
        if presence[idx] { status = try decoder.decodeSequenceOf() }

        if hasExtensions {
            let numExt = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt where extPresence[i] {
                try decoder.skipOpenType()
            }
        }
    }
}

extension TravelerType: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        try encoder.encodePresenceBitmap([
            firstName != nil,
            secondName != nil,
            lastName != nil,
            idCard != nil,
            passportId != nil,
            title != nil,
            gender != nil,
            customerIdIA5 != nil,
            customerIdNum != nil,
            yearOfBirth != nil,
            monthOfBirth != nil,
            dayOfBirth != nil,
            passengerType != nil,
            passengerWithReducedMobility != nil,
            countryOfResidence != nil,
            countryOfPassport != nil,
            countryOfIdCard != nil,
            status != nil
        ])
        if let firstName { try encoder.encodeUTF8String(firstName) }
        if let secondName { try encoder.encodeUTF8String(secondName) }
        if let lastName { try encoder.encodeUTF8String(lastName) }
        if let idCard { try encoder.encodeIA5String(idCard) }
        if let passportId { try encoder.encodeIA5String(passportId) }
        if let title { try encoder.encodeIA5String(title, constraint: ASN1StringConstraint(type: .ia5String, minLength: 1, maxLength: 3)) }
        if let gender { try encoder.encodeEnumerated(gender.rawValue, rootCount: 4, hasExtensionMarker: true) }
        if let customerIdIA5 { try encoder.encodeIA5String(customerIdIA5) }
        if let customerIdNum { try encoder.encodeUnconstrainedInteger(Int64(customerIdNum)) }
        if let yearOfBirth { try encoder.encodeConstrainedInt(yearOfBirth, min: 1901, max: 2155) }
        if let monthOfBirth { try encoder.encodeConstrainedInt(monthOfBirth, min: 1, max: 12) }
        if let dayOfBirth { try encoder.encodeConstrainedInt(dayOfBirth, min: 1, max: 31) }
        try encoder.encodeBoolean(ticketHolder)
        if let passengerType { try encoder.encodeEnumerated(passengerType.rawValue, rootCount: 8, hasExtensionMarker: true) }
        if let passengerWithReducedMobility { try encoder.encodeBoolean(passengerWithReducedMobility) }
        if let countryOfResidence { try encoder.encodeConstrainedInt(countryOfResidence, min: 1, max: 999) }
        if let countryOfPassport { try encoder.encodeConstrainedInt(countryOfPassport, min: 1, max: 999) }
        if let countryOfIdCard { try encoder.encodeConstrainedInt(countryOfIdCard, min: 1, max: 999) }
        if let status { try encoder.encodeSequenceOf(status) }
    }
}
