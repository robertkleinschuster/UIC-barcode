import Foundation

struct ViaStationTypeV2: ASN1Decodable {
    var stationCodeTable: CodeTableTypeV2?
    var stationNum: Int?
    var stationIA5: String?
    var alternativeRoutes: [ViaStationTypeV2]?
    var route: [ViaStationTypeV2]?
    var border: Bool = false
    var carriersNum: [Int]?
    var carriersIA5: [String]?
    var seriesId: Int?
    var routeId: Int?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 9 optional+default fields; border is mandatory
        let presence = try decoder.decodePresenceBitmap(count: 9)
        var idx = 0

        if presence[idx] {
            stationCodeTable = try CodeTableTypeV2(from: &decoder)
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

extension ViaStationTypeV2: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        let stationCodeTablePresent = stationCodeTable != nil && stationCodeTable != .stationUIC
        try encoder.encodePresenceBitmap([
            stationCodeTablePresent,
            stationNum != nil,
            stationIA5 != nil,
            alternativeRoutes != nil,
            route != nil,
            // border is mandatory
            carriersNum != nil,
            carriersIA5 != nil,
            seriesId != nil,
            routeId != nil
        ])
        if stationCodeTablePresent { try encoder.encodeEnumerated(stationCodeTable!.rawValue, rootCount: CodeTableTypeV2.rootValueCount) }
        if let v = stationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = stationIA5 { try encoder.encodeIA5String(v) }
        if let v = alternativeRoutes { try encoder.encodeSequenceOf(v) }
        if let v = route { try encoder.encodeSequenceOf(v) }
        // border is MANDATORY
        try encoder.encodeBoolean(border)
        if let v = carriersNum {
            try encoder.encodeLengthDeterminant(v.count)
            for num in v { try encoder.encodeConstrainedInt(num, min: 1, max: 32000) }
        }
        if let v = carriersIA5 {
            try encoder.encodeLengthDeterminant(v.count)
            for s in v { try encoder.encodeIA5String(s) }
        }
        if let v = seriesId { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = routeId { try encoder.encodeUnconstrainedInteger(Int64(v)) }
    }
}
