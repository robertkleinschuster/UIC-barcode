import Foundation

/// Route section type - NO extension marker in Java
public struct RouteSectionType: ASN1Decodable {
    public var stationCodeTable: CodeTableType?
    public var fromStationNum: Int?
    public var fromStationIA5: String?
    public var toStationNum: Int?
    public var toStationIA5: String?
    public var fromStationNameUTF8: String?
    public var toStationNameUTF8: String?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let presence = try decoder.decodePresenceBitmap(count: 7)

        if presence[0] {
            let value = try decoder.decodeEnumerated(rootCount: 5)
            stationCodeTable = CodeTableType(rawValue: value)
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

extension RouteSectionType: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
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

        if stationCodeTablePresent { try encoder.encodeEnumerated(stationCodeTable!.rawValue, rootCount: 5) }
        if let v = fromStationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = fromStationIA5 { try encoder.encodeIA5String(v) }
        if let v = toStationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = toStationIA5 { try encoder.encodeIA5String(v) }
        if let v = fromStationNameUTF8 { try encoder.encodeUTF8String(v) }
        if let v = toStationNameUTF8 { try encoder.encodeUTF8String(v) }
    }
}
