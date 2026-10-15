import Foundation

// MARK: - FIP Ticket Data

struct FIPTicketDataV2: ASN1Decodable {
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
    var classCode: TravelClassTypeV2?
    var extensionData: ExtensionDataV2?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 13 optional+default fields; numberOfTravelDays and includesSupplements are mandatory
        let presence = try decoder.decodePresenceBitmap(count: 13)
        var idx = 0

        if presence[idx] { referenceIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { referenceNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { productOwnerNum = try decoder.decodeConstrainedInt(min: 1, max: 32000) }; idx += 1
        if presence[idx] { productOwnerIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { productIdNum = try decoder.decodeConstrainedInt(min: 0, max: 65535) }; idx += 1
        if presence[idx] { productIdIA5 = try decoder.decodeIA5String() }; idx += 1
        // V2: validFromDay is @Asn1Optional only (no @Asn1Default)
        if presence[idx] { validFromDay = try decoder.decodeConstrainedInt(min: -1, max: 700) }; idx += 1
        // V2: validUntilDay is @Asn1Optional only (no @Asn1Default), constraint -1..370
        if presence[idx] { validUntilDay = try decoder.decodeConstrainedInt(min: -1, max: 370) }; idx += 1
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
            classCode = try TravelClassTypeV2(from: &decoder)
        } else {
            classCode = .second
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

// MARK: - FIP Ticket Data Encoding

extension FIPTicketDataV2: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        let classCodePresent = classCode != nil && classCode != .second
        // V2: 13 optional+default fields; numberOfTravelDays and includesSupplements are mandatory
        // V2: validFromDay and validUntilDay are @Asn1Optional only (no @Asn1Default)
        try encoder.encodePresenceBitmap([
            referenceIA5 != nil,
            referenceNum != nil,
            productOwnerNum != nil,
            productOwnerIA5 != nil,
            productIdNum != nil,
            productIdIA5 != nil,
            validFromDay != nil,
            validUntilDay != nil,
            activatedDay != nil,
            carrierNum != nil,
            carrierIA5 != nil,
            // numberOfTravelDays, includesSupplements are mandatory
            classCodePresent,
            extensionData != nil
        ])
        if let v = referenceIA5 { try encoder.encodeIA5String(v) }
        if let v = referenceNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = productOwnerNum { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        if let v = productOwnerIA5 { try encoder.encodeIA5String(v) }
        if let v = productIdNum { try encoder.encodeConstrainedInt(v, min: 0, max: 65535) }
        if let v = productIdIA5 { try encoder.encodeIA5String(v) }
        // V2: validFromDay is @Asn1Optional only (no @Asn1Default)
        if let v = validFromDay { try encoder.encodeConstrainedInt(v, min: -1, max: 700) }
        // V2: validUntilDay is @Asn1Optional only (no @Asn1Default)
        if let v = validUntilDay { try encoder.encodeConstrainedInt(v, min: -1, max: 370) }
        if let v = activatedDay {
            try encoder.encodeLengthDeterminant(v.count)
            for day in v { try encoder.encodeConstrainedInt(day, min: 0, max: 370) }
        }
        if let v = carrierNum {
            try encoder.encodeLengthDeterminant(v.count)
            for num in v { try encoder.encodeConstrainedInt(num, min: 1, max: 32000) }
        }
        if let v = carrierIA5 {
            try encoder.encodeLengthDeterminant(v.count)
            for s in v { try encoder.encodeIA5String(s) }
        }
        // MANDATORY fields
        try encoder.encodeConstrainedInt(numberOfTravelDays, min: 1, max: 200)
        try encoder.encodeBoolean(includesSupplements)
        if classCodePresent { try encoder.encodeEnumerated(classCode!.rawValue, rootCount: TravelClassTypeV2.rootValueCount, hasExtensionMarker: TravelClassTypeV2.hasExtensionMarker) }
        if let v = extensionData { try v.encode(to: &encoder) }
    }
}
