import Foundation

public struct LineType: ASN1Decodable {
    public var carrierNum: Int?
    public var carrierIA5: String?
    public var lineId: [Int]?
    public var stationCodeTable: CodeTableType?
    public var entryStationNum: Int?
    public var entryStationIA5: String?
    public var terminatingStationNum: Int?
    public var terminatingStationIA5: String?
    public var city: Int?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        let presence = try decoder.decodePresenceBitmap(count: 9)

        if presence[0] { carrierNum = try decoder.decodeConstrainedInt(min: 1, max: 32000) }
        if presence[1] { carrierIA5 = try decoder.decodeIA5String() }
        if presence[2] {
            let count = try decoder.decodeLengthDeterminant()
            lineId = []
            for _ in 0..<count {
                lineId?.append(Int(try decoder.decodeUnconstrainedInteger()))
            }
        }
        // Field 3: stationCodeTable (optional, default stationUIC)
        if presence[3] {
            let value = try decoder.decodeEnumerated(rootCount: 5)
            stationCodeTable = CodeTableType(rawValue: value)
        } else {
            stationCodeTable = .stationUIC
        }
        if presence[4] { entryStationNum = try decoder.decodeConstrainedInt(min: 1, max: 9999999) }
        if presence[5] { entryStationIA5 = try decoder.decodeIA5String() }
        if presence[6] { terminatingStationNum = try decoder.decodeConstrainedInt(min: 1, max: 9999999) }
        if presence[7] { terminatingStationIA5 = try decoder.decodeIA5String() }
        if presence[8] { city = Int(try decoder.decodeUnconstrainedInteger()) }

        if hasExtensions {
            let numExt = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt where extPresence[i] {
                try decoder.skipOpenType()
            }
        }
    }
}

extension LineType: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
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
            city != nil
        ])

        if let v = carrierNum { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        if let v = carrierIA5 { try encoder.encodeIA5String(v) }
        if let arr = lineId {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        }
        if stationCodeTablePresent { try encoder.encodeEnumerated(stationCodeTable!.rawValue, rootCount: 5) }
        if let v = entryStationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = entryStationIA5 { try encoder.encodeIA5String(v) }
        if let v = terminatingStationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = terminatingStationIA5 { try encoder.encodeIA5String(v) }
        if let v = city { try encoder.encodeUnconstrainedInteger(Int64(v)) }
    }
}
