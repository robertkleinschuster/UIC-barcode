import Foundation

/// Places type - matches Java PlacesType.java (5 optional fields, NO extension marker)
public struct PlacesType: ASN1Decodable {
    public var coach: String?
    public var placeString: String?
    public var placeDescription: String?
    public var placeIA5: [String]?
    public var placeNum: [Int]?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
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

extension PlacesType: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
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
