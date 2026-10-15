import Foundation

// MARK: - UicRailTicketDataV1 (root)

struct UicRailTicketDataV1: ASN1Decodable {
    static let hasExtensionMarker = true
    static let optionalFieldCount = 4

    var issuingDetail: IssuingDataV1
    var travelerDetail: TravelerDataV1?
    var transportDocument: [DocumentDataV1]?
    var controlDetail: ControlDataV1?
    var extensionData: [ExtensionDataV1]?

    init() {
        self.issuingDetail = IssuingDataV1()
    }

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        let presence = try decoder.decodePresenceBitmap(count: Self.optionalFieldCount)

        self.issuingDetail = try IssuingDataV1(from: &decoder)

        if presence[0] { self.travelerDetail = try TravelerDataV1(from: &decoder) }
        if presence[1] { self.transportDocument = try decoder.decodeSequenceOf() }
        if presence[2] { self.controlDetail = try ControlDataV1(from: &decoder) }
        if presence[3] { self.extensionData = try decoder.decodeSequenceOf() }

        if hasExtensions {
            let numExtensions = try decoder.decodeBitmaskLength()
            let extensionPresence = try decoder.decodePresenceBitmap(count: numExtensions)
            for i in 0..<numExtensions where extensionPresence[i] {
                try decoder.skipOpenType()
            }
        }
    }
}

// MARK: - Encoding

extension UicRailTicketDataV1: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        try encoder.encodePresenceBitmap([
            travelerDetail != nil,
            transportDocument != nil,
            controlDetail != nil,
            extensionData != nil
        ])
        try issuingDetail.encode(to: &encoder)
        if let travelerDetail { try travelerDetail.encode(to: &encoder) }
        if let transportDocument { try encoder.encodeSequenceOf(transportDocument) }
        if let controlDetail { try controlDetail.encode(to: &encoder) }
        if let extensionData { try encoder.encodeSequenceOf(extensionData) }
    }
}
