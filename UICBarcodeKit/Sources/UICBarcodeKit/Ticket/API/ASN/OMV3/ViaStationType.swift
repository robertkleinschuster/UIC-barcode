import Foundation

public struct ViaStationType: ASN1Decodable {
    public var stationCodeTable: CodeTableType?
    public var stationNum: Int?
    public var stationIA5: String?
    public var alternativeRoutes: [ViaStationType]?
    public var route: [ViaStationType]?
    public var border: Bool = false
    public var carriersNum: [Int]?
    public var carriersIA5: [String]?
    public var seriesId: Int?
    public var routeId: Int?
    public var includedServiceBrands: [Int]?
    public var excludedServiceBrands: [Int]?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 11 optional/default fields, 1 mandatory (border)
        let presence = try decoder.decodePresenceBitmap(count: 11)

        if presence[0] {
            let value = try decoder.decodeEnumerated(rootCount: 5)
            stationCodeTable = CodeTableType(rawValue: value)
        } else {
            stationCodeTable = .stationUIC
        }
        if presence[1] { stationNum = try decoder.decodeConstrainedInt(min: 1, max: 9999999) }
        if presence[2] { stationIA5 = try decoder.decodeIA5String() }
        if presence[3] { alternativeRoutes = try decoder.decodeSequenceOf() }
        if presence[4] { route = try decoder.decodeSequenceOf() }
        border = try decoder.decodeBoolean()
        if presence[5] {
            let count = try decoder.decodeLengthDeterminant()
            carriersNum = []
            for _ in 0..<count {
                carriersNum?.append(try decoder.decodeConstrainedInt(min: 1, max: 32000))
            }
        }
        if presence[6] {
            let count = try decoder.decodeLengthDeterminant()
            carriersIA5 = []
            for _ in 0..<count {
                carriersIA5?.append(try decoder.decodeIA5String())
            }
        }
        if presence[7] { seriesId = Int(try decoder.decodeUnconstrainedInteger()) }
        if presence[8] { routeId = Int(try decoder.decodeUnconstrainedInteger()) }
        if presence[9] {
            let count = try decoder.decodeLengthDeterminant()
            includedServiceBrands = []
            for _ in 0..<count {
                includedServiceBrands?.append(try decoder.decodeConstrainedInt(min: 1, max: 32000))
            }
        }
        if presence[10] {
            let count = try decoder.decodeLengthDeterminant()
            excludedServiceBrands = []
            for _ in 0..<count {
                excludedServiceBrands?.append(try decoder.decodeConstrainedInt(min: 1, max: 32000))
            }
        }

        if hasExtensions {
            let numExt = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt where extPresence[i] {
                try decoder.skipOpenType()
            }
        }
    }
}

extension ViaStationType: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
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
            routeId != nil,
            includedServiceBrands != nil,
            excludedServiceBrands != nil
        ])

        if stationCodeTablePresent { try encoder.encodeEnumerated(stationCodeTable!.rawValue, rootCount: 5) }
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
        if let arr = includedServiceBrands {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        }
        if let arr = excludedServiceBrands {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        }
    }
}
