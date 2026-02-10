import Foundation

/// Geographic coordinate type
public struct GeoCoordinateType: ASN1Decodable {
    public var geoUnit: GeoUnitType?
    public var coordinateSystem: GeoCoordinateSystemType?
    public var hemisphereLongitude: HemisphereLongitudeType?
    public var hemisphereLatitude: HemisphereLatitudeType?
    public var longitude: Int = 0
    public var latitude: Int = 0
    public var accuracy: GeoUnitType?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        // Java GeoCoordinateType has NO @HasExtensionMarker
        let presence = try decoder.decodePresenceBitmap(count: 5)

        if presence[0] {
            let value = try decoder.decodeEnumerated(rootCount: 5)
            geoUnit = GeoUnitType(rawValue: value)
        } else {
            geoUnit = .milliDegree
        }
        if presence[1] {
            let value = try decoder.decodeEnumerated(rootCount: 2)
            coordinateSystem = GeoCoordinateSystemType(rawValue: value)
        } else {
            coordinateSystem = .wgs84
        }
        if presence[2] {
            let value = try decoder.decodeEnumerated(rootCount: 2)
            hemisphereLongitude = HemisphereLongitudeType(rawValue: value)
        } else {
            hemisphereLongitude = .east
        }
        if presence[3] {
            let value = try decoder.decodeEnumerated(rootCount: 2)
            hemisphereLatitude = HemisphereLatitudeType(rawValue: value)
        } else {
            hemisphereLatitude = .north
        }

        longitude = Int(try decoder.decodeUnconstrainedInteger())
        latitude = Int(try decoder.decodeUnconstrainedInteger())

        if presence[4] {
            let value = try decoder.decodeEnumerated(rootCount: 5)
            accuracy = GeoUnitType(rawValue: value)
        }
    }
}

extension GeoCoordinateType: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        let geoUnitPresent = geoUnit != nil && geoUnit != .milliDegree
        let coordinateSystemPresent = coordinateSystem != nil && coordinateSystem != .wgs84
        let hemisphereLongitudePresent = hemisphereLongitude != nil && hemisphereLongitude != .east
        let hemisphereLatitudePresent = hemisphereLatitude != nil && hemisphereLatitude != .north
        let accuracyPresent = accuracy != nil

        try encoder.encodePresenceBitmap([
            geoUnitPresent,
            coordinateSystemPresent,
            hemisphereLongitudePresent,
            hemisphereLatitudePresent,
            accuracyPresent
        ])

        if geoUnitPresent { try encoder.encodeEnumerated(geoUnit!.rawValue, rootCount: 5) }
        if coordinateSystemPresent { try encoder.encodeEnumerated(coordinateSystem!.rawValue, rootCount: 2) }
        if hemisphereLongitudePresent { try encoder.encodeEnumerated(hemisphereLongitude!.rawValue, rootCount: 2) }
        if hemisphereLatitudePresent { try encoder.encodeEnumerated(hemisphereLatitude!.rawValue, rootCount: 2) }

        try encoder.encodeUnconstrainedInteger(Int64(longitude))
        try encoder.encodeUnconstrainedInteger(Int64(latitude))

        if accuracyPresent { try encoder.encodeEnumerated(accuracy!.rawValue, rootCount: 5) }
    }
}
