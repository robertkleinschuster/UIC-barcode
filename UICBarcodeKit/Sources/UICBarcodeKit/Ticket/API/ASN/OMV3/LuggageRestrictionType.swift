import Foundation

public struct LuggageRestrictionType: ASN1Decodable {
    public var maxHandLuggagePieces: Int?
    public var maxNonHandLuggagePieces: Int?
    public var registeredLuggage: [RegisteredLuggageType]?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
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

extension LuggageRestrictionType: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)

        let maxHandPresent = maxHandLuggagePieces != nil && maxHandLuggagePieces != 3
        let maxNonHandPresent = maxNonHandLuggagePieces != nil && maxNonHandLuggagePieces != 1

        try encoder.encodePresenceBitmap([
            maxHandPresent,
            maxNonHandPresent,
            registeredLuggage != nil
        ])

        if maxHandPresent { try encoder.encodeConstrainedInt(maxHandLuggagePieces!, min: 0, max: 99) }
        if maxNonHandPresent { try encoder.encodeConstrainedInt(maxNonHandLuggagePieces!, min: 0, max: 99) }
        if let arr = registeredLuggage { try encoder.encodeSequenceOf(arr) }
    }
}
