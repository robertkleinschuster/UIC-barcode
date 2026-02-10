import Foundation

// MARK: - Included Open Ticket Type

public struct IncludedOpenTicketType: ASN1Decodable {
    public var productOwnerNum: Int?
    public var productOwnerIA5: String?
    public var productIdNum: Int?
    public var productIdIA5: String?
    public var externalIssuerId: Int?
    public var issuerAutorizationId: Int?
    public var stationCodeTable: CodeTableType?
    public var validRegion: [RegionalValidityType]?
    public var validFromDay: Int?
    public var validFromTime: Int?
    public var validFromUTCOffset: Int?
    public var validUntilDay: Int?
    public var validUntilTime: Int?
    public var validUntilUTCOffset: Int?
    public var classCode: TravelClassType?
    public var serviceLevel: String?
    public var carrierNum: [Int]?
    public var carrierIA5: [String]?
    public var includedServiceBrands: [Int]?
    public var excludedServiceBrands: [Int]?
    public var tariffs: [TariffType]?
    public var infoText: String?
    public var includedTransportTypes: [Int]?
    public var excludedTransportTypes: [Int]?
    public var extensionData: ExtensionData?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        let presence = try decoder.decodePresenceBitmap(count: 25)
        var idx = 0

        if presence[idx] { productOwnerNum = try decoder.decodeConstrainedInt(min: 1, max: 32000) }; idx += 1
        if presence[idx] { productOwnerIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { productIdNum = try decoder.decodeConstrainedInt(min: 0, max: 65535) }; idx += 1
        if presence[idx] { productIdIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { externalIssuerId = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { issuerAutorizationId = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] {
            let value = try decoder.decodeEnumerated(rootCount: 5)
            stationCodeTable = CodeTableType(rawValue: value)
        } else {
            stationCodeTable = .stationUIC
        }; idx += 1
        if presence[idx] { validRegion = try decoder.decodeSequenceOf() }; idx += 1
        if presence[idx] { validFromDay = try decoder.decodeConstrainedInt(min: -367, max: 700) } else { validFromDay = 0 }; idx += 1
        if presence[idx] { validFromTime = try decoder.decodeConstrainedInt(min: 0, max: 1439) }; idx += 1
        if presence[idx] { validFromUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }; idx += 1
        if presence[idx] { validUntilDay = try decoder.decodeConstrainedInt(min: -1, max: 500) } else { validUntilDay = 0 }; idx += 1
        if presence[idx] { validUntilTime = try decoder.decodeConstrainedInt(min: 0, max: 1439) }; idx += 1
        if presence[idx] { validUntilUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }; idx += 1
        // classCode: @Asn1Optional only (NO @Asn1Default in Java IncludedOpenTicketType)
        if presence[idx] {
            let value = try decoder.decodeEnumerated(rootCount: 12, hasExtensionMarker: true)
            classCode = TravelClassType(rawValue: value)
        }; idx += 1
        if presence[idx] { serviceLevel = try decoder.decodeIA5String(constraint: ASN1StringConstraint(type: .ia5String, minLength: 1, maxLength: 2)) }; idx += 1
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

// MARK: - IncludedOpenTicketType Encoding

extension IncludedOpenTicketType: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)

        let stationCodeTablePresent = stationCodeTable != nil && stationCodeTable != .stationUIC
        let validFromDayPresent = validFromDay != nil && validFromDay != 0
        let validUntilDayPresent = validUntilDay != nil && validUntilDay != 0

        try encoder.encodePresenceBitmap([
            productOwnerNum != nil,
            productOwnerIA5 != nil,
            productIdNum != nil,
            productIdIA5 != nil,
            externalIssuerId != nil,
            issuerAutorizationId != nil,
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
        if let v = issuerAutorizationId { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if stationCodeTablePresent { try encoder.encodeEnumerated(stationCodeTable!.rawValue, rootCount: 5) }
        if let arr = validRegion { try encoder.encodeSequenceOf(arr) }
        if validFromDayPresent { try encoder.encodeConstrainedInt(validFromDay!, min: -367, max: 700) }
        if let v = validFromTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1439) }
        if let v = validFromUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if validUntilDayPresent { try encoder.encodeConstrainedInt(validUntilDay!, min: -1, max: 500) }
        if let v = validUntilTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1439) }
        if let v = validUntilUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if let v = classCode { try encoder.encodeEnumerated(v.rawValue, rootCount: 12, hasExtensionMarker: true) }
        if let v = serviceLevel { try encoder.encodeIA5String(v, constraint: ASN1StringConstraint(type: .ia5String, minLength: 1, maxLength: 2)) }
        if let arr = carrierNum {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        }
        if let arr = carrierIA5 {
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
        if let arr = tariffs { try encoder.encodeSequenceOf(arr) }
        if let v = infoText { try encoder.encodeUTF8String(v) }
        if let arr = includedTransportTypes {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeConstrainedInt(v, min: 0, max: 31) }
        }
        if let arr = excludedTransportTypes {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeConstrainedInt(v, min: 0, max: 31) }
        }
        if let v = extensionData { try v.encode(to: &encoder) }
    }
}
