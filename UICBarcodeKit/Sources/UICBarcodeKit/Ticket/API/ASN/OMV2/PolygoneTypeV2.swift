import Foundation

struct PolygoneTypeV2: ASN1Decodable {
    var firstEdge: GeoCoordinateTypeV2
    var edges: [DeltaCoordinatesV2]

    init(firstEdge: GeoCoordinateTypeV2 = GeoCoordinateTypeV2(), edges: [DeltaCoordinatesV2] = []) {
        self.firstEdge = firstEdge
        self.edges = edges
    }

    init(from decoder: inout UPERDecoder) throws {
        // No extension marker, no optional fields
        firstEdge = try GeoCoordinateTypeV2(from: &decoder)
        edges = try decoder.decodeSequenceOf()
    }
}

extension PolygoneTypeV2: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try firstEdge.encode(to: &encoder)
        try encoder.encodeSequenceOf(edges)
    }
}
