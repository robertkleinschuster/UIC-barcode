import Foundation

/// Control information - matches Java ControlData.java
/// Java has 12 fields (0-11), 6 mandatory, 6 optional
public struct ControlData: ASN1Decodable {
    public var identificationByCardReference: [CardReferenceType]?  // 0: optional
    public var identificationByIdCard: Bool = false                 // 1: MANDATORY
    public var identificationByPassportId: Bool = false             // 2: MANDATORY
    public var identificationItem: Int?                             // 3: optional
    public var passportValidationRequired: Bool = false             // 4: MANDATORY
    public var onlineValidationRequired: Bool = false               // 5: MANDATORY
    public var randomDetailedValidationRequired: Int?               // 6: optional
    public var ageCheckRequired: Bool = false                       // 7: MANDATORY
    public var reductionCardCheckRequired: Bool = false             // 8: MANDATORY
    public var infoText: String?                                    // 9: optional
    public var includedTickets: [TicketLinkType]?                   // 10: optional
    public var extensionData: ExtensionData?                        // 11: optional

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 6 optional fields: 0, 3, 6, 9, 10, 11
        let presence = try decoder.decodePresenceBitmap(count: 6)

        // Field 0: identificationByCardReference (optional)
        if presence[0] { identificationByCardReference = try decoder.decodeSequenceOf() }
        // Field 1: identificationByIdCard (MANDATORY)
        identificationByIdCard = try decoder.decodeBoolean()
        // Field 2: identificationByPassportId (MANDATORY)
        identificationByPassportId = try decoder.decodeBoolean()
        // Field 3: identificationItem (optional)
        if presence[1] { identificationItem = Int(try decoder.decodeUnconstrainedInteger()) }
        // Field 4: passportValidationRequired (MANDATORY)
        passportValidationRequired = try decoder.decodeBoolean()
        // Field 5: onlineValidationRequired (MANDATORY)
        onlineValidationRequired = try decoder.decodeBoolean()
        // Field 6: randomDetailedValidationRequired (optional)
        if presence[2] { randomDetailedValidationRequired = try decoder.decodeConstrainedInt(min: 0, max: 99) }
        // Field 7: ageCheckRequired (MANDATORY)
        ageCheckRequired = try decoder.decodeBoolean()
        // Field 8: reductionCardCheckRequired (MANDATORY)
        reductionCardCheckRequired = try decoder.decodeBoolean()
        // Field 9: infoText (optional)
        if presence[3] { infoText = try decoder.decodeUTF8String() }
        // Field 10: includedTickets (optional)
        if presence[4] { includedTickets = try decoder.decodeSequenceOf() }
        // Field 11: extension (optional)
        if presence[5] { extensionData = try ExtensionData(from: &decoder) }

        if hasExtensions {
            let numExt = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt where extPresence[i] {
                try decoder.skipOpenType()
            }
        }
    }
}

extension ControlData: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        try encoder.encodePresenceBitmap([
            identificationByCardReference != nil,
            identificationItem != nil,
            randomDetailedValidationRequired != nil,
            infoText != nil,
            includedTickets != nil,
            extensionData != nil
        ])
        if let identificationByCardReference { try encoder.encodeSequenceOf(identificationByCardReference) }
        try encoder.encodeBoolean(identificationByIdCard)
        try encoder.encodeBoolean(identificationByPassportId)
        if let identificationItem { try encoder.encodeUnconstrainedInteger(Int64(identificationItem)) }
        try encoder.encodeBoolean(passportValidationRequired)
        try encoder.encodeBoolean(onlineValidationRequired)
        if let randomDetailedValidationRequired { try encoder.encodeConstrainedInt(randomDetailedValidationRequired, min: 0, max: 99) }
        try encoder.encodeBoolean(ageCheckRequired)
        try encoder.encodeBoolean(reductionCardCheckRequired)
        if let infoText { try encoder.encodeUTF8String(infoText) }
        if let includedTickets { try encoder.encodeSequenceOf(includedTickets) }
        if let extensionData { try extensionData.encode(to: &encoder) }
    }
}
