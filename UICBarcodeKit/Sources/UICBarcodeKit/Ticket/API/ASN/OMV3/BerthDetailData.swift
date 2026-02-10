import Foundation

public struct BerthDetailData: ASN1Decodable {
    public var berthType: BerthTypeType?
    public var numberOfBerths: Int?
    public var gender: CompartmentGenderType?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 1 optional field (gender); berthType and numberOfBerths are MANDATORY
        let presence = try decoder.decodePresenceBitmap(count: 1)
        // berthType is MANDATORY
        let berthValue = try decoder.decodeEnumerated(rootCount: 6)
        berthType = BerthTypeType(rawValue: berthValue)
        // numberOfBerths is MANDATORY
        numberOfBerths = try decoder.decodeConstrainedInt(min: 1, max: 999)
        if presence[0] {
            let value = try decoder.decodeEnumerated(rootCount: 5, hasExtensionMarker: true)
            gender = CompartmentGenderType(rawValue: value)
        } else {
            gender = .family
        }

        if hasExtensions {
            let numExt = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt where extPresence[i] {
                try decoder.skipOpenType()
            }
        }
    }
}

extension BerthDetailData: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)

        let genderPresent = gender != nil && gender != .family

        try encoder.encodePresenceBitmap([
            genderPresent
        ])

        try encoder.encodeEnumerated((berthType ?? .single).rawValue, rootCount: 6)
        try encoder.encodeConstrainedInt(numberOfBerths ?? 1, min: 1, max: 999)
        if genderPresent { try encoder.encodeEnumerated(gender!.rawValue, rootCount: 5, hasExtensionMarker: true) }
    }
}
