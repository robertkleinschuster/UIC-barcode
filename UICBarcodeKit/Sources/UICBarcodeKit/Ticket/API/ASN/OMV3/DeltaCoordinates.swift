import Foundation

public struct DeltaCoordinates: ASN1Decodable {
    public var longitude: Int
    public var latitude: Int

    public init(longitude: Int = 0, latitude: Int = 0) {
        self.longitude = longitude
        self.latitude = latitude
    }

    public init(from decoder: inout UPERDecoder) throws {
        longitude = Int(try decoder.decodeUnconstrainedInteger())
        latitude = Int(try decoder.decodeUnconstrainedInteger())
    }
}

extension DeltaCoordinates: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeUnconstrainedInteger(Int64(longitude))
        try encoder.encodeUnconstrainedInteger(Int64(latitude))
    }
}
