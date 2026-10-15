import Foundation

public struct TrainLinkType: ASN1Decodable {
    public var trainNum: Int?
    public var trainIA5: String?
    public var travelDate: Int = 0
    public var departureTime: Int = 0
    public var departureUTCOffset: Int?
    public var fromStationNum: Int?
    public var fromStationIA5: String?
    public var toStationNum: Int?
    public var toStationIA5: String?
    public var fromStationNameUTF8: String?
    public var toStationNameUTF8: String?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        // No @HasExtensionMarker in Java; 9 optional fields, 2 mandatory (travelDate, departureTime)
        let presence = try decoder.decodePresenceBitmap(count: 9)
        if presence[0] { trainNum = Int(try decoder.decodeUnconstrainedInteger()) }
        if presence[1] { trainIA5 = try decoder.decodeIA5String() }
        travelDate = try decoder.decodeConstrainedInt(min: -1, max: 500)
        departureTime = try decoder.decodeConstrainedInt(min: 0, max: 1440)
        if presence[2] { departureUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }
        if presence[3] { fromStationNum = try decoder.decodeConstrainedInt(min: 1, max: 9999999) }
        if presence[4] { fromStationIA5 = try decoder.decodeIA5String() }
        if presence[5] { toStationNum = try decoder.decodeConstrainedInt(min: 1, max: 9999999) }
        if presence[6] { toStationIA5 = try decoder.decodeIA5String() }
        if presence[7] { fromStationNameUTF8 = try decoder.decodeUTF8String() }
        if presence[8] { toStationNameUTF8 = try decoder.decodeUTF8String() }
    }
}

extension TrainLinkType: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodePresenceBitmap([
            trainNum != nil,
            trainIA5 != nil,
            departureUTCOffset != nil,
            fromStationNum != nil,
            fromStationIA5 != nil,
            toStationNum != nil,
            toStationIA5 != nil,
            fromStationNameUTF8 != nil,
            toStationNameUTF8 != nil
        ])

        if let v = trainNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = trainIA5 { try encoder.encodeIA5String(v) }
        try encoder.encodeConstrainedInt(travelDate, min: -1, max: 500)
        try encoder.encodeConstrainedInt(departureTime, min: 0, max: 1440)
        if let v = departureUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if let v = fromStationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = fromStationIA5 { try encoder.encodeIA5String(v) }
        if let v = toStationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = toStationIA5 { try encoder.encodeIA5String(v) }
        if let v = fromStationNameUTF8 { try encoder.encodeUTF8String(v) }
        if let v = toStationNameUTF8 { try encoder.encodeUTF8String(v) }
    }
}
