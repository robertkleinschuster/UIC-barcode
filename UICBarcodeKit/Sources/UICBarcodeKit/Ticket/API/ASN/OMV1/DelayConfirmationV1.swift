import Foundation

// MARK: - Delay Confirmation

struct DelayConfirmationV1: ASN1Decodable {
    var referenceIA5: String?
    var referenceNum: Int?
    var trainNum: Int?
    var trainIA5: String?
    var departureYear: Int?
    var departureDay: Int?
    var departureTime: Int?
    var departureUTCOffset: Int?
    var stationCodeTable: CodeTableTypeV1?
    var stationNum: Int?
    var stationIA5: String?
    var delay: Int = 1
    var trainCancelled: Bool = false
    var confirmationType: ConfirmationTypeTypeV1?
    var affectedTickets: [TicketLinkTypeV1]?
    var infoText: String?
    var extensionData: ExtensionDataV1?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 14 optional+default fields; delay and trainCancelled are mandatory
        // referenceIA5, referenceNum, trainNum, trainIA5 = 4 optional
        // departureYear, departureDay, departureTime, departureUTCOffset = 4 optional
        // stationCodeTable(D), stationNum, stationIA5 = 3 (1 default + 2 optional)
        // confirmationType(D), affectedTickets, infoText, extensionData = 4 (1 default + 3 optional)
        // Total = 15 optional+default
        let presence = try decoder.decodePresenceBitmap(count: 15)
        var idx = 0

        if presence[idx] { referenceIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { referenceNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { trainNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { trainIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { departureYear = try decoder.decodeConstrainedInt(min: 2016, max: 2269) }; idx += 1
        if presence[idx] { departureDay = try decoder.decodeConstrainedInt(min: 1, max: 366) }; idx += 1
        if presence[idx] { departureTime = try decoder.decodeConstrainedInt(min: 0, max: 1440) }; idx += 1
        if presence[idx] { departureUTCOffset = try decoder.decodeConstrainedInt(min: -60, max: 60) }; idx += 1
        if presence[idx] {
            stationCodeTable = try CodeTableTypeV1(from: &decoder)
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
            confirmationType = try ConfirmationTypeTypeV1(from: &decoder)
        } else {
            confirmationType = .travelerDelay
        }; idx += 1
        if presence[idx] { affectedTickets = try decoder.decodeSequenceOf() }; idx += 1
        if presence[idx] { infoText = try decoder.decodeUTF8String() }; idx += 1
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

// MARK: - DelayConfirmationV1 Encoding

extension DelayConfirmationV1: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        let stationCodeTablePresent = stationCodeTable != nil && stationCodeTable != .stationUIC
        let confirmationTypePresent = confirmationType != nil && confirmationType != .travelerDelay
        try encoder.encodePresenceBitmap([
            referenceIA5 != nil,
            referenceNum != nil,
            trainNum != nil,
            trainIA5 != nil,
            departureYear != nil,
            departureDay != nil,
            departureTime != nil,
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
        if let v = departureYear { try encoder.encodeConstrainedInt(v, min: 2016, max: 2269) }
        if let v = departureDay { try encoder.encodeConstrainedInt(v, min: 1, max: 366) }
        if let v = departureTime { try encoder.encodeConstrainedInt(v, min: 0, max: 1440) }
        if let v = departureUTCOffset { try encoder.encodeConstrainedInt(v, min: -60, max: 60) }
        if stationCodeTablePresent { try encoder.encodeEnumerated(stationCodeTable!.rawValue, rootCount: CodeTableTypeV1.rootValueCount) }
        if let v = stationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = stationIA5 { try encoder.encodeIA5String(v) }
        try encoder.encodeConstrainedInt(delay, min: 1, max: 999)
        try encoder.encodeBoolean(trainCancelled)
        if confirmationTypePresent { try encoder.encodeEnumerated(confirmationType!.rawValue, rootCount: ConfirmationTypeTypeV1.rootValueCount, hasExtensionMarker: ConfirmationTypeTypeV1.hasExtensionMarker) }
        if let arr = affectedTickets { try encoder.encodeSequenceOf(arr) }
        if let v = infoText { try encoder.encodeUTF8String(v) }
        if let v = extensionData { try v.encode(to: &encoder) }
    }
}
