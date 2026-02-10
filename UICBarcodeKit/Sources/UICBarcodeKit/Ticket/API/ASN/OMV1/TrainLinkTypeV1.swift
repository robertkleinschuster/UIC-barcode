import Foundation

struct TrainLinkTypeV1: ASN1Decodable {
    var trainNum: Int?
    var trainIA5: String?
    var travelDate: Int = 0
    var departureTime: Int = 0
    var departureUTCOffset: Int?
    var fromStationNum: Int?
    var fromStationIA5: String?
    var toStationNum: Int?
    var toStationIA5: String?
    var fromStationNameUTF8: String?
    var toStationNameUTF8: String?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        // NO extension marker in Java
        // 9 optional fields; travelDate and departureTime are mandatory
        let presence = try decoder.decodePresenceBitmap(count: 9)
        var idx = 0

        if presence[idx] { trainNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { trainIA5 = try decoder.decodeIA5String() }; idx += 1

        // travelDate is MANDATORY
        travelDate = try decoder.decodeConstrainedInt(min: -1, max: 370)
        // departureTime is MANDATORY
        departureTime = try decoder.decodeConstrainedInt(min: 0, max: 1440)

        if presence[idx] { departureUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }; idx += 1
        if presence[idx] { fromStationNum = try decoder.decodeConstrainedInt(min: 1, max: 9999999) }; idx += 1
        if presence[idx] { fromStationIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { toStationNum = try decoder.decodeConstrainedInt(min: 1, max: 9999999) }; idx += 1
        if presence[idx] { toStationIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { fromStationNameUTF8 = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] { toStationNameUTF8 = try decoder.decodeUTF8String() }
    }
}

// MARK: - TrainLinkTypeV1 Encoding

extension TrainLinkTypeV1: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
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
        try encoder.encodeConstrainedInt(travelDate, min: -1, max: 370)
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
