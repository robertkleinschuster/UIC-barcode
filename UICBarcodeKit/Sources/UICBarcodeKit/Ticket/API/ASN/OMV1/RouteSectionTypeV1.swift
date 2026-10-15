import Foundation

struct RouteSectionTypeV1: ASN1Decodable {
    var stationCodeTable: CodeTableTypeV1?
    var fromStationNum: Int?
    var fromStationIA5: String?
    var toStationNum: Int?
    var toStationIA5: String?
    var fromStationNameUTF8: String?
    var toStationNameUTF8: String?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        // No extension marker
        // 7 optional+default fields (stationCodeTable is default, rest optional)
        let presence = try decoder.decodePresenceBitmap(count: 7)

        if presence[0] {
            stationCodeTable = try CodeTableTypeV1(from: &decoder)
        } else {
            stationCodeTable = .stationUIC
        }
        if presence[1] { fromStationNum = try decoder.decodeConstrainedInt(min: 1, max: 9999999) }
        if presence[2] { fromStationIA5 = try decoder.decodeIA5String() }
        if presence[3] { toStationNum = try decoder.decodeConstrainedInt(min: 1, max: 9999999) }
        if presence[4] { toStationIA5 = try decoder.decodeIA5String() }
        if presence[5] { fromStationNameUTF8 = try decoder.decodeUTF8String() }
        if presence[6] { toStationNameUTF8 = try decoder.decodeUTF8String() }
    }
}

// MARK: - RouteSectionTypeV1 Encoding

extension RouteSectionTypeV1: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        let stationCodeTablePresent = stationCodeTable != nil && stationCodeTable != .stationUIC
        try encoder.encodePresenceBitmap([
            stationCodeTablePresent,
            fromStationNum != nil,
            fromStationIA5 != nil,
            toStationNum != nil,
            toStationIA5 != nil,
            fromStationNameUTF8 != nil,
            toStationNameUTF8 != nil
        ])
        if stationCodeTablePresent { try encoder.encodeEnumerated(stationCodeTable!.rawValue, rootCount: CodeTableTypeV1.rootValueCount) }
        if let v = fromStationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = fromStationIA5 { try encoder.encodeIA5String(v) }
        if let v = toStationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = toStationIA5 { try encoder.encodeIA5String(v) }
        if let v = fromStationNameUTF8 { try encoder.encodeUTF8String(v) }
        if let v = toStationNameUTF8 { try encoder.encodeUTF8String(v) }
    }
}
