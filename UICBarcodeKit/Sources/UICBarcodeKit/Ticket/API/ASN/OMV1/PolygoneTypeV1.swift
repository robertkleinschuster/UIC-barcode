import Foundation

struct PolygoneTypeV1: ASN1Decodable {
    var firstEdge: GeoCoordinateTypeV1
    var edges: [DeltaCoordinatesV1]

    init(firstEdge: GeoCoordinateTypeV1 = GeoCoordinateTypeV1(), edges: [DeltaCoordinatesV1] = []) {
        self.firstEdge = firstEdge
        self.edges = edges
    }

    init(from decoder: inout UPERDecoder) throws {
        // No extension marker, no optional fields
        firstEdge = try GeoCoordinateTypeV1(from: &decoder)
        edges = try decoder.decodeSequenceOf()
    }
}

// MARK: - PolygoneTypeV1 Encoding

extension PolygoneTypeV1: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try firstEdge.encode(to: &encoder)
        try encoder.encodeSequenceOf(edges)
    }
}
