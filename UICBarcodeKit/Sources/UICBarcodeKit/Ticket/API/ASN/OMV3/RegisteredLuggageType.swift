import Foundation

public struct RegisteredLuggageType: ASN1Decodable {
    public var registrationId: String?
    public var maxWeight: Int?
    public var maxSize: Int?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        let presence = try decoder.decodePresenceBitmap(count: 3)
        if presence[0] { registrationId = try decoder.decodeIA5String() }
        if presence[1] { maxWeight = try decoder.decodeConstrainedInt(min: 1, max: 99) }
        if presence[2] { maxSize = try decoder.decodeConstrainedInt(min: 1, max: 300) }

        if hasExtensions {
            let numExt = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt where extPresence[i] {
                try decoder.skipOpenType()
            }
        }
    }
}

extension RegisteredLuggageType: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)

        try encoder.encodePresenceBitmap([
            registrationId != nil,
            maxWeight != nil,
            maxSize != nil
        ])

        if let v = registrationId { try encoder.encodeIA5String(v) }
        if let v = maxWeight { try encoder.encodeConstrainedInt(v, min: 1, max: 99) }
        if let v = maxSize { try encoder.encodeConstrainedInt(v, min: 1, max: 300) }
    }
}
