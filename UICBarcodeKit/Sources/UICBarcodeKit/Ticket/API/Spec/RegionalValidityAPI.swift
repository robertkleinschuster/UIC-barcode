import Foundation

public enum RegionalValidityAPI {
    case trainLink(TrainLinkAPI)
    case viaStations(ViaStationAPI)
    case zone(ZoneAPI)
    case line(LineAPI)
    case polygone(PolygoneAPI)
}
