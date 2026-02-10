import Foundation

struct IncludedOpenTicketTypeV2: ASN1Decodable {
    var productOwnerNum: Int?
    var productOwnerIA5: String?
    var productIdNum: Int?
    var productIdIA5: String?
    var externalIssuerId: Int?
    var issuerAuthorizationId: Int?
    var stationCodeTable: CodeTableTypeV2?
    var validRegion: [RegionalValidityTypeV2]?
    var validFromDay: Int?
    var validFromTime: Int?
    var validFromUTCOffset: Int?
    var validUntilDay: Int?
    var validUntilTime: Int?
    var validUntilUTCOffset: Int?
    var classCode: TravelClassTypeV2?
    var serviceLevel: String?
    var carrierNum: [Int]?
    var carrierIA5: [String]?
    var includedServiceBrands: [Int]?
    var excludedServiceBrands: [Int]?
    var tariffs: [TariffTypeV2]?
    var infoText: String?
    var includedTransportTypes: [Int]?
    var excludedTransportTypes: [Int]?
    var extensionData: ExtensionDataV2?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 25 optional+default fields (stationCodeTable(D), validFromDay(D), validUntilDay(D) = 3 defaults + 22 optional)
        let presence = try decoder.decodePresenceBitmap(count: 25)
        var idx = 0

        if presence[idx] { productOwnerNum = try decoder.decodeConstrainedInt(min: 1, max: 32000) }; idx += 1
        if presence[idx] { productOwnerIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { productIdNum = try decoder.decodeConstrainedInt(min: 0, max: 65535) }; idx += 1
        if presence[idx] { productIdIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { externalIssuerId = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { issuerAuthorizationId = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] {
            stationCodeTable = try CodeTableTypeV2(from: &decoder)
        } else {
            stationCodeTable = .stationUIC
        }; idx += 1
        if presence[idx] { validRegion = try decoder.decodeSequenceOf() }; idx += 1
        if presence[idx] { validFromDay = try decoder.decodeConstrainedInt(min: -1, max: 700) } else { validFromDay = 0 }; idx += 1
        if presence[idx] { validFromTime = try decoder.decodeConstrainedInt(min: 0, max: 1439) }; idx += 1
        if presence[idx] { validFromUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }; idx += 1
        if presence[idx] { validUntilDay = try decoder.decodeConstrainedInt(min: -1, max: 370) } else { validUntilDay = 0 }; idx += 1
        if presence[idx] { validUntilTime = try decoder.decodeConstrainedInt(min: 0, max: 1439) }; idx += 1
        if presence[idx] { validUntilUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }; idx += 1
        if presence[idx] { classCode = try TravelClassTypeV2(from: &decoder) }; idx += 1
        if presence[idx] {
            serviceLevel = try decoder.decodeIA5String(
                constraint: ASN1StringConstraint(type: .ia5String, minLength: 1, maxLength: 2)
            )
        }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            carrierNum = []
            for _ in 0..<count {
                carrierNum?.append(try decoder.decodeConstrainedInt(min: 1, max: 32000))
            }
        }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            carrierIA5 = []
            for _ in 0..<count {
                carrierIA5?.append(try decoder.decodeIA5String())
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
        // V2 order: tariffs(20), infoText(21), includedTransportTypes(22), excludedTransportTypes(23), extension(24)
        if presence[idx] { tariffs = try decoder.decodeSequenceOf() }; idx += 1
        if presence[idx] { infoText = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            includedTransportTypes = []
            for _ in 0..<count {
                includedTransportTypes?.append(try decoder.decodeConstrainedInt(min: 0, max: 31))
            }
        }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            excludedTransportTypes = []
            for _ in 0..<count {
                excludedTransportTypes?.append(try decoder.decodeConstrainedInt(min: 0, max: 31))
            }
        }; idx += 1
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

extension IncludedOpenTicketTypeV2: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        let stationCodeTablePresent = stationCodeTable != nil && stationCodeTable != .stationUIC
        let validFromDayPresent = validFromDay != nil && validFromDay != 0
        let validUntilDayPresent = validUntilDay != nil && validUntilDay != 0
        // V2: 25 optional+default fields
        try encoder.encodePresenceBitmap([
            productOwnerNum != nil,
            productOwnerIA5 != nil,
            productIdNum != nil,
            productIdIA5 != nil,
            externalIssuerId != nil,
            issuerAuthorizationId != nil,
            stationCodeTablePresent,
            validRegion != nil,
            validFromDayPresent,
            validFromTime != nil,
            validFromUTCOffset != nil,
            validUntilDayPresent,
            validUntilTime != nil,
            validUntilUTCOffset != nil,
            classCode != nil,
            serviceLevel != nil,
            carrierNum != nil,
            carrierIA5 != nil,
            includedServiceBrands != nil,
            excludedServiceBrands != nil,
            // V2 order: tariffs, infoText, transport types, extension
            tariffs != nil,
            infoText != nil,
            includedTransportTypes != nil,
            excludedTransportTypes != nil,
            extensionData != nil
        ])
        if let v = productOwnerNum { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        if let v = productOwnerIA5 { try encoder.encodeIA5String(v) }
        if let v = productIdNum { try encoder.encodeConstrainedInt(v, min: 0, max: 65535) }
        if let v = productIdIA5 { try encoder.encodeIA5String(v) }
        if let v = externalIssuerId { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = issuerAuthorizationId { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if stationCodeTablePresent { try encoder.encodeEnumerated(stationCodeTable!.rawValue, rootCount: CodeTableTypeV2.rootValueCount) }
        if let v = validRegion { try encoder.encodeSequenceOf(v) }
        if validFromDayPresent { try encoder.encodeConstrainedInt(validFromDay!, min: -1, max: 700) }
        if let v = validFromTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1439) }
        if let v = validFromUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if validUntilDayPresent { try encoder.encodeConstrainedInt(validUntilDay!, min: -1, max: 370) }
        if let v = validUntilTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1439) }
        if let v = validUntilUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if let v = classCode { try encoder.encodeEnumerated(v.rawValue, rootCount: TravelClassTypeV2.rootValueCount, hasExtensionMarker: TravelClassTypeV2.hasExtensionMarker) }
        if let v = serviceLevel { try encoder.encodeIA5String(v, constraint: ASN1StringConstraint(type: .ia5String, minLength: 1, maxLength: 2)) }
        if let v = carrierNum {
            try encoder.encodeLengthDeterminant(v.count)
            for num in v { try encoder.encodeConstrainedInt(num, min: 1, max: 32000) }
        }
        if let v = carrierIA5 {
            try encoder.encodeLengthDeterminant(v.count)
            for s in v { try encoder.encodeIA5String(s) }
        }
        if let v = includedServiceBrands {
            try encoder.encodeLengthDeterminant(v.count)
            for num in v { try encoder.encodeConstrainedInt(num, min: 0, max: 32000) }
        }
        if let v = excludedServiceBrands {
            try encoder.encodeLengthDeterminant(v.count)
            for num in v { try encoder.encodeConstrainedInt(num, min: 0, max: 32000) }
        }
        // V2 order: tariffs, infoText, transport types, extension
        if let v = tariffs { try encoder.encodeSequenceOf(v) }
        if let v = infoText { try encoder.encodeUTF8String(v) }
        if let v = includedTransportTypes {
            try encoder.encodeLengthDeterminant(v.count)
            for num in v { try encoder.encodeConstrainedInt(num, min: 0, max: 31) }
        }
        if let v = excludedTransportTypes {
            try encoder.encodeLengthDeterminant(v.count)
            for num in v { try encoder.encodeConstrainedInt(num, min: 0, max: 31) }
        }
        if let v = extensionData { try v.encode(to: &encoder) }
    }
}
