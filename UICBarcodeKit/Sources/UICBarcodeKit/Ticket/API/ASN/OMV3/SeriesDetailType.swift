import Foundation

/// Series detail type
public struct SeriesDetailType: ASN1Decodable {
    public var supplyingCarrier: Int?
    public var offerIdentification: Int?
    public var series: Int?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let presence = try decoder.decodePresenceBitmap(count: 3)

        if presence[0] { supplyingCarrier = try decoder.decodeConstrainedInt(min: 1, max: 32000) }
        if presence[1] { offerIdentification = try decoder.decodeConstrainedInt(min: 1, max: 99) }
        if presence[2] { series = Int(try decoder.decodeUnconstrainedInteger()) }
    }
}

extension SeriesDetailType: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodePresenceBitmap([
            supplyingCarrier != nil,
            offerIdentification != nil,
            series != nil
        ])

        if let v = supplyingCarrier { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        if let v = offerIdentification { try encoder.encodeConstrainedInt(v, min: 1, max: 99) }
        if let v = series { try encoder.encodeUnconstrainedInteger(Int64(v)) }
    }
}
