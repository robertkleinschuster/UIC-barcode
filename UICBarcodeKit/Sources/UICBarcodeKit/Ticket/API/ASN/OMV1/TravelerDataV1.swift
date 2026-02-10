import Foundation

struct TravelerDataV1: ASN1Decodable {
    static let hasExtensionMarker = true
    static let optionalFieldCount = 3

    var traveler: [TravelerTypeV1]?
    var preferedLanguage: String?
    var groupName: String?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        let presence = try decoder.decodePresenceBitmap(count: Self.optionalFieldCount)

        if presence[0] { traveler = try decoder.decodeSequenceOf() }
        if presence[1] {
            preferedLanguage = try decoder.decodeIA5String(
                constraint: ASN1StringConstraint(type: .ia5String, fixedLength: 2)
            )
        }
        if presence[2] { groupName = try decoder.decodeUTF8String() }

        if hasExtensions {
            let numExt = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt where extPresence[i] {
                try decoder.skipOpenType()
            }
        }
    }
}

extension TravelerDataV1: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        try encoder.encodePresenceBitmap([
            traveler != nil,
            preferedLanguage != nil,
            groupName != nil
        ])
        if let traveler { try encoder.encodeSequenceOf(traveler) }
        if let preferedLanguage { try encoder.encodeIA5String(preferedLanguage, constraint: ASN1StringConstraint(type: .ia5String, fixedLength: 2)) }
        if let groupName { try encoder.encodeUTF8String(groupName) }
    }
}
