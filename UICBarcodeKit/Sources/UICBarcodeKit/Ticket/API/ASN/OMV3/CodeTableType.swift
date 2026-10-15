import Foundation

/// Code table type for station codes
public enum CodeTableType: Int {
    case stationUIC = 0
    case stationUICReservation = 1
    case stationERA = 2
    case localCarrierStationCodeTable = 3
    case proprietaryIssuerStationCodeTable = 4
}
