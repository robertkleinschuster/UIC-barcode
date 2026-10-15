import Foundation

// MARK: - FIP Ticket Data

/// FIP ticket data - FCB v3 all 15 fields
public struct FIPTicketData: ASN1Decodable {
    public var referenceIA5: String?
    public var referenceNum: Int?
    public var productOwnerNum: Int?
    public var productOwnerIA5: String?
    public var productIdNum: Int?
    public var productIdIA5: String?
    public var validFromDay: Int?
    public var validUntilDay: Int?
    public var activatedDay: [Int]?
    public var carrierNum: [Int]?
    public var carrierIA5: [String]?
    public var numberOfTravelDays: Int = 0        // MANDATORY
    public var includesSupplements: Bool = false   // MANDATORY
    public var classCode: TravelClassType?
    public var extensionData: ExtensionData?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 13 optional fields (numberOfTravelDays, includesSupplements are MANDATORY)
        let presence = try decoder.decodePresenceBitmap(count: 13)
        var idx = 0

        if presence[idx] { referenceIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { referenceNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { productOwnerNum = try decoder.decodeConstrainedInt(min: 1, max: 32000) }; idx += 1
        if presence[idx] { productOwnerIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { productIdNum = try decoder.decodeConstrainedInt(min: 0, max: 65535) }; idx += 1
        if presence[idx] { productIdIA5 = try decoder.decodeIA5String() }; idx += 1
        // Field 6: validFromDay (optional, -367..700, default 0)
        if presence[idx] { validFromDay = try decoder.decodeConstrainedInt(min: -367, max: 700) } else { validFromDay = 0 }; idx += 1
        // Field 7: validUntilDay (optional, -1..500, default 0)
        if presence[idx] { validUntilDay = try decoder.decodeConstrainedInt(min: -1, max: 500) } else { validUntilDay = 0 }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            activatedDay = []
            for _ in 0..<count {
                activatedDay?.append(try decoder.decodeConstrainedInt(min: 0, max: 500))
            }
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
        // Field 11: numberOfTravelDays (MANDATORY, 1..200)
        numberOfTravelDays = try decoder.decodeConstrainedInt(min: 1, max: 200)
        // Field 12: includesSupplements (MANDATORY, Boolean)
        includesSupplements = try decoder.decodeBoolean()
        // Field 13: classCode (optional, default second)
        if presence[idx] {
            let value = try decoder.decodeEnumerated(rootCount: 12, hasExtensionMarker: true)
            classCode = TravelClassType(rawValue: value)
        } else {
            classCode = .second
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

// MARK: - FIPTicketData Encoding

extension FIPTicketData: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)

        let validFromDayPresent = validFromDay != nil && validFromDay != 0
        let validUntilDayPresent = validUntilDay != nil && validUntilDay != 0
        let classCodePresent = classCode != nil && classCode != .second

        try encoder.encodePresenceBitmap([
            referenceIA5 != nil,
            referenceNum != nil,
            productOwnerNum != nil,
            productOwnerIA5 != nil,
            productIdNum != nil,
            productIdIA5 != nil,
            validFromDayPresent,
            validUntilDayPresent,
            activatedDay != nil,
            carrierNum != nil,
            carrierIA5 != nil,
            classCodePresent,
            extensionData != nil
        ])

        if let v = referenceIA5 { try encoder.encodeIA5String(v) }
        if let v = referenceNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = productOwnerNum { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        if let v = productOwnerIA5 { try encoder.encodeIA5String(v) }
        if let v = productIdNum { try encoder.encodeConstrainedInt(v, min: 0, max: 65535) }
        if let v = productIdIA5 { try encoder.encodeIA5String(v) }
        if validFromDayPresent { try encoder.encodeConstrainedInt(validFromDay!, min: -367, max: 700) }
        if validUntilDayPresent { try encoder.encodeConstrainedInt(validUntilDay!, min: -1, max: 500) }
        if let arr = activatedDay {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeConstrainedInt(v, min: 0, max: 500) }
        }
        if let arr = carrierNum {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        }
        if let arr = carrierIA5 {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeIA5String(v) }
        }
        try encoder.encodeConstrainedInt(numberOfTravelDays, min: 1, max: 200)
        try encoder.encodeBoolean(includesSupplements)
        if classCodePresent { try encoder.encodeEnumerated(classCode!.rawValue, rootCount: 12, hasExtensionMarker: true) }
        if let v = extensionData { try v.encode(to: &encoder) }
    }
}
