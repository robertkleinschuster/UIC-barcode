import Foundation

// MARK: - Delay Confirmation

/// Delay confirmation - FCB v3: 15 optional fields + 2 mandatory (delay, trainCancelled)
public struct DelayConfirmation: ASN1Decodable {
    public var referenceIA5: String?
    public var referenceNum: Int?
    public var trainNum: Int?
    public var trainIA5: String?
    public var plannedArrivalYear: Int?
    public var plannedArrivalDay: Int?
    public var plannedArrivalTime: Int?
    public var departureUTCOffset: Int?
    public var stationCodeTable: CodeTableType?
    public var stationNum: Int?
    public var stationIA5: String?
    public var delay: Int = 0
    public var trainCancelled: Bool = false
    public var confirmationType: ConfirmationTypeType?
    public var affectedTickets: [TicketLinkType]?
    public var infoText: String?
    public var extensionData: ExtensionData?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        let optionalCount = 15
        let presence = try decoder.decodePresenceBitmap(count: optionalCount)
        var idx = 0

        if presence[idx] { referenceIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { referenceNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { trainNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { trainIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { plannedArrivalYear = try decoder.decodeConstrainedInt(min: 2016, max: 2269) }; idx += 1
        if presence[idx] { plannedArrivalDay = try decoder.decodeConstrainedInt(min: 1, max: 366) }; idx += 1
        if presence[idx] { plannedArrivalTime = try decoder.decodeConstrainedInt(min: 0, max: 1439) }; idx += 1
        if presence[idx] { departureUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }; idx += 1
        if presence[idx] {
            let value = try decoder.decodeEnumerated(rootCount: 5)
            stationCodeTable = CodeTableType(rawValue: value)
        } else {
            stationCodeTable = .stationUIC
        }; idx += 1
        if presence[idx] { stationNum = try decoder.decodeConstrainedInt(min: 1, max: 9999999) }; idx += 1
        if presence[idx] { stationIA5 = try decoder.decodeIA5String() }; idx += 1
        // delay is MANDATORY (not guarded by presence bit)
        delay = try decoder.decodeConstrainedInt(min: 1, max: 999)
        // trainCancelled is MANDATORY (not guarded by presence bit)
        trainCancelled = try decoder.decodeBoolean()
        if presence[idx] {
            let value = try decoder.decodeEnumerated(rootCount: 3, hasExtensionMarker: true)
            confirmationType = ConfirmationTypeType(rawValue: value)
        } else {
            confirmationType = .travelerDelayConfirmation
        }; idx += 1
        if presence[idx] { affectedTickets = try decoder.decodeSequenceOf() }; idx += 1
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

// MARK: - DelayConfirmation Encoding

extension DelayConfirmation: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)

        let stationCodeTablePresent = stationCodeTable != nil && stationCodeTable != .stationUIC
        let confirmationTypePresent = confirmationType != nil && confirmationType != .travelerDelayConfirmation

        try encoder.encodePresenceBitmap([
            referenceIA5 != nil,
            referenceNum != nil,
            trainNum != nil,
            trainIA5 != nil,
            plannedArrivalYear != nil,
            plannedArrivalDay != nil,
            plannedArrivalTime != nil,
            departureUTCOffset != nil,
            stationCodeTablePresent,
            stationNum != nil,
            stationIA5 != nil,
            confirmationTypePresent,
            affectedTickets != nil,
            infoText != nil,
            extensionData != nil
        ])

        if let v = referenceIA5 { try encoder.encodeIA5String(v) }
        if let v = referenceNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = trainNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = trainIA5 { try encoder.encodeIA5String(v) }
        if let v = plannedArrivalYear { try encoder.encodeConstrainedInt(v, min: 2016, max: 2269) }
        if let v = plannedArrivalDay { try encoder.encodeConstrainedInt(v, min: 1, max: 366) }
        if let v = plannedArrivalTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1439) }
        if let v = departureUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if stationCodeTablePresent { try encoder.encodeEnumerated(stationCodeTable!.rawValue, rootCount: 5) }
        if let v = stationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = stationIA5 { try encoder.encodeIA5String(v) }
        try encoder.encodeConstrainedInt(delay, min: 1, max: 999)
        try encoder.encodeBoolean(trainCancelled)
        if confirmationTypePresent { try encoder.encodeEnumerated(confirmationType!.rawValue, rootCount: 3, hasExtensionMarker: true) }
        if let arr = affectedTickets { try encoder.encodeSequenceOf(arr) }
        if let v = infoText { try encoder.encodeUTF8String(v) }
        if let v = extensionData { try v.encode(to: &encoder) }
    }
}
