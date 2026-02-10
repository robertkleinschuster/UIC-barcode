import Foundation

// MARK: - Pass Data

/// Pass ticket data - FCB v3 all 34 fields
public struct PassData: ASN1Decodable {
    public var referenceNum: Int?
    public var referenceIA5: String?
    public var productOwnerNum: Int?
    public var productOwnerIA5: String?
    public var productIdNum: Int?
    public var productIdIA5: String?
    public var passType: Int?
    public var passDescription: String?
    public var classCode: TravelClassType?
    public var validFromDay: Int?
    public var validFromTime: Int?
    public var validFromUTCOffset: Int?
    public var validUntilDay: Int?
    public var validUntilTime: Int?
    public var validUntilUTCOffset: Int?
    public var validityPeriodDetails: ValidityPeriodDetailType?
    public var numberOfValidityDays: Int?
    public var trainValidity: TrainValidityType?
    public var numberOfPossibleTrips: Int?
    public var numberOfDaysOfTravel: Int?
    public var activatedDay: [Int]?
    public var countries: [Int]?
    public var includedCarrierNum: [Int]?
    public var includedCarrierIA5: [String]?
    public var excludedCarrierNum: [Int]?
    public var excludedCarrierIA5: [String]?
    public var includedServiceBrands: [Int]?
    public var excludedServiceBrands: [Int]?
    public var validRegion: [RegionalValidityType]?
    public var tariffs: [TariffType]?
    public var price: Int?
    public var vatDetails: [VatDetailType]?
    public var infoText: String?
    public var extensionData: ExtensionData?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        let optionalCount = 34
        let presence = try decoder.decodePresenceBitmap(count: optionalCount)
        var idx = 0

        if presence[idx] { referenceNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { referenceIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { productOwnerNum = try decoder.decodeConstrainedInt(min: 1, max: 32000) }; idx += 1
        if presence[idx] { productOwnerIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { productIdNum = try decoder.decodeConstrainedInt(min: 0, max: 65535) }; idx += 1
        if presence[idx] { productIdIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { passType = try decoder.decodeConstrainedInt(min: 1, max: 250) }; idx += 1
        if presence[idx] { passDescription = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] {
            let value = try decoder.decodeEnumerated(rootCount: 12, hasExtensionMarker: true)
            classCode = TravelClassType(rawValue: value)
        } else {
            classCode = .second
        }; idx += 1
        if presence[idx] { validFromDay = try decoder.decodeConstrainedInt(min: -367, max: 700) } else { validFromDay = 0 }; idx += 1
        if presence[idx] { validFromTime = try decoder.decodeConstrainedInt(min: 0, max: 1439) }; idx += 1
        if presence[idx] { validFromUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }; idx += 1
        if presence[idx] { validUntilDay = try decoder.decodeConstrainedInt(min: -1, max: 500) } else { validUntilDay = 0 }; idx += 1
        if presence[idx] { validUntilTime = try decoder.decodeConstrainedInt(min: 0, max: 1439) }; idx += 1
        if presence[idx] { validUntilUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }; idx += 1
        if presence[idx] { validityPeriodDetails = try ValidityPeriodDetailType(from: &decoder) }; idx += 1
        if presence[idx] { numberOfValidityDays = try decoder.decodeConstrainedInt(min: 0, max: 500) }; idx += 1
        if presence[idx] { trainValidity = try TrainValidityType(from: &decoder) }; idx += 1
        if presence[idx] { numberOfPossibleTrips = try decoder.decodeConstrainedInt(min: 1, max: 250) }; idx += 1
        if presence[idx] { numberOfDaysOfTravel = try decoder.decodeConstrainedInt(min: 1, max: 250) }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            activatedDay = []
            for _ in 0..<count {
                activatedDay?.append(try decoder.decodeConstrainedInt(min: 0, max: 500))
            }
        }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            countries = []
            for _ in 0..<count {
                countries?.append(try decoder.decodeConstrainedInt(min: 1, max: 250))
            }
        }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            includedCarrierNum = []
            for _ in 0..<count {
                includedCarrierNum?.append(try decoder.decodeConstrainedInt(min: 1, max: 32000))
            }
        }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            includedCarrierIA5 = []
            for _ in 0..<count {
                includedCarrierIA5?.append(try decoder.decodeIA5String())
            }
        }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            excludedCarrierNum = []
            for _ in 0..<count {
                excludedCarrierNum?.append(try decoder.decodeConstrainedInt(min: 1, max: 32000))
            }
        }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            excludedCarrierIA5 = []
            for _ in 0..<count {
                excludedCarrierIA5?.append(try decoder.decodeIA5String())
            }
        }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            includedServiceBrands = []
            for _ in 0..<count {
                includedServiceBrands?.append(try decoder.decodeConstrainedInt(min: 1, max: 32000))
            }
        }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            excludedServiceBrands = []
            for _ in 0..<count {
                excludedServiceBrands?.append(try decoder.decodeConstrainedInt(min: 1, max: 32000))
            }
        }; idx += 1
        if presence[idx] { validRegion = try decoder.decodeSequenceOf() }; idx += 1
        if presence[idx] { tariffs = try decoder.decodeSequenceOf() }; idx += 1
        if presence[idx] { price = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { vatDetails = try decoder.decodeSequenceOf() }; idx += 1
        if presence[idx] { infoText = try decoder.decodeUTF8String() }; idx += 1
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

// MARK: - PassData Encoding

extension PassData: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)

        let classCodePresent = classCode != nil && classCode != .second
        let validFromDayPresent = validFromDay != nil && validFromDay != 0
        let validUntilDayPresent = validUntilDay != nil && validUntilDay != 0

        try encoder.encodePresenceBitmap([
            referenceNum != nil,
            referenceIA5 != nil,
            productOwnerNum != nil,
            productOwnerIA5 != nil,
            productIdNum != nil,
            productIdIA5 != nil,
            passType != nil,
            passDescription != nil,
            classCodePresent,
            validFromDayPresent,
            validFromTime != nil,
            validFromUTCOffset != nil,
            validUntilDayPresent,
            validUntilTime != nil,
            validUntilUTCOffset != nil,
            validityPeriodDetails != nil,
            numberOfValidityDays != nil,
            trainValidity != nil,
            numberOfPossibleTrips != nil,
            numberOfDaysOfTravel != nil,
            activatedDay != nil,
            countries != nil,
            includedCarrierNum != nil,
            includedCarrierIA5 != nil,
            excludedCarrierNum != nil,
            excludedCarrierIA5 != nil,
            includedServiceBrands != nil,
            excludedServiceBrands != nil,
            validRegion != nil,
            tariffs != nil,
            price != nil,
            vatDetails != nil,
            infoText != nil,
            extensionData != nil
        ])

        if let v = referenceNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = referenceIA5 { try encoder.encodeIA5String(v) }
        if let v = productOwnerNum { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        if let v = productOwnerIA5 { try encoder.encodeIA5String(v) }
        if let v = productIdNum { try encoder.encodeConstrainedInt(v, min: 0, max: 65535) }
        if let v = productIdIA5 { try encoder.encodeIA5String(v) }
        if let v = passType { try encoder.encodeConstrainedInt(v, min: 1, max: 250) }
        if let v = passDescription { try encoder.encodeUTF8String(v) }
        if classCodePresent { try encoder.encodeEnumerated(classCode!.rawValue, rootCount: 12, hasExtensionMarker: true) }
        if validFromDayPresent { try encoder.encodeConstrainedInt(validFromDay!, min: -367, max: 700) }
        if let v = validFromTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1439) }
        if let v = validFromUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if validUntilDayPresent { try encoder.encodeConstrainedInt(validUntilDay!, min: -1, max: 500) }
        if let v = validUntilTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1439) }
        if let v = validUntilUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if let v = validityPeriodDetails { try v.encode(to: &encoder) }
        if let v = numberOfValidityDays { try encoder.encodeConstrainedInt(v, min: 0, max: 500) }
        if let v = trainValidity { try v.encode(to: &encoder) }
        if let v = numberOfPossibleTrips { try encoder.encodeConstrainedInt(v, min: 1, max: 250) }
        if let v = numberOfDaysOfTravel { try encoder.encodeConstrainedInt(v, min: 1, max: 250) }
        if let arr = activatedDay {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeConstrainedInt(v, min: 0, max: 500) }
        }
        if let arr = countries {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeConstrainedInt(v, min: 1, max: 250) }
        }
        if let arr = includedCarrierNum {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        }
        if let arr = includedCarrierIA5 {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeIA5String(v) }
        }
        if let arr = excludedCarrierNum {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        }
        if let arr = excludedCarrierIA5 {
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
        if let arr = validRegion { try encoder.encodeSequenceOf(arr) }
        if let arr = tariffs { try encoder.encodeSequenceOf(arr) }
        if let v = price { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let arr = vatDetails { try encoder.encodeSequenceOf(arr) }
        if let v = infoText { try encoder.encodeUTF8String(v) }
        if let v = extensionData { try v.encode(to: &encoder) }
    }
}
