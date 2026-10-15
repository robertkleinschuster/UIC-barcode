import Foundation

struct ZoneTypeV1: ASN1Decodable {
    var carrierNum: Int?
    var carrierIA5: String?
    var stationCodeTable: CodeTableTypeV1?
    var entryStationNum: Int?
    var entryStationIA5: String?
    var terminatingStationNum: Int?
    var terminatingStationIA5: String?
    var city: Int?
    var zoneId: [Int]?
    var binaryZoneId: Data?
    var nutsCode: String?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 11 optional+default fields (all optional or default, no mandatory)
        let presence = try decoder.decodePresenceBitmap(count: 11)

        if presence[0] { carrierNum = try decoder.decodeConstrainedInt(min: 1, max: 32000) }
        if presence[1] { carrierIA5 = try decoder.decodeIA5String() }
        if presence[2] {
            stationCodeTable = try CodeTableTypeV1(from: &decoder)
        } else {
            stationCodeTable = .stationUIC
        }
        if presence[3] { entryStationNum = try decoder.decodeConstrainedInt(min: 0, max: 9999999) }
        if presence[4] { entryStationIA5 = try decoder.decodeIA5String() }
        if presence[5] { terminatingStationNum = try decoder.decodeConstrainedInt(min: 0, max: 9999999) }
        if presence[6] { terminatingStationIA5 = try decoder.decodeIA5String() }
        if presence[7] { city = Int(try decoder.decodeUnconstrainedInteger()) }
        if presence[8] {
            let count = try decoder.decodeLengthDeterminant()
            zoneId = []
            for _ in 0..<count {
                zoneId?.append(Int(try decoder.decodeUnconstrainedInteger()))
            }
        }
        if presence[9] { binaryZoneId = try decoder.decodeOctetString() }
        if presence[10] { nutsCode = try decoder.decodeIA5String() }

        if hasExtensions {
            let numExt = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt where extPresence[i] {
                try decoder.skipOpenType()
            }
        }
    }
}

// MARK: - ZoneTypeV1 Encoding

extension ZoneTypeV1: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        let stationCodeTablePresent = stationCodeTable != nil && stationCodeTable != .stationUIC
        try encoder.encodePresenceBitmap([
            carrierNum != nil,
            carrierIA5 != nil,
            stationCodeTablePresent,
            entryStationNum != nil,
            entryStationIA5 != nil,
            terminatingStationNum != nil,
            terminatingStationIA5 != nil,
            city != nil,
            zoneId != nil,
            binaryZoneId != nil,
            nutsCode != nil
        ])
        if let v = carrierNum { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        if let v = carrierIA5 { try encoder.encodeIA5String(v) }
        if stationCodeTablePresent { try encoder.encodeEnumerated(stationCodeTable!.rawValue, rootCount: CodeTableTypeV1.rootValueCount) }
        if let v = entryStationNum { try encoder.encodeConstrainedInt(v, min: 0, max: 9999999) }
        if let v = entryStationIA5 { try encoder.encodeIA5String(v) }
        if let v = terminatingStationNum { try encoder.encodeConstrainedInt(v, min: 0, max: 9999999) }
        if let v = terminatingStationIA5 { try encoder.encodeIA5String(v) }
        if let v = city { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let arr = zoneId {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        }
        if let v = binaryZoneId { try encoder.encodeOctetString(v) }
        if let v = nutsCode { try encoder.encodeIA5String(v) }
    }
}
