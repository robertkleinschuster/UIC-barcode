import Foundation

// MARK: - Parking Ground Data

struct ParkingGroundDataV2: ASN1Decodable {
    var referenceIA5: String?
    var referenceNum: Int?
    var parkingGroundId: String = ""
    var fromParkingDate: Int = 0
    var toParkingDate: Int?
    var productOwnerNum: Int?
    var productOwnerIA5: String?
    var productIdNum: Int?
    var productIdIA5: String?
    var accessCode: String?
    var location: String = ""
    var stationCodeTable: CodeTableTypeV2?
    var stationNum: Int?
    var stationIA5: String?
    var specialInformation: String?
    var entryTrack: String?
    var numberPlate: String?
    var price: Int?
    var vatDetail: [VatDetailTypeV2]?
    var extensionData: ExtensionDataV2?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 17 optional+default fields; parkingGroundId, fromParkingDate, location are mandatory
        let presence = try decoder.decodePresenceBitmap(count: 17)
        var idx = 0

        if presence[idx] { referenceIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { referenceNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1

        // parkingGroundId is MANDATORY
        parkingGroundId = try decoder.decodeIA5String()
        // fromParkingDate is MANDATORY
        fromParkingDate = try decoder.decodeConstrainedInt(min: -1, max: 370)

        if presence[idx] { toParkingDate = try decoder.decodeConstrainedInt(min: 0, max: 370) } else { toParkingDate = 0 }; idx += 1
        if presence[idx] { productOwnerNum = try decoder.decodeConstrainedInt(min: 1, max: 32000) }; idx += 1
        if presence[idx] { productOwnerIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { productIdNum = try decoder.decodeConstrainedInt(min: 0, max: 65535) }; idx += 1
        if presence[idx] { productIdIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { accessCode = try decoder.decodeIA5String() }; idx += 1

        // location is MANDATORY
        location = try decoder.decodeUTF8String()

        if presence[idx] {
            stationCodeTable = try CodeTableTypeV2(from: &decoder)
        } else {
            stationCodeTable = .stationUIC
        }; idx += 1
        if presence[idx] { stationNum = try decoder.decodeConstrainedInt(min: 1, max: 9999999) }; idx += 1
        if presence[idx] { stationIA5 = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] { specialInformation = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] { entryTrack = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] { numberPlate = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { price = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { vatDetail = try decoder.decodeSequenceOf() }; idx += 1
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

// MARK: - Parking Ground Data Encoding

extension ParkingGroundDataV2: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        let stationCodeTablePresent = stationCodeTable != nil && stationCodeTable != .stationUIC
        // V2: toParkingDate (not untilParkingDate), @Asn1Default(0), constraint 0..370
        let toParkingDatePresent = toParkingDate != nil && toParkingDate != 0
        // V2: 17 optional+default fields; parkingGroundId, fromParkingDate, location are mandatory
        try encoder.encodePresenceBitmap([
            referenceIA5 != nil,
            referenceNum != nil,
            // parkingGroundId, fromParkingDate are mandatory
            toParkingDatePresent,
            productOwnerNum != nil,
            productOwnerIA5 != nil,
            productIdNum != nil,
            productIdIA5 != nil,
            accessCode != nil,
            // location is mandatory
            stationCodeTablePresent,
            stationNum != nil,
            stationIA5 != nil,
            specialInformation != nil,
            entryTrack != nil,
            numberPlate != nil,
            price != nil,
            vatDetail != nil,
            extensionData != nil
        ])
        if let v = referenceIA5 { try encoder.encodeIA5String(v) }
        if let v = referenceNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        // parkingGroundId is MANDATORY
        try encoder.encodeIA5String(parkingGroundId)
        // fromParkingDate is MANDATORY
        try encoder.encodeConstrainedInt(fromParkingDate, min: -1, max: 370)
        if toParkingDatePresent { try encoder.encodeConstrainedInt(toParkingDate!, min: 0, max: 370) }
        if let v = productOwnerNum { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        if let v = productOwnerIA5 { try encoder.encodeIA5String(v) }
        if let v = productIdNum { try encoder.encodeConstrainedInt(v, min: 0, max: 65535) }
        if let v = productIdIA5 { try encoder.encodeIA5String(v) }
        if let v = accessCode { try encoder.encodeIA5String(v) }
        // location is MANDATORY
        try encoder.encodeUTF8String(location)
        if stationCodeTablePresent { try encoder.encodeEnumerated(stationCodeTable!.rawValue, rootCount: CodeTableTypeV2.rootValueCount) }
        if let v = stationNum { try encoder.encodeConstrainedInt(v, min: 1, max: 9999999) }
        if let v = stationIA5 { try encoder.encodeUTF8String(v) }
        if let v = specialInformation { try encoder.encodeUTF8String(v) }
        if let v = entryTrack { try encoder.encodeUTF8String(v) }
        if let v = numberPlate { try encoder.encodeIA5String(v) }
        if let v = price { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = vatDetail { try encoder.encodeSequenceOf(v) }
        if let v = extensionData { try v.encode(to: &encoder) }
    }
}
