import Foundation

struct LuggageRestrictionTypeV2: ASN1Decodable {
    var maxHandLuggagePieces: Int?
    var maxNonHandLuggagePieces: Int?
    var registeredLuggage: [RegisteredLuggageTypeV2]?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 3 optional fields
        let presence = try decoder.decodePresenceBitmap(count: 3)

        if presence[0] {
            maxHandLuggagePieces = try decoder.decodeConstrainedInt(min: 0, max: 99)
        } else {
            maxHandLuggagePieces = 3
        }
        if presence[1] {
            maxNonHandLuggagePieces = try decoder.decodeConstrainedInt(min: 0, max: 99)
        } else {
            maxNonHandLuggagePieces = 1
        }
        if presence[2] { registeredLuggage = try decoder.decodeSequenceOf() }

        if hasExtensions {
            let numExt = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt where extPresence[i] {
                try decoder.skipOpenType()
            }
        }
    }
}

extension LuggageRestrictionTypeV2: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        let maxHandLuggagePresent = maxHandLuggagePieces != nil && maxHandLuggagePieces != 3
        let maxNonHandLuggagePresent = maxNonHandLuggagePieces != nil && maxNonHandLuggagePieces != 1
        try encoder.encodePresenceBitmap([
            maxHandLuggagePresent,
            maxNonHandLuggagePresent,
            registeredLuggage != nil
        ])
        if maxHandLuggagePresent { try encoder.encodeConstrainedInt(maxHandLuggagePieces!, min: 0, max: 99) }
        if maxNonHandLuggagePresent { try encoder.encodeConstrainedInt(maxNonHandLuggagePieces!, min: 0, max: 99) }
        if let v = registeredLuggage { try encoder.encodeSequenceOf(v) }
    }
}
