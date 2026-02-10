import Foundation

struct RegionalValidityTypeV1: ASN1Decodable {
    enum ValidityType {
        case trainLink(TrainLinkTypeV1)
        case viaStations(ViaStationTypeV1)
        case zone(ZoneTypeV1)
        case line(LineTypeV1)
        case polygone(PolygoneTypeV1)
    }

    var validity: ValidityType?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let choiceIndex = try decoder.decodeChoiceIndex(rootCount: 5, hasExtensionMarker: true)
        switch choiceIndex {
        case 0: validity = .trainLink(try TrainLinkTypeV1(from: &decoder))
        case 1: validity = .viaStations(try ViaStationTypeV1(from: &decoder))
        case 2: validity = .zone(try ZoneTypeV1(from: &decoder))
        case 3: validity = .line(try LineTypeV1(from: &decoder))
        case 4: validity = .polygone(try PolygoneTypeV1(from: &decoder))
        default: break
        }
    }
}

// MARK: - RegionalValidityTypeV1 Encoding

extension RegionalValidityTypeV1: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        guard let validity else {
            throw UICBarcodeError.encodingFailed("RegionalValidityTypeV1 has no validity set")
        }
        switch validity {
        case .trainLink(let data):
            try encoder.encodeChoiceIndex(0, rootCount: 5, hasExtensionMarker: true)
            try data.encode(to: &encoder)
        case .viaStations(let data):
            try encoder.encodeChoiceIndex(1, rootCount: 5, hasExtensionMarker: true)
            try data.encode(to: &encoder)
        case .zone(let data):
            try encoder.encodeChoiceIndex(2, rootCount: 5, hasExtensionMarker: true)
            try data.encode(to: &encoder)
        case .line(let data):
            try encoder.encodeChoiceIndex(3, rootCount: 5, hasExtensionMarker: true)
            try data.encode(to: &encoder)
        case .polygone(let data):
            try encoder.encodeChoiceIndex(4, rootCount: 5, hasExtensionMarker: true)
            try data.encode(to: &encoder)
        }
    }
}
