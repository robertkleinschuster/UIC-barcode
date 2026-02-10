import Foundation

struct BerthDetailDataV2: ASN1Decodable {
    var berthType: BerthTypeTypeV2 = .single
    var numberOfBerths: Int = 1
    var gender: CompartmentGenderTypeV2?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 1 default field (gender)
        let presence = try decoder.decodePresenceBitmap(count: 1)

        // berthType is MANDATORY
        berthType = try BerthTypeTypeV2(from: &decoder)
        // numberOfBerths is MANDATORY
        numberOfBerths = try decoder.decodeConstrainedInt(min: 1, max: 999)

        if presence[0] {
            gender = try CompartmentGenderTypeV2(from: &decoder)
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

extension BerthDetailDataV2: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        let genderPresent = gender != nil && gender != .family
        try encoder.encodePresenceBitmap([genderPresent])
        // berthType is MANDATORY
        try encoder.encodeEnumerated(berthType.rawValue, rootCount: BerthTypeTypeV2.rootValueCount)
        // numberOfBerths is MANDATORY
        try encoder.encodeConstrainedInt(numberOfBerths, min: 1, max: 999)
        if genderPresent { try encoder.encodeEnumerated(gender!.rawValue, rootCount: CompartmentGenderTypeV2.rootValueCount, hasExtensionMarker: CompartmentGenderTypeV2.hasExtensionMarker) }
    }
}
