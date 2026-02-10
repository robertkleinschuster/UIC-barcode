import Foundation

// MARK: - Pass Data

struct PassDataV1: ASN1Decodable {
    var referenceNum: Int?
    var referenceIA5: String?
    var productOwnerNum: Int?
    var productOwnerIA5: String?
    var productIdNum: Int?
    var productIdIA5: String?
    var passType: Int?
    var passDescription: String?
    var classCode: TravelClassTypeV1?
    var validFromDay: Int?
    var validFromTime: Int?
    var validFromUTCOffset: Int?
    var validUntilDay: Int?
    var validUntilTime: Int?
    var validUntilUTCOffset: Int?
    var validityPeriodDetails: ValidityPeriodDetailTypeV1?
    var numberOfValidityDays: Int?
    var numberOfPossibleTrips: Int?
    var numberOfDaysOfTravel: Int?
    var activatedDay: [Int]?
    var countries: [Int]?
    var includedCarrierNum: [Int]?
    var includedCarrierIA5: [String]?
    var excludedCarrierNum: [Int]?
    var excludedCarrierIA5: [String]?
    var includedServiceBrands: [Int]?
    var excludedServiceBrands: [Int]?
    var validRegion: [RegionalValidityTypeV1]?
    var tariffs: [TariffTypeV1]?
    var price: Int?
    var vatDetail: [VatDetailTypeV1]?
    var infoText: String?
    var extensionData: ExtensionDataV1?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 33 optional+default fields (classCode(D), validFromDay(D), validUntilDay(D) + 30 optional)
        // No mandatory fields in this type
        let presence = try decoder.decodePresenceBitmap(count: 33)
        var idx = 0

        if presence[idx] { referenceNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { referenceIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { productOwnerNum = try decoder.decodeConstrainedInt(min: 1, max: 32000) }; idx += 1
        if presence[idx] { productOwnerIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { productIdNum = try decoder.decodeConstrainedInt(min: 0, max: 32000) }; idx += 1
        if presence[idx] { productIdIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { passType = try decoder.decodeConstrainedInt(min: 1, max: 250) }; idx += 1
        if presence[idx] { passDescription = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] {
            classCode = try TravelClassTypeV1(from: &decoder)
        } else {
            classCode = .second
        }; idx += 1
        if presence[idx] { validFromDay = try decoder.decodeConstrainedInt(min: -1, max: 700) } else { validFromDay = 0 }; idx += 1
        if presence[idx] { validFromTime = try decoder.decodeConstrainedInt(min: 0, max: 1440) }; idx += 1
        if presence[idx] { validFromUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }; idx += 1
        if presence[idx] { validUntilDay = try decoder.decodeConstrainedInt(min: 0, max: 370) } else { validUntilDay = 0 }; idx += 1
        if presence[idx] { validUntilTime = try decoder.decodeConstrainedInt(min: 0, max: 1440) }; idx += 1
        if presence[idx] { validUntilUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }; idx += 1
        if presence[idx] { validityPeriodDetails = try ValidityPeriodDetailTypeV1(from: &decoder) }; idx += 1
        if presence[idx] { numberOfValidityDays = try decoder.decodeConstrainedInt(min: 0, max: 370) }; idx += 1
        if presence[idx] { numberOfPossibleTrips = try decoder.decodeConstrainedInt(min: 1, max: 250) }; idx += 1
        if presence[idx] { numberOfDaysOfTravel = try decoder.decodeConstrainedInt(min: 1, max: 250) }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            activatedDay = []
            for _ in 0..<count {
                activatedDay?.append(try decoder.decodeConstrainedInt(min: 0, max: 370))
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
                includedServiceBrands?.append(try decoder.decodeConstrainedInt(min: 0, max: 32000))
            }
        }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            excludedServiceBrands = []
            for _ in 0..<count {
                excludedServiceBrands?.append(try decoder.decodeConstrainedInt(min: 0, max: 32000))
            }
        }; idx += 1
        if presence[idx] { validRegion = try decoder.decodeSequenceOf() }; idx += 1
        if presence[idx] { tariffs = try decoder.decodeSequenceOf() }; idx += 1
        if presence[idx] { price = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { vatDetail = try decoder.decodeSequenceOf() }; idx += 1
        if presence[idx] { infoText = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] { extensionData = try ExtensionDataV1(from: &decoder) }

        if hasExtensions {
            let numExt = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt where extPresence[i] {
                try decoder.skipOpenType()
            }
        }
    }
}

// MARK: - PassDataV1 Encoding

extension PassDataV1: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
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
            vatDetail != nil,
            infoText != nil,
            extensionData != nil
        ])
        if let v = referenceNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = referenceIA5 { try encoder.encodeIA5String(v) }
        if let v = productOwnerNum { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        if let v = productOwnerIA5 { try encoder.encodeIA5String(v) }
        if let v = productIdNum { try encoder.encodeConstrainedInt(v, min: 0, max: 32000) }
        if let v = productIdIA5 { try encoder.encodeIA5String(v) }
        if let v = passType { try encoder.encodeConstrainedInt(v, min: 1, max: 250) }
        if let v = passDescription { try encoder.encodeUTF8String(v) }
        if classCodePresent { try encoder.encodeEnumerated(classCode!.rawValue, rootCount: TravelClassTypeV1.rootValueCount, hasExtensionMarker: TravelClassTypeV1.hasExtensionMarker) }
        if validFromDayPresent { try encoder.encodeConstrainedInt(validFromDay!, min: -1, max: 700) }
        if let v = validFromTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1440) }
        if let v = validFromUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if validUntilDayPresent { try encoder.encodeConstrainedInt(validUntilDay!, min: 0, max: 370) }
        if let v = validUntilTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1440) }
        if let v = validUntilUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if let v = validityPeriodDetails { try v.encode(to: &encoder) }
        if let v = numberOfValidityDays { try encoder.encodeConstrainedInt(v, min: 0, max: 370) }
        if let v = numberOfPossibleTrips { try encoder.encodeConstrainedInt(v, min: 1, max: 250) }
        if let v = numberOfDaysOfTravel { try encoder.encodeConstrainedInt(v, min: 1, max: 250) }
        if let arr = activatedDay {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeConstrainedInt(v, min: 0, max: 370) }
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
            for v in arr { try encoder.encodeConstrainedInt(v, min: 0, max: 32000) }
        }
        if let arr = excludedServiceBrands {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeConstrainedInt(v, min: 0, max: 32000) }
        }
        if let arr = validRegion { try encoder.encodeSequenceOf(arr) }
        if let arr = tariffs { try encoder.encodeSequenceOf(arr) }
        if let v = price { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let arr = vatDetail { try encoder.encodeSequenceOf(arr) }
        if let v = infoText { try encoder.encodeUTF8String(v) }
        if let v = extensionData { try v.encode(to: &encoder) }
    }
}
