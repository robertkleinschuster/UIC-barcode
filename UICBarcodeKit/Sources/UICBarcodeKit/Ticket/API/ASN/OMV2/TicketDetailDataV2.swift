import Foundation

struct TicketDetailDataV2: ASN1Decodable {
    enum TicketType {
        case reservation(ReservationDataV2)
        case carCarriageReservation(CarCarriageReservationDataV2)
        case openTicket(OpenTicketDataV2)
        case pass(PassDataV2)
        case voucher(VoucherDataV2)
        case customerCard(CustomerCardDataV2)
        case countermark(CountermarkDataV2)
        case parkingGround(ParkingGroundDataV2)
        case fipTicket(FIPTicketDataV2)
        case stationPassage(StationPassageDataV2)
        case ticketExtension(ExtensionDataV2)
        case delayConfirmation(DelayConfirmationV2)
        case unknown(Data)
    }

    var ticketType: TicketType?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let choiceIndex = try decoder.decodeChoiceIndex(rootCount: 12, hasExtensionMarker: true)

        switch choiceIndex {
        case 0: ticketType = .reservation(try ReservationDataV2(from: &decoder))
        case 1: ticketType = .carCarriageReservation(try CarCarriageReservationDataV2(from: &decoder))
        case 2: ticketType = .openTicket(try OpenTicketDataV2(from: &decoder))
        case 3: ticketType = .pass(try PassDataV2(from: &decoder))
        case 4: ticketType = .voucher(try VoucherDataV2(from: &decoder))
        case 5: ticketType = .customerCard(try CustomerCardDataV2(from: &decoder))
        case 6: ticketType = .countermark(try CountermarkDataV2(from: &decoder))
        case 7: ticketType = .parkingGround(try ParkingGroundDataV2(from: &decoder))
        case 8: ticketType = .fipTicket(try FIPTicketDataV2(from: &decoder))
        case 9: ticketType = .stationPassage(try StationPassageDataV2(from: &decoder))
        case 10: ticketType = .ticketExtension(try ExtensionDataV2(from: &decoder))
        case 11: ticketType = .delayConfirmation(try DelayConfirmationV2(from: &decoder))
        default:
            let data = try decoder.decodeOctetString()
            ticketType = .unknown(data)
        }
    }
}

extension TicketDetailDataV2: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        guard let ticketType else {
            throw UICBarcodeError.encodingFailed("TicketDetailDataV2 has no ticket type set")
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
