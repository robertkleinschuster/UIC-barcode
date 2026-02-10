import Foundation

// MARK: - Station Passage Data

/// Station passage data - FCB v3 all 22 fields
public struct StationPassageData: ASN1Decodable {
    public var referenceIA5: String?
    public var referenceNum: Int?
    public var productOwnerNum: Int?
    public var productOwnerIA5: String?
    public var productIdNum: Int?
    public var productIdIA5: String?
    public var productName: String?
    public var stationCodeTable: CodeTableType?
    public var stationNum: [Int]?
    public var stationIA5: [String]?
    public var stationNameUTF8: [String]?
    public var areaCodeNum: [Int]?
    public var areaCodeIA5: [String]?
    public var areaNameUTF8: [String]?
    public var validFromDay: Int = 0                                // 14: MANDATORY
    public var validFromTime: Int?
    public var validFromUTCOffset: Int?
    public var validUntilDay: Int?
    public var validUntilTime: Int?
    public var validUntilUTCOffset: Int?
    public var numberOfDaysValid: Int?
    public var extensionData: ExtensionData?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 21 optional fields (field 14: validFromDay is MANDATORY)
        let presence = try decoder.decodePresenceBitmap(count: 21)
        var idx = 0

        if presence[idx] { referenceIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { referenceNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { productOwnerNum = try decoder.decodeConstrainedInt(min: 1, max: 32000) }; idx += 1
        if presence[idx] { productOwnerIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { productIdNum = try decoder.decodeConstrainedInt(min: 0, max: 65535) }; idx += 1
        if presence[idx] { productIdIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { productName = try decoder.decodeUTF8String() }; idx += 1
        // Field 7: stationCodeTable (optional, default stationUIC)
        if presence[idx] {
            let value = try decoder.decodeEnumerated(rootCount: 5)
            stationCodeTable = CodeTableType(rawValue: value)
        } else {
            stationCodeTable = .stationUIC
        }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            stationNum = []
            for _ in 0..<count {
                stationNum?.append(Int(try decoder.decodeUnconstrainedInteger()))
            }
        }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            stationIA5 = []
            for _ in 0..<count {
                stationIA5?.append(try decoder.decodeIA5String())
            }
        }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            stationNameUTF8 = []
            for _ in 0..<count {
                stationNameUTF8?.append(try decoder.decodeUTF8String())
            }
        }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            areaCodeNum = []
            for _ in 0..<count {
                areaCodeNum?.append(Int(try decoder.decodeUnconstrainedInteger()))
            }
        }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            areaCodeIA5 = []
            for _ in 0..<count {
                areaCodeIA5?.append(try decoder.decodeIA5String())
            }
        }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            areaNameUTF8 = []
            for _ in 0..<count {
                areaNameUTF8?.append(try decoder.decodeUTF8String())
            }
        }; idx += 1
        // Field 14: validFromDay (MANDATORY)
        validFromDay = try decoder.decodeConstrainedInt(min: -367, max: 700)
        if presence[idx] { validFromTime = try decoder.decodeConstrainedInt(min: 0, max: 1440) }; idx += 1
        if presence[idx] { validFromUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }; idx += 1
        if presence[idx] { validUntilDay = try decoder.decodeConstrainedInt(min: -1, max: 500) } else { validUntilDay = 0 }; idx += 1
        if presence[idx] { validUntilTime = try decoder.decodeConstrainedInt(min: 0, max: 1440) }; idx += 1
        if presence[idx] { validUntilUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }; idx += 1
        if presence[idx] { numberOfDaysValid = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { extensionData = try ExtensionData(from: &decoder) }

        if hasExtensions {
            let numExt = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt where extPresence[i] {
                try decoder.skipOpenType()
            }
        }
    }
}

// MARK: - StationPassageData Encoding

extension StationPassageData: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)

        let stationCodeTablePresent = stationCodeTable != nil && stationCodeTable != .stationUIC
        let validUntilDayPresent = validUntilDay != nil && validUntilDay != 0

        try encoder.encodePresenceBitmap([
            referenceIA5 != nil,
            referenceNum != nil,
            productOwnerNum != nil,
            productOwnerIA5 != nil,
            productIdNum != nil,
            productIdIA5 != nil,
            productName != nil,
            stationCodeTablePresent,
            stationNum != nil,
            stationIA5 != nil,
            stationNameUTF8 != nil,
            areaCodeNum != nil,
            areaCodeIA5 != nil,
            areaNameUTF8 != nil,
            validFromTime != nil,
            validFromUTCOffset != nil,
            validUntilDayPresent,
            validUntilTime != nil,
            validUntilUTCOffset != nil,
            numberOfDaysValid != nil,
            extensionData != nil
        ])

        if let v = referenceIA5 { try encoder.encodeIA5String(v) }
        if let v = referenceNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = productOwnerNum { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        if let v = productOwnerIA5 { try encoder.encodeIA5String(v) }
        if let v = productIdNum { try encoder.encodeConstrainedInt(v, min: 0, max: 65535) }
        if let v = productIdIA5 { try encoder.encodeIA5String(v) }
        if let v = productName { try encoder.encodeUTF8String(v) }
        if stationCodeTablePresent { try encoder.encodeEnumerated(stationCodeTable!.rawValue, rootCount: 5) }
        if let arr = stationNum {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        }
        if let arr = stationIA5 {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeIA5String(v) }
        }
        if let arr = stationNameUTF8 {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeUTF8String(v) }
        }
        if let arr = areaCodeNum {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        }
        if let arr = areaCodeIA5 {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeIA5String(v) }
        }
        if let arr = areaNameUTF8 {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeUTF8String(v) }
        }
        try encoder.encodeConstrainedInt(validFromDay, min: -367, max: 700)
        if let v = validFromTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1440) }
        if let v = validFromUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if validUntilDayPresent { try encoder.encodeConstrainedInt(validUntilDay!, min: -1, max: 500) }
        if let v = validUntilTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1440) }
        if let v = validUntilUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if let v = numberOfDaysValid { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = extensionData { try v.encode(to: &encoder) }
    }
}
