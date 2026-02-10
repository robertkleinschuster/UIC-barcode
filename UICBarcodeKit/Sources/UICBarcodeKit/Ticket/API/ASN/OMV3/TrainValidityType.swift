import Foundation

public struct TrainValidityType: ASN1Decodable {
    public var validFromDay: Int?
    public var validFromTime: Int?
    public var validFromUTCOffset: Int?
    public var validUntilDay: Int?
    public var validUntilTime: Int?
    public var validUntilUTCOffset: Int?
    public var includedCarriersNum: [Int]?
    public var includedCarriersIA5: [String]?
    public var excludedCarriersNum: [Int]?
    public var excludedCarriersIA5: [String]?
    public var includedServiceBrands: [Int]?
    public var excludedServiceBrands: [Int]?
    public var bordingOrArrival: BoardingOrArrivalType?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        let presence = try decoder.decodePresenceBitmap(count: 13)

        if presence[0] { validFromDay = try decoder.decodeConstrainedInt(min: -1, max: 700) } else { validFromDay = 0 }
        if presence[1] { validFromTime = try decoder.decodeConstrainedInt(min: 0, max: 1439) }
        if presence[2] { validFromUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }
        if presence[3] { validUntilDay = try decoder.decodeConstrainedInt(min: -1, max: 500) } else { validUntilDay = 0 }
        if presence[4] { validUntilTime = try decoder.decodeConstrainedInt(min: 0, max: 1439) }
        if presence[5] { validUntilUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }
        if presence[6] {
            let count = try decoder.decodeLengthDeterminant()
            includedCarriersNum = []
            for _ in 0..<count {
                includedCarriersNum?.append(try decoder.decodeConstrainedInt(min: 1, max: 32000))
            }
        }
        if presence[7] {
            let count = try decoder.decodeLengthDeterminant()
            includedCarriersIA5 = []
            for _ in 0..<count {
                includedCarriersIA5?.append(try decoder.decodeIA5String())
            }
        }
        if presence[8] {
            let count = try decoder.decodeLengthDeterminant()
            excludedCarriersNum = []
            for _ in 0..<count {
                excludedCarriersNum?.append(try decoder.decodeConstrainedInt(min: 1, max: 32000))
            }
        }
        if presence[9] {
            let count = try decoder.decodeLengthDeterminant()
            excludedCarriersIA5 = []
            for _ in 0..<count {
                excludedCarriersIA5?.append(try decoder.decodeIA5String())
            }
        }
        if presence[10] {
            let count = try decoder.decodeLengthDeterminant()
            includedServiceBrands = []
            for _ in 0..<count {
                includedServiceBrands?.append(try decoder.decodeConstrainedInt(min: 1, max: 32000))
            }
        }
        if presence[11] {
            let count = try decoder.decodeLengthDeterminant()
            excludedServiceBrands = []
            for _ in 0..<count {
                excludedServiceBrands?.append(try decoder.decodeConstrainedInt(min: 1, max: 32000))
            }
        }
        if presence[12] {
            let value = try decoder.decodeEnumerated(rootCount: 2, hasExtensionMarker: true)
            bordingOrArrival = BoardingOrArrivalType(rawValue: value)
        } else {
            bordingOrArrival = .boarding
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

extension TrainValidityType: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)

        let validFromDayPresent = validFromDay != nil && validFromDay != 0
        let validUntilDayPresent = validUntilDay != nil && validUntilDay != 0
        let bordingOrArrivalPresent = bordingOrArrival != nil && bordingOrArrival != .boarding

        try encoder.encodePresenceBitmap([
            validFromDayPresent,
            validFromTime != nil,
            validFromUTCOffset != nil,
            validUntilDayPresent,
            validUntilTime != nil,
            validUntilUTCOffset != nil,
            includedCarriersNum != nil,
            includedCarriersIA5 != nil,
            excludedCarriersNum != nil,
            excludedCarriersIA5 != nil,
            includedServiceBrands != nil,
            excludedServiceBrands != nil,
            bordingOrArrivalPresent
        ])

        if validFromDayPresent { try encoder.encodeConstrainedInt(validFromDay!, min: -1, max: 700) }
        if let v = validFromTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1439) }
        if let v = validFromUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if validUntilDayPresent { try encoder.encodeConstrainedInt(validUntilDay!, min: -1, max: 500) }
        if let v = validUntilTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1439) }
        if let v = validUntilUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if let arr = includedCarriersNum {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        }
        if let arr = includedCarriersIA5 {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeIA5String(v) }
        }
        if let arr = excludedCarriersNum {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        }
        if let arr = excludedCarriersIA5 {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeIA5String(v) }
        }
        if let arr = includedServiceBrands {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        }
        if let arr = excludedServiceBrands {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        }
        if bordingOrArrivalPresent { try encoder.encodeEnumerated(bordingOrArrival!.rawValue, rootCount: 2, hasExtensionMarker: true) }
    }
}
