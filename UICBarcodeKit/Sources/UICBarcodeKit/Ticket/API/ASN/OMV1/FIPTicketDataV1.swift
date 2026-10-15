import Foundation

// MARK: - FIP Ticket Data

struct FIPTicketDataV1: ASN1Decodable {
    var referenceIA5: String?
    var referenceNum: Int?
    var productOwnerNum: Int?
    var productOwnerIA5: String?
    var productIdNum: Int?
    var productIdIA5: String?
    var validFromDay: Int?
    var validUntilDay: Int?
    var activatedDay: [Int]?
    var carrierNum: [Int]?
    var carrierIA5: [String]?
    var numberOfTravelDays: Int = 1
    var includesSupplements: Bool = false
    var classCode: TravelClassTypeV1?
    var extensionData: ExtensionDataV1?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 12 optional+default fields; numberOfTravelDays and includesSupplements are mandatory
        // referenceIA5, referenceNum, productOwnerNum, productOwnerIA5, productIdNum, productIdIA5 = 6 optional
        // validFromDay(D), validUntilDay(D) = 2 default
        // activatedDay, carrierNum, carrierIA5 = 3 optional
        // classCode(D) = 1 default
        // extensionData = 1 optional
        // Total = 13 optional+default
        let presence = try decoder.decodePresenceBitmap(count: 13)
        var idx = 0

        if presence[idx] { referenceIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { referenceNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { productOwnerNum = try decoder.decodeConstrainedInt(min: 1, max: 32000) }; idx += 1
        if presence[idx] { productOwnerIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { productIdNum = try decoder.decodeConstrainedInt(min: 0, max: 32000) }; idx += 1
        if presence[idx] { productIdIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { validFromDay = try decoder.decodeConstrainedInt(min: -1, max: 700) } else { validFromDay = 0 }; idx += 1
        if presence[idx] { validUntilDay = try decoder.decodeConstrainedInt(min: 0, max: 370) } else { validUntilDay = 0 }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            activatedDay = []
            for _ in 0..<count {
                activatedDay?.append(try decoder.decodeConstrainedInt(min: 0, max: 370))
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

        // numberOfTravelDays is MANDATORY
        numberOfTravelDays = try decoder.decodeConstrainedInt(min: 1, max: 200)
        // includesSupplements is MANDATORY
        includesSupplements = try decoder.decodeBoolean()

        if presence[idx] {
            classCode = try TravelClassTypeV1(from: &decoder)
        } else {
            classCode = .second
        }; idx += 1
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

// MARK: - FIPTicketDataV1 Encoding

extension FIPTicketDataV1: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
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
        if let v = productIdNum { try encoder.encodeConstrainedInt(v, min: 0, max: 32000) }
        if let v = productIdIA5 { try encoder.encodeIA5String(v) }
        if validFromDayPresent { try encoder.encodeConstrainedInt(validFromDay!, min: -1, max: 700) }
        if validUntilDayPresent { try encoder.encodeConstrainedInt(validUntilDay!, min: 0, max: 370) }
        if let arr = activatedDay {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeConstrainedInt(v, min: 0, max: 370) }
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
        if classCodePresent { try encoder.encodeEnumerated(classCode!.rawValue, rootCount: TravelClassTypeV1.rootValueCount, hasExtensionMarker: TravelClassTypeV1.hasExtensionMarker) }
        if let v = extensionData { try v.encode(to: &encoder) }
    }
}
