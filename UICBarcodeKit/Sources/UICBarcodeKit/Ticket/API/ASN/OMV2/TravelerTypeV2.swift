import Foundation

struct TravelerTypeV2: ASN1Decodable {
    static let hasExtensionMarker = true
    static let optionalFieldCount = 18

    var firstName: String?
    var secondName: String?
    var lastName: String?
    var idCard: String?
    var passportId: String?
    var title: String?
    var gender: GenderTypeV2?
    var customerIdIA5: String?
    var customerIdNum: Int?
    var yearOfBirth: Int?
    var monthOfBirth: Int?
    var dayOfBirth: Int?
    var ticketHolder: Bool = true
    var passengerType: PassengerTypeV2?
    var passengerWithReducedMobility: Bool?
    var countryOfResidence: Int?
    var countryOfPassport: Int?
    var countryOfIdCard: Int?
    var status: [CustomerStatusTypeV2]?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        let presence = try decoder.decodePresenceBitmap(count: Self.optionalFieldCount)

        var idx = 0

        if presence[idx] { firstName = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] { secondName = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] { lastName = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] { idCard = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { passportId = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] {
            title = try decoder.decodeIA5String(
                constraint: ASN1StringConstraint(type: .ia5String, minLength: 1, maxLength: 3)
            )
        }; idx += 1
        if presence[idx] { gender = try GenderTypeV2(from: &decoder) }; idx += 1
        if presence[idx] { customerIdIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { customerIdNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { yearOfBirth = try decoder.decodeConstrainedInt(min: 1901, max: 2155) }; idx += 1
        if presence[idx] { monthOfBirth = try decoder.decodeConstrainedInt(min: 1, max: 12) }; idx += 1
        if presence[idx] { dayOfBirth = try decoder.decodeConstrainedInt(min: 1, max: 31) }; idx += 1

        // ticketHolder is mandatory
        ticketHolder = try decoder.decodeBoolean()

        if presence[idx] { passengerType = try PassengerTypeV2(from: &decoder) }; idx += 1
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

extension TravelerTypeV2: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
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
        if let v = firstName { try encoder.encodeUTF8String(v) }
        if let v = secondName { try encoder.encodeUTF8String(v) }
        if let v = lastName { try encoder.encodeUTF8String(v) }
        if let v = idCard { try encoder.encodeIA5String(v) }
        if let v = passportId { try encoder.encodeIA5String(v) }
        if let v = title { try encoder.encodeIA5String(v, constraint: ASN1StringConstraint(type: .ia5String, minLength: 1, maxLength: 3)) }
        if let v = gender { try encoder.encodeEnumerated(v.rawValue, rootCount: GenderTypeV2.rootValueCount, hasExtensionMarker: GenderTypeV2.hasExtensionMarker) }
        if let v = customerIdIA5 { try encoder.encodeIA5String(v) }
        if let v = customerIdNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = yearOfBirth { try encoder.encodeConstrainedInt(v, min: 1901, max: 2155) }
        if let v = monthOfBirth { try encoder.encodeConstrainedInt(v, min: 1, max: 12) }
        if let v = dayOfBirth { try encoder.encodeConstrainedInt(v, min: 1, max: 31) }
        try encoder.encodeBoolean(ticketHolder)
        if let v = passengerType { try encoder.encodeEnumerated(v.rawValue, rootCount: PassengerTypeV2.rootValueCount, hasExtensionMarker: PassengerTypeV2.hasExtensionMarker) }
        if let v = passengerWithReducedMobility { try encoder.encodeBoolean(v) }
        if let v = countryOfResidence { try encoder.encodeConstrainedInt(v, min: 1, max: 999) }
        if let v = countryOfPassport { try encoder.encodeConstrainedInt(v, min: 1, max: 999) }
        if let v = countryOfIdCard { try encoder.encodeConstrainedInt(v, min: 1, max: 999) }
        if let v = status { try encoder.encodeSequenceOf(v) }
    }
}
