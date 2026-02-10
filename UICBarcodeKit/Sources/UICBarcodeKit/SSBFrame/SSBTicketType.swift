import Foundation

/// SSB Ticket Types (5 bits, values 0-31)
/// Java ref: SsbTicketType.java
public enum SSBTicketType: Int {
    case nonUic = 0
    case irtResBoa = 1          // IRT/RES/BOA - Reservation
    case nrt = 2                // NRT - Non-reservation
    case grp = 3                // GRP - Group
    case rpt = 4                // RPT - Rail Pass
    case uic5Undefined = 5
    case uic6Undefined = 6
    case uic7Undefined = 7
    case uic8Undefined = 8
    case uic9Undefined = 9
    case uic10Undefined = 10
    case uic11Undefined = 11
    case uic12Undefined = 12
    case uic13Undefined = 13
    case uic14Undefined = 14
    case uic15Undefined = 15
    case uic16Undefined = 16
    case uic17Undefined = 17
    case uic18Undefined = 18
    case uic19Undefined = 19
    case uic20Undefined = 20
    case nonUic21Bilateral = 21
    case nonUic22Bilateral = 22
    case nonUic23Bilateral = 23
    case nonUic24Bilateral = 24
    case nonUic25Bilateral = 25
    case nonUic26Bilateral = 26
    case nonUic27Bilateral = 27
    case nonUic28Bilateral = 28
    case nonUic29Bilateral = 29
    case nonUic30Bilateral = 30
    case nonUic31Bilateral = 31

    public var description: String {
        switch self {
        case .nonUic: return "Non-UIC"
        case .irtResBoa: return "IRT/RES/BOA"
        case .nrt: return "NRT"
        case .grp: return "GRP"
        case .rpt: return "RPT"
        default:
            if rawValue >= 21 { return "Non-UIC Bilateral \(rawValue)" }
            return "UIC Undefined \(rawValue)"
        }
    }
}
