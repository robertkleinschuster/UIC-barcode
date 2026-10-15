import Foundation

struct ReturnRouteDescriptionTypeV1: ASN1Decodable {
    var fromStationNum: Int?
    var fromStationIA5: String?
    var toStationNum: Int?
    var toStationIA5: String?
    var fromStationNameUTF8: String?
    var toStationNameUTF8: String?
    var validReturnRegionDesc: String?
    var validReturnRegion: [RegionalValidityTypeV1]?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 8 optional fields
        let presence = try decoder.decodePresenceBitmap(count: 8)

        if presence[0] { fromStationNum = try decoder.decodeConstrainedInt(min: 1, max: 9999999) }
        if presence[1] { fromStationIA5 = try decoder.decodeIA5String() }
        if presence[2] { toStationNum = try decoder.decodeConstrainedInt(min: 1, max: 9999999) }
        if presence[3] { toStationIA5 = try decoder.decodeIA5String() }
        if presence[4] { fromStationNameUTF8 = try decoder.decodeUTF8String() }
        if presence[5] { toStationNameUTF8 = try decoder.decodeUTF8String() }
        if presence[6] { validReturnRegionDesc = try decoder.decodeUTF8String() }
        if presence[7] { validReturnRegion = try decoder.decodeSequenceOf() }

        if hasExtensions {
            let numExt = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt where extPresence[i] {
                try decoder.skipOpenType()
            }
        }
    }
}

// MARK: - ReturnRouteDescriptionTypeV1 Encoding

extension ReturnRouteDescriptionTypeV1: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        try encoder.encodePresenceBitmap([
            fromStationNum != nil,
            fromStationIA5 != nil,
            toStationNum != nil,
            toStationIA5 != nil,
            fromStationNameUTF8 != nil,
            toStationNameUTF8 != nil,
            validReturnRegionDesc != nil,
            validReturnRegion != nil
        ])
        if let v = fromStationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = fromStationIA5 { try encoder.encodeIA5String(v) }
        if let v = toStationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = toStationIA5 { try encoder.encodeIA5String(v) }
        if let v = fromStationNameUTF8 { try encoder.encodeUTF8String(v) }
        if let v = toStationNameUTF8 { try encoder.encodeUTF8String(v) }
        if let v = validReturnRegionDesc { try encoder.encodeUTF8String(v) }
        if let arr = validReturnRegion { try encoder.encodeSequenceOf(arr) }
    }
}
