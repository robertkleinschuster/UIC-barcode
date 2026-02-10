import Foundation

// MARK: - Parking Ground Data

/// Parking ground data - FCB v3 all 20 fields
public struct ParkingGroundData: ASN1Decodable {
    public var referenceIA5: String?
    public var referenceNum: Int?
    public var parkingGroundId: String = ""       // MANDATORY, default ""
    public var fromParkingDate: Int = 0           // MANDATORY
    public var toParkingDate: Int?
    public var productOwnerNum: Int?
    public var productOwnerIA5: String?
    public var productIdNum: Int?
    public var productIdIA5: String?
    public var accessCode: String?
    public var location: String = ""              // MANDATORY, UTF8String (not GeoCoordinateType)
    public var stationCodeTable: CodeTableType?
    public var stationNum: Int?
    public var stationIA5: String?                // UTF8String in Java
    public var specialInformation: String?
    public var entryTrack: String?                // UTF8String in Java
    public var numberPlate: String?
    public var price: Int?
    public var vatDetails: [VatDetailType]?
    public var extensionData: ExtensionData?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 17 optional fields (parkingGroundId, fromParkingDate, location are MANDATORY)
        let presence = try decoder.decodePresenceBitmap(count: 17)
        var idx = 0

        if presence[idx] { referenceIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { referenceNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        // Field 2: parkingGroundId (MANDATORY, IA5String, default "")
        parkingGroundId = try decoder.decodeIA5String()
        // Field 3: fromParkingDate (MANDATORY, -367..370)
        fromParkingDate = try decoder.decodeConstrainedInt(min: -367, max: 370)
        // Field 4: toParkingDate (optional, 0..500, default 0)
        if presence[idx] { toParkingDate = try decoder.decodeConstrainedInt(min: 0, max: 500) } else { toParkingDate = 0 }; idx += 1
        if presence[idx] { productOwnerNum = try decoder.decodeConstrainedInt(min: 1, max: 32000) }; idx += 1
        if presence[idx] { productOwnerIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { productIdNum = try decoder.decodeConstrainedInt(min: 0, max: 65535) }; idx += 1
        if presence[idx] { productIdIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { accessCode = try decoder.decodeIA5String() }; idx += 1
        // Field 10: location (MANDATORY, UTF8String)
        location = try decoder.decodeUTF8String()
        // Field 11: stationCodeTable (optional, default stationUIC)
        if presence[idx] {
            let value = try decoder.decodeEnumerated(rootCount: 5)
            stationCodeTable = CodeTableType(rawValue: value)
        } else {
            stationCodeTable = .stationUIC
        }; idx += 1
        if presence[idx] { stationNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        // Field 13: stationIA5 (optional, UTF8String in Java)
        if presence[idx] { stationIA5 = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] { specialInformation = try decoder.decodeUTF8String() }; idx += 1
        // Field 15: entryTrack (optional, UTF8String in Java)
        if presence[idx] { entryTrack = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] { numberPlate = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { price = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { vatDetails = try decoder.decodeSequenceOf() }; idx += 1
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

// MARK: - ParkingGroundData Encoding

extension ParkingGroundData: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)

        let toParkingDatePresent = toParkingDate != nil && toParkingDate != 0
        let stationCodeTablePresent = stationCodeTable != nil && stationCodeTable != .stationUIC

        try encoder.encodePresenceBitmap([
            referenceIA5 != nil,
            referenceNum != nil,
            toParkingDatePresent,
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
            vatDetails != nil,
            extensionData != nil
        ])

        if let v = referenceIA5 { try encoder.encodeIA5String(v) }
        if let v = referenceNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        try encoder.encodeIA5String(parkingGroundId)
        try encoder.encodeConstrainedInt(fromParkingDate, min: -367, max: 370)
        if toParkingDatePresent { try encoder.encodeConstrainedInt(toParkingDate!, min: 0, max: 500) }
        if let v = productOwnerNum { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        if let v = productOwnerIA5 { try encoder.encodeIA5String(v) }
        if let v = productIdNum { try encoder.encodeConstrainedInt(v, min: 0, max: 65535) }
        if let v = productIdIA5 { try encoder.encodeIA5String(v) }
        if let v = accessCode { try encoder.encodeIA5String(v) }
        try encoder.encodeUTF8String(location)
        if stationCodeTablePresent { try encoder.encodeEnumerated(stationCodeTable!.rawValue, rootCount: 5) }
        if let v = stationNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = stationIA5 { try encoder.encodeUTF8String(v) }
        if let v = specialInformation { try encoder.encodeUTF8String(v) }
        if let v = entryTrack { try encoder.encodeUTF8String(v) }
        if let v = numberPlate { try encoder.encodeIA5String(v) }
        if let v = price { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let arr = vatDetails { try encoder.encodeSequenceOf(arr) }
        if let v = extensionData { try v.encode(to: &encoder) }
    }
}
