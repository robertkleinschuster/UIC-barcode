import Foundation

struct RegionalValidityTypeV2: ASN1Decodable {
    enum ValidityType {
        case trainLink(TrainLinkTypeV2)
        case viaStations(ViaStationTypeV2)
        case zone(ZoneTypeV2)
        case line(LineTypeV2)
        case polygone(PolygoneTypeV2)
    }

    var validity: ValidityType?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let choiceIndex = try decoder.decodeChoiceIndex(rootCount: 5, hasExtensionMarker: true)
        switch choiceIndex {
        case 0: validity = .trainLink(try TrainLinkTypeV2(from: &decoder))
        case 1: validity = .viaStations(try ViaStationTypeV2(from: &decoder))
        case 2: validity = .zone(try ZoneTypeV2(from: &decoder))
        case 3: validity = .line(try LineTypeV2(from: &decoder))
        case 4: validity = .polygone(try PolygoneTypeV2(from: &decoder))
        default: break
        }
    }
}

extension RegionalValidityTypeV2: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
        guard let validity else { return }
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
