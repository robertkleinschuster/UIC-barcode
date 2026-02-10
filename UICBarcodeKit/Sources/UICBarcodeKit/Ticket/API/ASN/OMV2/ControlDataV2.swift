import Foundation

struct ControlDataV2: ASN1Decodable {
    static let hasExtensionMarker = true
    static let optionalFieldCount = 6

    var identificationByCardReference: [CardReferenceTypeV2]?
    var identificationByIdCard: Bool = false
    var identificationByPassportId: Bool = false
    var identificationItem: Int?
    var passportValidationRequired: Bool = false
    var onlineValidationRequired: Bool = false
    var randomDetailedValidationRequired: Int?
    var ageCheckRequired: Bool = false
    var reductionCardCheckRequired: Bool = false
    var infoText: String?
    var includedTickets: [TicketLinkTypeV2]?
    var extensionData: ExtensionDataV2?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 6 optional fields: identificationByCardReference, identificationItem,
        // randomDetailedValidationRequired, infoText, includedTickets, extensionData
        let presence = try decoder.decodePresenceBitmap(count: Self.optionalFieldCount)

        if presence[0] { identificationByCardReference = try decoder.decodeSequenceOf() }
        identificationByIdCard = try decoder.decodeBoolean()
        identificationByPassportId = try decoder.decodeBoolean()
        if presence[1] { identificationItem = Int(try decoder.decodeUnconstrainedInteger()) }
        passportValidationRequired = try decoder.decodeBoolean()
        onlineValidationRequired = try decoder.decodeBoolean()
        if presence[2] { randomDetailedValidationRequired = try decoder.decodeConstrainedInt(min: 0, max: 99) }
        ageCheckRequired = try decoder.decodeBoolean()
        reductionCardCheckRequired = try decoder.decodeBoolean()
        if presence[3] { infoText = try decoder.decodeUTF8String() }
        if presence[4] { includedTickets = try decoder.decodeSequenceOf() }
        if presence[5] { extensionData = try ExtensionDataV2(from: &decoder) }

        if hasExtensions {
            let numExt = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt where extPresence[i] {
                try decoder.skipOpenType()
            }
        }
    }
}

extension ControlDataV2: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        try encoder.encodePresenceBitmap([
            identificationByCardReference != nil,
            identificationItem != nil,
            randomDetailedValidationRequired != nil,
            infoText != nil,
            includedTickets != nil,
            extensionData != nil
        ])
        if let v = identificationByCardReference { try encoder.encodeSequenceOf(v) }
        try encoder.encodeBoolean(identificationByIdCard)
        try encoder.encodeBoolean(identificationByPassportId)
        if let v = identificationItem { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        try encoder.encodeBoolean(passportValidationRequired)
        try encoder.encodeBoolean(onlineValidationRequired)
        if let v = randomDetailedValidationRequired { try encoder.encodeConstrainedInt(v, min: 0, max: 99) }
        try encoder.encodeBoolean(ageCheckRequired)
        try encoder.encodeBoolean(reductionCardCheckRequired)
        if let v = infoText { try encoder.encodeUTF8String(v) }
        if let v = includedTickets { try encoder.encodeSequenceOf(v) }
        if let v = extensionData { try v.encode(to: &encoder) }
    }
}
