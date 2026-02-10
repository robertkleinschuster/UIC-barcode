import Foundation

/// Base for all transport document types
public enum APIDocumentData {
    case reservation(Reservation)
    case openTicket(OpenTicket)
    case pass(Pass)
    case carCarriageReservation(CarCarriageReservationAPI)
    case customerCard(CustomerCardAPI)
    case counterMark(CounterMarkAPI)
    case parkingGround(ParkingGroundAPI)
    case fipTicket(FIPTicketAPI)
    case stationPassage(StationPassageAPI)
    case delayConfirmation(DelayConfirmationAPI)
    case voucher(VoucherAPI)
    case documentExtension(DocumentExtensionAPI)
}
