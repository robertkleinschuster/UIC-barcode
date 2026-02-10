import Foundation

struct TariffTypeV1: ASN1Decodable {
    var numberOfPassengers: Int?
    var passengerType: PassengerTypeV1?
    var ageBelow: Int?
    var ageAbove: Int?
    var travelerid: [Int]?
    var restrictedToCountryOfResidence: Bool = false
    var restrictedToRouteSection: RouteSectionTypeV1?
    var seriesDataDetails: SeriesDetailTypeV1?
    var tariffIdNum: Int?
    var tariffIdIA5: String?
    var tariffDesc: String?
    var reductionCard: [CardReferenceTypeV1]?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 11 optional+default fields; restrictedToCountryOfResidence is mandatory
        let presence = try decoder.decodePresenceBitmap(count: 11)
        var idx = 0

        if presence[idx] { numberOfPassengers = try decoder.decodeConstrainedInt(min: 1, max: 200) } else { numberOfPassengers = 1 }; idx += 1
        if presence[idx] { passengerType = try PassengerTypeV1(from: &decoder) }; idx += 1
        if presence[idx] { ageBelow = try decoder.decodeConstrainedInt(min: 1, max: 64) }; idx += 1
        if presence[idx] { ageAbove = try decoder.decodeConstrainedInt(min: 1, max: 128) }; idx += 1
        if presence[idx] {
            let count = try decoder.decodeLengthDeterminant()
            travelerid = []
            for _ in 0..<count {
                travelerid?.append(try decoder.decodeConstrainedInt(min: 0, max: 254))
            }
        }; idx += 1

        // restrictedToCountryOfResidence is MANDATORY
        restrictedToCountryOfResidence = try decoder.decodeBoolean()

        if presence[idx] { restrictedToRouteSection = try RouteSectionTypeV1(from: &decoder) }; idx += 1
        if presence[idx] { seriesDataDetails = try SeriesDetailTypeV1(from: &decoder) }; idx += 1
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

// MARK: - TariffTypeV1 Encoding

extension TariffTypeV1: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
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
        if let v = passengerType { try encoder.encodeEnumerated(v.rawValue, rootCount: PassengerTypeV1.rootValueCount, hasExtensionMarker: PassengerTypeV1.hasExtensionMarker) }
        if let v = ageBelow { try encoder.encodeConstrainedInt(v, min: 1, max: 64) }
        if let v = ageAbove { try encoder.encodeConstrainedInt(v, min: 1, max: 128) }
        if let arr = travelerid {
            try encoder.encodeLengthDeterminant(arr.count)
            for v in arr { try encoder.encodeConstrainedInt(v, min: 0, max: 254) }
        }
        try encoder.encodeBoolean(restrictedToCountryOfResidence)
        if let v = restrictedToRouteSection { try v.encode(to: &encoder) }
        if let v = seriesDataDetails { try v.encode(to: &encoder) }
        if let v = tariffIdNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = tariffIdIA5 { try encoder.encodeIA5String(v) }
        if let v = tariffDesc { try encoder.encodeUTF8String(v) }
        if let arr = reductionCard { try encoder.encodeSequenceOf(arr) }
    }
}
