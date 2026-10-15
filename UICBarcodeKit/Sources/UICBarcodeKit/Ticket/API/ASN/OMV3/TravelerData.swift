import Foundation

/// Information about traveler
public struct TravelerData: ASN1Decodable {
    public var traveler: [TravelerType]?
    public var preferedLanguage: String?
    public var groupName: String?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        let presence = try decoder.decodePresenceBitmap(count: 3)

        if presence[0] {
            traveler = try decoder.decodeSequenceOf()
        }
        if presence[1] {
            preferedLanguage = try decoder.decodeIA5String(constraint: ASN1StringConstraint(type: .ia5String, fixedLength: 2))
        }
        if presence[2] {
            groupName = try decoder.decodeUTF8String()
        }

        if hasExtensions {
            let numExt = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt {
                if extPresence[i] {
                    try decoder.skipOpenType()
                }
            }
        }
    }
}

extension TravelerData: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        try encoder.encodePresenceBitmap([
            traveler != nil,
            preferedLanguage != nil,
            groupName != nil
        ])
        if let traveler {
            try encoder.encodeSequenceOf(traveler)
        }
        if let preferedLanguage {
            try encoder.encodeIA5String(preferedLanguage, constraint: ASN1StringConstraint(type: .ia5String, fixedLength: 2))
        }
        if let groupName {
            try encoder.encodeUTF8String(groupName)
        }
    }
}
