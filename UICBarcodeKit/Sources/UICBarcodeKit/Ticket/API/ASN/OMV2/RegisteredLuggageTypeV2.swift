import Foundation

struct RegisteredLuggageTypeV2: ASN1Decodable {
    var registrationId: String?
    var maxWeight: Int?
    var maxSize: Int?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 3 optional fields
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

extension RegisteredLuggageTypeV2: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
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
