import Foundation

/// Ticket detail data - CHOICE of different ticket types
public struct TicketDetailData: ASN1Decodable {
    public enum TicketType {
        case reservation(ReservationData)
        case carCarriageReservation(CarCarriageReservationData)
        case openTicket(OpenTicketData)
        case pass(PassData)
        case voucher(VoucherData)
        case customerCard(CustomerCardData)
        case countermark(CountermarkData)
        case parkingGround(ParkingGroundData)
        case fipTicket(FIPTicketData)
        case stationPassage(StationPassageData)
        case ticketExtension(ExtensionData)
        case delayConfirmation(DelayConfirmation)
        case unknown(Data)
    }

    public var ticketType: TicketType?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let choiceIndex = try decoder.decodeChoiceIndex(rootCount: 12, hasExtensionMarker: true)

        switch choiceIndex {
        case 0: ticketType = .reservation(try ReservationData(from: &decoder))
        case 1: ticketType = .carCarriageReservation(try CarCarriageReservationData(from: &decoder))
        case 2: ticketType = .openTicket(try OpenTicketData(from: &decoder))
        case 3: ticketType = .pass(try PassData(from: &decoder))
        case 4: ticketType = .voucher(try VoucherData(from: &decoder))
        case 5: ticketType = .customerCard(try CustomerCardData(from: &decoder))
        case 6: ticketType = .countermark(try CountermarkData(from: &decoder))
        case 7: ticketType = .parkingGround(try ParkingGroundData(from: &decoder))
        case 8: ticketType = .fipTicket(try FIPTicketData(from: &decoder))
        case 9: ticketType = .stationPassage(try StationPassageData(from: &decoder))
        case 10: ticketType = .ticketExtension(try ExtensionData(from: &decoder))
        case 11: ticketType = .delayConfirmation(try DelayConfirmation(from: &decoder))
        default:
            // Extension or unknown - skip
            let data = try decoder.decodeOctetString()
            ticketType = .unknown(data)
        }
    }
}

extension TicketDetailData: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        guard let ticketType else {
            throw UICBarcodeError.encodingFailed("TicketDetailData has no ticket type set")
        }
        switch ticketType {
        case .reservation(let data):
            try encoder.encodeChoiceIndex(0, rootCount: 12, hasExtensionMarker: true)
            try data.encode(to: &encoder)
        case .carCarriageReservation(let data):
            try encoder.encodeChoiceIndex(1, rootCount: 12, hasExtensionMarker: true)
            try data.encode(to: &encoder)
        case .openTicket(let data):
            try encoder.encodeChoiceIndex(2, rootCount: 12, hasExtensionMarker: true)
            try data.encode(to: &encoder)
        case .pass(let data):
            try encoder.encodeChoiceIndex(3, rootCount: 12, hasExtensionMarker: true)
            try data.encode(to: &encoder)
        case .voucher(let data):
            try encoder.encodeChoiceIndex(4, rootCount: 12, hasExtensionMarker: true)
            try data.encode(to: &encoder)
        case .customerCard(let data):
            try encoder.encodeChoiceIndex(5, rootCount: 12, hasExtensionMarker: true)
            try data.encode(to: &encoder)
        case .countermark(let data):
            try encoder.encodeChoiceIndex(6, rootCount: 12, hasExtensionMarker: true)
            try data.encode(to: &encoder)
        case .parkingGround(let data):
            try encoder.encodeChoiceIndex(7, rootCount: 12, hasExtensionMarker: true)
            try data.encode(to: &encoder)
        case .fipTicket(let data):
            try encoder.encodeChoiceIndex(8, rootCount: 12, hasExtensionMarker: true)
            try data.encode(to: &encoder)
        case .stationPassage(let data):
            try encoder.encodeChoiceIndex(9, rootCount: 12, hasExtensionMarker: true)
            try data.encode(to: &encoder)
        case .ticketExtension(let data):
            try encoder.encodeChoiceIndex(10, rootCount: 12, hasExtensionMarker: true)
            try data.encode(to: &encoder)
        case .delayConfirmation(let data):
            try encoder.encodeChoiceIndex(11, rootCount: 12, hasExtensionMarker: true)
            try data.encode(to: &encoder)
        case .unknown(let data):
            try encoder.encodeOctetString(data)
        }
    }
}
