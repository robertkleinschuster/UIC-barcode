import Foundation

struct CompartmentDetailsTypeV1: ASN1Decodable {
    var coachType: Int?
    var compartmentType: Int?
    var specialAllocation: Int?
    var coachTypeDescr: String?
    var compartmentTypeDescr: String?
    var specialAllocationDescr: String?
    var position: CompartmentPositionTypeV1?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 7 optional+default fields (position is @Asn1Default)
        let presence = try decoder.decodePresenceBitmap(count: 7)

        if presence[0] { coachType = try decoder.decodeConstrainedInt(min: 1, max: 99) }
        if presence[1] { compartmentType = try decoder.decodeConstrainedInt(min: 1, max: 99) }
        if presence[2] { specialAllocation = try decoder.decodeConstrainedInt(min: 1, max: 99) }
        if presence[3] { coachTypeDescr = try decoder.decodeUTF8String() }
        if presence[4] { compartmentTypeDescr = try decoder.decodeUTF8String() }
        if presence[5] { specialAllocationDescr = try decoder.decodeUTF8String() }
        if presence[6] {
            position = try CompartmentPositionTypeV1(from: &decoder)
        } else {
            position = .unspecified
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

// MARK: - CompartmentDetailsTypeV1 Encoding

extension CompartmentDetailsTypeV1: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        let positionPresent = position != nil && position != .unspecified
        try encoder.encodePresenceBitmap([
            coachType != nil,
            compartmentType != nil,
            specialAllocation != nil,
            coachTypeDescr != nil,
            compartmentTypeDescr != nil,
            specialAllocationDescr != nil,
            positionPresent
        ])
        if let v = coachType { try encoder.encodeConstrainedInt(v, min: 1, max: 99) }
        if let v = compartmentType { try encoder.encodeConstrainedInt(v, min: 1, max: 99) }
        if let v = specialAllocation { try encoder.encodeConstrainedInt(v, min: 1, max: 99) }
        if let v = coachTypeDescr { try encoder.encodeUTF8String(v) }
        if let v = compartmentTypeDescr { try encoder.encodeUTF8String(v) }
        if let v = specialAllocationDescr { try encoder.encodeUTF8String(v) }
        if positionPresent { try encoder.encodeEnumerated(position!.rawValue, rootCount: CompartmentPositionTypeV1.rootValueCount) }
    }
}
