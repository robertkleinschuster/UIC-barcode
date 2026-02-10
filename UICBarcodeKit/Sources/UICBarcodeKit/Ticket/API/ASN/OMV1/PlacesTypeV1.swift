import Foundation

struct PlacesTypeV1: ASN1Decodable {
    var coach: String?
    var placeString: String?
    var placeDescription: String?
    var placeIA5: [String]?
    var placeNum: [Int]?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        // No extension marker
        let presence = try decoder.decodePresenceBitmap(count: 5)

        if presence[0] { coach = try decoder.decodeIA5String() }
        if presence[1] { placeString = try decoder.decodeIA5String() }
        if presence[2] { placeDescription = try decoder.decodeUTF8String() }
        if presence[3] {
            let count = try decoder.decodeLengthDeterminant()
            placeIA5 = []
            for _ in 0..<count {
                placeIA5?.append(try decoder.decodeIA5String())
            }
        }
        if presence[4] {
            let count = try decoder.decodeLengthDeterminant()
            placeNum = []
            for _ in 0..<count {
                placeNum?.append(try decoder.decodeConstrainedInt(min: 1, max: 254))
            }
        }
    }
}

// MARK: - PlacesTypeV1 Encoding

extension PlacesTypeV1: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodePresenceBitmap([
            coach != nil,
            placeString != nil,
            placeDescription != nil,
            placeIA5 != nil,
            placeNum != nil
        ])
        if let v = coach { try encoder.encodeIA5String(v) }
        if let v = placeString { try encoder.encodeIA5String(v) }
        if let v = placeDescription { try encoder.encodeUTF8String(v) }
        if let arr = placeIA5 {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeIA5String(v) }
        }
        if let arr = placeNum {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeConstrainedInt(v, min: 1, max: 254) }
        }
    }
}
