import Foundation

struct GeoCoordinateTypeV1: ASN1Decodable {
    static let optionalFieldCount = 5

    var geoUnit: GeoUnitTypeV1?
    var coordinateSystem: GeoCoordinateSystemTypeV1?
    var hemisphereLongitude: HemisphereLongitudeTypeV1?
    var hemisphereLatitude: HemisphereLatitudeTypeV1?
    var longitude: Int = 0
    var latitude: Int = 0
    var accuracy: GeoUnitTypeV1?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        // No extension marker in Java GeoCoordinateType v1
        let presence = try decoder.decodePresenceBitmap(count: Self.optionalFieldCount)

        if presence[0] {
            geoUnit = try GeoUnitTypeV1(from: &decoder)
        } else {
            geoUnit = .milliDegree
        }
        if presence[1] {
            coordinateSystem = try GeoCoordinateSystemTypeV1(from: &decoder)
        } else {
            coordinateSystem = .wgs84
        }
        if presence[2] {
            hemisphereLongitude = try HemisphereLongitudeTypeV1(from: &decoder)
        } else {
            hemisphereLongitude = .east
        }
        if presence[3] {
            hemisphereLatitude = try HemisphereLatitudeTypeV1(from: &decoder)
        } else {
            hemisphereLatitude = .north
        }

        longitude = Int(try decoder.decodeUnconstrainedInteger())
        latitude = Int(try decoder.decodeUnconstrainedInteger())

        if presence[4] {
            accuracy = try GeoUnitTypeV1(from: &decoder)
        }
    }
}

extension GeoCoordinateTypeV1: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        let geoUnitPresent = geoUnit != nil && geoUnit != .milliDegree
        let coordinateSystemPresent = coordinateSystem != nil && coordinateSystem != .wgs84
        let hemisphereLongitudePresent = hemisphereLongitude != nil && hemisphereLongitude != .east
        let hemisphereLatitudePresent = hemisphereLatitude != nil && hemisphereLatitude != .north
        try encoder.encodePresenceBitmap([
            geoUnitPresent,
            coordinateSystemPresent,
            hemisphereLongitudePresent,
            hemisphereLatitudePresent,
            accuracy != nil
        ])
        if geoUnitPresent { try encoder.encodeEnumerated(geoUnit!.rawValue, rootCount: GeoUnitTypeV1.rootValueCount) }
        if coordinateSystemPresent { try encoder.encodeEnumerated(coordinateSystem!.rawValue, rootCount: GeoCoordinateSystemTypeV1.rootValueCount) }
        if hemisphereLongitudePresent { try encoder.encodeEnumerated(hemisphereLongitude!.rawValue, rootCount: HemisphereLongitudeTypeV1.rootValueCount) }
        if hemisphereLatitudePresent { try encoder.encodeEnumerated(hemisphereLatitude!.rawValue, rootCount: HemisphereLatitudeTypeV1.rootValueCount) }
        try encoder.encodeUnconstrainedInteger(Int64(longitude))
        try encoder.encodeUnconstrainedInteger(Int64(latitude))
        if let v = accuracy { try encoder.encodeEnumerated(v.rawValue, rootCount: GeoUnitTypeV1.rootValueCount) }
    }
}
