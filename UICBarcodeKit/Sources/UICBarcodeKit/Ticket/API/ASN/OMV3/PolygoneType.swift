import Foundation

public struct PolygoneType: ASN1Decodable {
    public var firstEdge: GeoCoordinateType
    public var edges: [DeltaCoordinates]

    public init(firstEdge: GeoCoordinateType = GeoCoordinateType(), edges: [DeltaCoordinates] = []) {
        self.firstEdge = firstEdge
        self.edges = edges
    }

    public init(from decoder: inout UPERDecoder) throws {
        firstEdge = try GeoCoordinateType(from: &decoder)
        edges = try decoder.decodeSequenceOf()
    }
}

extension PolygoneType: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try firstEdge.encode(to: &encoder)
        try encoder.encodeSequenceOf(edges)
    }
}
