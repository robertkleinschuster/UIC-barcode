import Foundation

/// Geographic coordinate
public struct GeoCoordinateAPI {
    public var longitude: Double = 0
    public var latitude: Double = 0
    public var coordinateSystem: GeoCoordinateSystemType = .wgs84
    public var hemisphereLongitude: HemisphereLongitudeType = .east
    public var hemisphereLatitude: HemisphereLatitudeType = .north
    public var accuracy: GeoUnitType = .milliDegree

    public init() {}
}
