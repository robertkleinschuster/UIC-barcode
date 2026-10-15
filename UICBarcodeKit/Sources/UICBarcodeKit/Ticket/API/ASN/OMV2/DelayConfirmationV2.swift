import Foundation

// MARK: - Delay Confirmation

struct DelayConfirmationV2: ASN1Decodable {
    var referenceIA5: String?
    var referenceNum: Int?
    var trainNum: Int?
    var trainIA5: String?
    // V2: uses plannedArrival* fields (not departure* like V3)
    var plannedArrivalYear: Int?
    var plannedArrivalDay: Int?
    var plannedArrivalTime: Int?
    var departureUTCOffset: Int?
    var stationCodeTable: CodeTableTypeV2?
    var stationNum: Int?
    var stationIA5: String?
    var delay: Int = 1
    var trainCancelled: Bool = false
    var confirmationType: ConfirmationTypeTypeV2?
    var affectedTickets: [TicketLinkTypeV2]?
    var infoText: String?
    var extensionData: ExtensionDataV2?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 15 optional+default fields; delay and trainCancelled are mandatory
        let presence = try decoder.decodePresenceBitmap(count: 15)
        var idx = 0

        if presence[idx] { referenceIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { referenceNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { trainNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { trainIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { plannedArrivalYear = try decoder.decodeConstrainedInt(min: 2016, max: 2269) }; idx += 1
        if presence[idx] { plannedArrivalDay = try decoder.decodeConstrainedInt(min: 1, max: 366) }; idx += 1
        // V2: plannedArrivalTime constraint 0..1439
        if presence[idx] { plannedArrivalTime = try decoder.decodeConstrainedInt(min: 0, max: 1439) }; idx += 1
        if presence[idx] { departureUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }; idx += 1
        if presence[idx] {
            stationCodeTable = try CodeTableTypeV2(from: &decoder)
        } else {
            stationCodeTable = .stationUIC
        }; idx += 1
        if presence[idx] { stationNum = try decoder.decodeConstrainedInt(min: 1, max: 9999999) }; idx += 1
        if presence[idx] { stationIA5 = try decoder.decodeIA5String() }; idx += 1

        // delay is MANDATORY
        delay = try decoder.decodeConstrainedInt(min: 1, max: 999)
        // trainCancelled is MANDATORY
        trainCancelled = try decoder.decodeBoolean()

        if presence[idx] {
            confirmationType = try ConfirmationTypeTypeV2(from: &decoder)
        } else {
            confirmationType = .travelerDelay
        }; idx += 1
        if presence[idx] { affectedTickets = try decoder.decodeSequenceOf() }; idx += 1
        if presence[idx] { infoText = try decoder.decodeUTF8String() }; idx += 1
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

// MARK: - Delay Confirmation Encoding

extension DelayConfirmationV2: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        let stationCodeTablePresent = stationCodeTable != nil && stationCodeTable != .stationUIC
        let confirmationTypePresent = confirmationType != nil && confirmationType != .travelerDelay
        // V2: 15 optional+default fields; delay and trainCancelled are mandatory
        // V2: uses plannedArrival* fields (not departure* like V3)
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
            // delay, trainCancelled are mandatory
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
        if stationCodeTablePresent { try encoder.encodeEnumerated(stationCodeTable!.rawValue, rootCount: CodeTableTypeV2.rootValueCount) }
        if let v = stationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = stationIA5 { try encoder.encodeIA5String(v) }
        // MANDATORY fields
        try encoder.encodeConstrainedInt(delay, min: 1, max: 999)
        try encoder.encodeBoolean(trainCancelled)
        if confirmationTypePresent { try encoder.encodeEnumerated(confirmationType!.rawValue, rootCount: ConfirmationTypeTypeV2.rootValueCount, hasExtensionMarker: ConfirmationTypeTypeV2.hasExtensionMarker) }
        if let v = affectedTickets { try encoder.encodeSequenceOf(v) }
        if let v = infoText { try encoder.encodeUTF8String(v) }
        if let v = extensionData { try v.encode(to: &encoder) }
    }
}
