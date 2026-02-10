import Foundation

struct ViaStationTypeV1: ASN1Decodable {
    var stationCodeTable: CodeTableTypeV1?
    var stationNum: Int?
    var stationIA5: String?
    var alternativeRoutes: [ViaStationTypeV1]?
    var route: [ViaStationTypeV1]?
    var border: Bool = false
    var carriersNum: [Int]?
    var carriersIA5: [String]?
    var seriesId: Int?
    var routeId: Int?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 9 optional+default fields; border is mandatory
        // stationCodeTable(D), stationNum, stationIA5 = 3
        // alternativeRoutes, route = 2 optional
        // carriersNum, carriersIA5, seriesId, routeId = 4 optional
        // Total = 9 optional+default
        let presence = try decoder.decodePresenceBitmap(count: 9)
        var idx = 0

        if presence[idx] {
            stationCodeTable = try CodeTableTypeV1(from: &decoder)
        } else {
            stationCodeTable = .stationUIC
        }; idx += 1
        if presence[idx] { stationNum = try decoder.decodeConstrainedInt(min: 1, max: 9999999) }; idx += 1
        if presence[idx] { stationIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { alternativeRoutes = try decoder.decodeSequenceOf() }; idx += 1
        if presence[idx] { route = try decoder.decodeSequenceOf() }; idx += 1

        // border is MANDATORY
        border = try decoder.decodeBoolean()

        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            carriersNum = []
            for _ in 0..<count {
                carriersNum?.append(try decoder.decodeConstrainedInt(min: 1, max: 32000))
            }
        }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            carriersIA5 = []
            for _ in 0..<count {
                carriersIA5?.append(try decoder.decodeIA5String())
            }
        }; idx += 1
        if presence[idx] { seriesId = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { routeId = Int(try decoder.decodeUnconstrainedInteger()) }

        if hasExtensions {
            let numExt = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt where extPresence[i] {
                try decoder.skipOpenType()
            }
        }
    }
}

// MARK: - ViaStationTypeV1 Encoding

extension ViaStationTypeV1: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        let stationCodeTablePresent = stationCodeTable != nil && stationCodeTable != .stationUIC
        try encoder.encodePresenceBitmap([
            stationCodeTablePresent,
            stationNum != nil,
            stationIA5 != nil,
            alternativeRoutes != nil,
            route != nil,
            carriersNum != nil,
            carriersIA5 != nil,
            seriesId != nil,
            routeId != nil
        ])
        if stationCodeTablePresent { try encoder.encodeEnumerated(stationCodeTable!.rawValue, rootCount: CodeTableTypeV1.rootValueCount) }
        if let v = stationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = stationIA5 { try encoder.encodeIA5String(v) }
        if let arr = alternativeRoutes { try encoder.encodeSequenceOf(arr) }
        if let arr = route { try encoder.encodeSequenceOf(arr) }
        try encoder.encodeBoolean(border)
        if let arr = carriersNum {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        }
        if let arr = carriersIA5 {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeIA5String(v) }
        }
        if let v = seriesId { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = routeId { try encoder.encodeUnconstrainedInteger(Int64(v)) }
    }
}
