import Foundation

struct BerthDetailDataV1: ASN1Decodable {
    var berthType: BerthTypeTypeV1 = .single
    var numberOfBerths: Int = 1
    var gender: CompartmentGenderTypeV1?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 1 default field (gender)
        let presence = try decoder.decodePresenceBitmap(count: 1)

        // berthType is MANDATORY
        berthType = try BerthTypeTypeV1(from: &decoder)
        // numberOfBerths is MANDATORY
        numberOfBerths = try decoder.decodeConstrainedInt(min: 1, max: 999)

        if presence[0] {
            gender = try CompartmentGenderTypeV1(from: &decoder)
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

// MARK: - BerthDetailDataV1 Encoding

extension BerthDetailDataV1: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        let genderPresent = gender != nil && gender != .family
        try encoder.encodePresenceBitmap([genderPresent])
        try encoder.encodeEnumerated(berthType.rawValue, rootCount: BerthTypeTypeV1.rootValueCount)
        try encoder.encodeConstrainedInt(numberOfBerths, min: 1, max: 999)
        if genderPresent { try encoder.encodeEnumerated(gender!.rawValue, rootCount: CompartmentGenderTypeV1.rootValueCount, hasExtensionMarker: CompartmentGenderTypeV1.hasExtensionMarker) }
    }
}
