import Foundation

public struct RegionalValidityType: ASN1Decodable {
    public enum ValidityType {
        case trainLink(TrainLinkType)
        case viaStations(ViaStationType)
        case zone(ZoneType)
        case line(LineType)
        case polygone(PolygoneType)
    }

    public var validity: ValidityType?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let choiceIndex = try decoder.decodeChoiceIndex(rootCount: 5, hasExtensionMarker: true)
        switch choiceIndex {
        case 0: validity = .trainLink(try TrainLinkType(from: &decoder))
        case 1: validity = .viaStations(try ViaStationType(from: &decoder))
        case 2: validity = .zone(try ZoneType(from: &decoder))
        case 3: validity = .line(try LineType(from: &decoder))
        case 4: validity = .polygone(try PolygoneType(from: &decoder))
        default: break
        }
    }
}

extension RegionalValidityType: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        guard let validity else {
            throw UICBarcodeError.encodingFailed("RegionalValidityType has no validity set")
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
