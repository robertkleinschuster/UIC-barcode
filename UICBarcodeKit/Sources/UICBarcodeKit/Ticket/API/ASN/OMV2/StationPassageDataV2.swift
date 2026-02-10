import Foundation

// MARK: - Station Passage Data

struct StationPassageDataV2: ASN1Decodable {
    var referenceIA5: String?
    var referenceNum: Int?
    var productOwnerNum: Int?
    var productOwnerIA5: String?
    var productIdNum: Int?
    var productIdIA5: String?
    var productName: String?
    var stationCodeTable: CodeTableTypeV2?
    var stationNum: [Int]?
    var stationIA5: [String]?
    var stationNameUTF8: [String]?
    var areaCodeNum: [Int]?
    var areaCodeIA5: [String]?
    var areaNameUTF8: [String]?
    var validFromDay: Int = 0
    var validFromTime: Int?
    var validFromUTCOffset: Int?
    var validUntilDay: Int?
    var validUntilTime: Int?
    var validUntilUTCOffset: Int?
    var numberOfDaysValid: Int?
    var extensionData: ExtensionDataV2?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 20 optional+default fields; validFromDay is mandatory
        // 21 optional+default fields; validFromDay is mandatory
        let presence = try decoder.decodePresenceBitmap(count: 21)
        var idx = 0

        if presence[idx] { referenceIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { referenceNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { productOwnerNum = try decoder.decodeConstrainedInt(min: 1, max: 32000) }; idx += 1
        if presence[idx] { productOwnerIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { productIdNum = try decoder.decodeConstrainedInt(min: 0, max: 65535) }; idx += 1
        if presence[idx] { productIdIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { productName = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] {
            stationCodeTable = try CodeTableTypeV2(from: &decoder)
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

        // validFromDay is MANDATORY
        validFromDay = try decoder.decodeConstrainedInt(min: -1, max: 700)

        if presence[idx] { validFromTime = try decoder.decodeConstrainedInt(min: 0, max: 1440) }; idx += 1
        if presence[idx] { validFromUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }; idx += 1
        if presence[idx] { validUntilDay = try decoder.decodeConstrainedInt(min: 0, max: 370) } else { validUntilDay = 0 }; idx += 1
        if presence[idx] { validUntilTime = try decoder.decodeConstrainedInt(min: 0, max: 1440) }; idx += 1
        if presence[idx] { validUntilUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }; idx += 1
        if presence[idx] { numberOfDaysValid = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { extensionData = try ExtensionDataV2(from: &decoder) }

        if hasExtensions {
            let numExt = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt where extPresence[i] {
                try decoder.skipOpenType()
            }
        }
    }
}

// MARK: - Station Passage Data Encoding

extension StationPassageDataV2: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        let stationCodeTablePresent = stationCodeTable != nil && stationCodeTable != .stationUIC
        let validUntilDayPresent = validUntilDay != nil && validUntilDay != 0
        // V2: 21 optional+default fields; validFromDay is mandatory
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
            // validFromDay is mandatory
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
        if stationCodeTablePresent { try encoder.encodeEnumerated(stationCodeTable!.rawValue, rootCount: CodeTableTypeV2.rootValueCount) }
        if let v = stationNum {
            try encoder.encodeLengthDeterminant(v.count)
            for num in v { try encoder.encodeUnconstrainedInteger(Int64(num)) }
        }
        if let v = stationIA5 {
            try encoder.encodeLengthDeterminant(v.count)
            for s in v { try encoder.encodeIA5String(s) }
        }
        if let v = stationNameUTF8 {
            try encoder.encodeLengthDeterminant(v.count)
            for s in v { try encoder.encodeUTF8String(s) }
        }
        if let v = areaCodeNum {
            try encoder.encodeLengthDeterminant(v.count)
            for num in v { try encoder.encodeUnconstrainedInteger(Int64(num)) }
        }
        if let v = areaCodeIA5 {
            try encoder.encodeLengthDeterminant(v.count)
            for s in v { try encoder.encodeIA5String(s) }
        }
        if let v = areaNameUTF8 {
            try encoder.encodeLengthDeterminant(v.count)
            for s in v { try encoder.encodeUTF8String(s) }
        }
        // validFromDay is MANDATORY
        try encoder.encodeConstrainedInt(validFromDay, min: -1, max: 700)
        if let v = validFromTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1440) }
        if let v = validFromUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if validUntilDayPresent { try encoder.encodeConstrainedInt(validUntilDay!, min: 0, max: 370) }
        if let v = validUntilTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1440) }
        if let v = validUntilUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if let v = numberOfDaysValid { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = extensionData { try v.encode(to: &encoder) }
    }
}
