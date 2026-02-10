import Foundation

struct GeoCoordinateTypeV2: ASN1Decodable {
    static let optionalFieldCount = 5

    var geoUnit: GeoUnitTypeV2?
    var coordinateSystem: GeoCoordinateSystemTypeV2?
    var hemisphereLongitude: HemisphereLongitudeTypeV2?
    var hemisphereLatitude: HemisphereLatitudeTypeV2?
    var longitude: Int = 0
    var latitude: Int = 0
    var accuracy: GeoUnitTypeV2?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        // No extension marker in Java GeoCoordinateType v2
        let presence = try decoder.decodePresenceBitmap(count: Self.optionalFieldCount)

        if presence[0] {
            geoUnit = try GeoUnitTypeV2(from: &decoder)
        } else {
            geoUnit = .milliDegree
        }
        if presence[1] {
            coordinateSystem = try GeoCoordinateSystemTypeV2(from: &decoder)
        } else {
            coordinateSystem = .wgs84
        }
        if presence[2] {
            hemisphereLongitude = try HemisphereLongitudeTypeV2(from: &decoder)
        } else {
            hemisphereLongitude = .east
        }
        if presence[3] {
            hemisphereLatitude = try HemisphereLatitudeTypeV2(from: &decoder)
        } else {
            hemisphereLatitude = .north
        }

        longitude = Int(try decoder.decodeUnconstrainedInteger())
        latitude = Int(try decoder.decodeUnconstrainedInteger())

        if presence[4] {
            accuracy = try GeoUnitTypeV2(from: &decoder)
        }
    }
}

extension GeoCoordinateTypeV2: ASN1Encodable {
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
        if geoUnitPresent { try encoder.encodeEnumerated(geoUnit!.rawValue, rootCount: GeoUnitTypeV2.rootValueCount) }
        if coordinateSystemPresent { try encoder.encodeEnumerated(coordinateSystem!.rawValue, rootCount: GeoCoordinateSystemTypeV2.rootValueCount) }
        if hemisphereLongitudePresent { try encoder.encodeEnumerated(hemisphereLongitude!.rawValue, rootCount: HemisphereLongitudeTypeV2.rootValueCount) }
        if hemisphereLatitudePresent { try encoder.encodeEnumerated(hemisphereLatitude!.rawValue, rootCount: HemisphereLatitudeTypeV2.rootValueCount) }
        try encoder.encodeUnconstrainedInteger(Int64(longitude))
        try encoder.encodeUnconstrainedInteger(Int64(latitude))
        if let v = accuracy { try encoder.encodeEnumerated(v.rawValue, rootCount: GeoUnitTypeV2.rootValueCount) }
    }
}
