import Foundation

struct LineTypeV2: ASN1Decodable {
    var carrierNum: Int?
    var carrierIA5: String?
    var lineId: [Int]?
    var stationCodeTable: CodeTableTypeV2?
    var entryStationNum: Int?
    var entryStationIA5: String?
    var terminatingStationNum: Int?
    var terminatingStationIA5: String?
    var city: Int?
    var binaryZoneId: Data?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 10 optional+default fields (all optional or default, no mandatory)
        let presence = try decoder.decodePresenceBitmap(count: 10)

        if presence[0] { carrierNum = try decoder.decodeConstrainedInt(min: 1, max: 32000) }
        if presence[1] { carrierIA5 = try decoder.decodeIA5String() }
        if presence[2] {
            let count = try decoder.decodeLengthDeterminant()
            lineId = []
            for _ in 0..<count {
                lineId?.append(Int(try decoder.decodeUnconstrainedInteger()))
            }
        }
        if presence[3] {
            stationCodeTable = try CodeTableTypeV2(from: &decoder)
        } else {
            stationCodeTable = .stationUIC
        }
        if presence[4] { entryStationNum = try decoder.decodeConstrainedInt(min: 0, max: 9999999) }
        if presence[5] { entryStationIA5 = try decoder.decodeIA5String() }
        if presence[6] { terminatingStationNum = try decoder.decodeConstrainedInt(min: 0, max: 9999999) }
        if presence[7] { terminatingStationIA5 = try decoder.decodeIA5String() }
        if presence[8] { city = Int(try decoder.decodeUnconstrainedInteger()) }
        if presence[9] { binaryZoneId = try decoder.decodeOctetString() }

        if hasExtensions {
            let numExt = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt where extPresence[i] {
                try decoder.skipOpenType()
            }
        }
    }
}

extension LineTypeV2: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        let stationCodeTablePresent = stationCodeTable != nil && stationCodeTable != .stationUIC
        try encoder.encodePresenceBitmap([
            carrierNum != nil,
            carrierIA5 != nil,
            lineId != nil,
            stationCodeTablePresent,
            entryStationNum != nil,
            entryStationIA5 != nil,
            terminatingStationNum != nil,
            terminatingStationIA5 != nil,
            city != nil,
            binaryZoneId != nil
        ])
        if let v = carrierNum { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        if let v = carrierIA5 { try encoder.encodeIA5String(v) }
        if let v = lineId {
            try encoder.encodeLengthDeterminant(v.count)
            for id in v { try encoder.encodeUnconstrainedInteger(Int64(id)) }
        }
        if stationCodeTablePresent { try encoder.encodeEnumerated(stationCodeTable!.rawValue, rootCount: CodeTableTypeV2.rootValueCount) }
        if let v = entryStationNum { try encoder.encodeConstrainedInt(v, min: 0, max: 9999999) }
        if let v = entryStationIA5 { try encoder.encodeIA5String(v) }
        if let v = terminatingStationNum { try encoder.encodeConstrainedInt(v, min: 0, max: 9999999) }
        if let v = terminatingStationIA5 { try encoder.encodeIA5String(v) }
        if let v = city { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = binaryZoneId { try encoder.encodeOctetString(v) }
    }
}
