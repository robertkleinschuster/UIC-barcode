import Foundation

/// Tariff type
public struct TariffType: ASN1Decodable {
    public var numberOfPassengers: Int?
    public var passengerType: PassengerType?
    public var ageBelow: Int?
    public var ageAbove: Int?
    public var travelerid: [Int]?
    public var restrictedToCountryOfResidence: Bool = false  // MANDATORY
    public var restrictedToRouteSection: RouteSectionType?
    public var seriesDataDetails: SeriesDetailType?
    public var tariffIdNum: Int?
    public var tariffIdIA5: String?
    public var tariffDesc: String?
    public var reductionCard: [CardReferenceType]?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        let presence = try decoder.decodePresenceBitmap(count: 11)
        var idx = 0

        if presence[idx] { numberOfPassengers = try decoder.decodeConstrainedInt(min: 1, max: 200) } else { numberOfPassengers = 1 }; idx += 1
        if presence[idx] {
            let value = try decoder.decodeEnumerated(rootCount: 8, hasExtensionMarker: true)
            passengerType = PassengerType(rawValue: value)
        }; idx += 1
        if presence[idx] { ageBelow = try decoder.decodeConstrainedInt(min: 1, max: 64) }; idx += 1
        if presence[idx] { ageAbove = try decoder.decodeConstrainedInt(min: 1, max: 128) }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            travelerid = []
            for _ in 0..<count {
                travelerid?.append(try decoder.decodeConstrainedInt(min: 1, max: 254))
            }
        }; idx += 1
        restrictedToCountryOfResidence = try decoder.decodeBoolean()  // MANDATORY
        if presence[idx] { restrictedToRouteSection = try RouteSectionType(from: &decoder) }; idx += 1
        if presence[idx] { seriesDataDetails = try SeriesDetailType(from: &decoder) }; idx += 1
        if presence[idx] { tariffIdNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { tariffIdIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { tariffDesc = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] { reductionCard = try decoder.decodeSequenceOf() }

        if hasExtensions {
            let numExt = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt where extPresence[i] {
                try decoder.skipOpenType()
            }
        }
    }
}

extension TariffType: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)

        let numberOfPassengersPresent = numberOfPassengers != nil && numberOfPassengers != 1

        try encoder.encodePresenceBitmap([
            numberOfPassengersPresent,
            passengerType != nil,
            ageBelow != nil,
            ageAbove != nil,
            travelerid != nil,
            restrictedToRouteSection != nil,
            seriesDataDetails != nil,
            tariffIdNum != nil,
            tariffIdIA5 != nil,
            tariffDesc != nil,
            reductionCard != nil
        ])

        if numberOfPassengersPresent { try encoder.encodeConstrainedInt(numberOfPassengers!, min: 1, max: 200) }
        if let v = passengerType { try encoder.encodeEnumerated(v.rawValue, rootCount: 8, hasExtensionMarker: true) }
        if let v = ageBelow { try encoder.encodeConstrainedInt(v, min: 1, max: 64) }
        if let v = ageAbove { try encoder.encodeConstrainedInt(v, min: 1, max: 128) }
        if let ids = travelerid {
            try encoder.encodeLengthDeterminant(ids.count)
            for id in ids {
                try encoder.encodeConstrainedInt(id, min: 1, max: 254)
            }
        }
        try encoder.encodeBoolean(restrictedToCountryOfResidence)
        if let v = restrictedToRouteSection { try v.encode(to: &encoder) }
        if let v = seriesDataDetails { try v.encode(to: &encoder) }
        if let v = tariffIdNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = tariffIdIA5 { try encoder.encodeIA5String(v) }
        if let v = tariffDesc { try encoder.encodeUTF8String(v) }
        if let v = reductionCard { try encoder.encodeSequenceOf(v) }
    }
}
