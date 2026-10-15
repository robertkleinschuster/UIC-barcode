import Foundation

// MARK: - Parking Ground Data

struct ParkingGroundDataV1: ASN1Decodable {
    var referenceIA5: String?
    var referenceNum: Int?
    var parkingGroundId: String = ""
    var fromParkingDate: Int = 0
    var untilParkingDate: Int?
    var productOwnerNum: Int?
    var productOwnerIA5: String?
    var productIdNum: Int?
    var productIdIA5: String?
    var accessCode: String?
    var location: String = ""
    var stationCodeTable: CodeTableTypeV1?
    var stationNum: Int?
    var stationIA5: String?
    var specialInformation: String?
    var entryTrack: String?
    var numberPlate: String?
    var price: Int?
    var vatDetail: [VatDetailTypeV1]?
    var extensionData: ExtensionDataV1?

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
        fromParkingDate = try decoder.decodeConstrainedInt(min: 0, max: 370)

        if presence[idx] { untilParkingDate = try decoder.decodeConstrainedInt(min: -1, max: 370) } else { untilParkingDate = 0 }; idx += 1
        if presence[idx] { productOwnerNum = try decoder.decodeConstrainedInt(min: 0, max: 32000) }; idx += 1
        if presence[idx] { productOwnerIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { productIdNum = try decoder.decodeConstrainedInt(min: 0, max: 32000) }; idx += 1
        if presence[idx] { productIdIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { accessCode = try decoder.decodeIA5String() }; idx += 1

        // location is MANDATORY
        location = try decoder.decodeUTF8String()

        if presence[idx] {
            stationCodeTable = try CodeTableTypeV1(from: &decoder)
        } else {
            stationCodeTable = .stationUIC
        }; idx += 1
        if presence[idx] { stationNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { stationIA5 = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] { specialInformation = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] { entryTrack = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] { numberPlate = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { price = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { vatDetail = try decoder.decodeSequenceOf() }; idx += 1
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

// MARK: - ParkingGroundDataV1 Encoding

extension ParkingGroundDataV1: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        let untilParkingDatePresent = untilParkingDate != nil && untilParkingDate != 0
        let stationCodeTablePresent = stationCodeTable != nil && stationCodeTable != .stationUIC
        try encoder.encodePresenceBitmap([
            referenceIA5 != nil,
            referenceNum != nil,
            untilParkingDatePresent,
            productOwnerNum != nil,
            productOwnerIA5 != nil,
            productIdNum != nil,
            productIdIA5 != nil,
            accessCode != nil,
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
        try encoder.encodeIA5String(parkingGroundId)
        try encoder.encodeConstrainedInt(fromParkingDate, min: 0, max: 370)
        if untilParkingDatePresent { try encoder.encodeConstrainedInt(untilParkingDate!, min: -1, max: 370) }
        if let v = productOwnerNum { try encoder.encodeConstrainedInt(v, min: 0, max: 32000) }
        if let v = productOwnerIA5 { try encoder.encodeIA5String(v) }
        if let v = productIdNum { try encoder.encodeConstrainedInt(v, min: 0, max: 32000) }
        if let v = productIdIA5 { try encoder.encodeIA5String(v) }
        if let v = accessCode { try encoder.encodeIA5String(v) }
        try encoder.encodeUTF8String(location)
        if stationCodeTablePresent { try encoder.encodeEnumerated(stationCodeTable!.rawValue, rootCount: CodeTableTypeV1.rootValueCount) }
        if let v = stationNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = stationIA5 { try encoder.encodeUTF8String(v) }
        if let v = specialInformation { try encoder.encodeUTF8String(v) }
        if let v = entryTrack { try encoder.encodeUTF8String(v) }
        if let v = numberPlate { try encoder.encodeIA5String(v) }
        if let v = price { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let arr = vatDetail { try encoder.encodeSequenceOf(arr) }
        if let v = extensionData { try v.encode(to: &encoder) }
    }
}
