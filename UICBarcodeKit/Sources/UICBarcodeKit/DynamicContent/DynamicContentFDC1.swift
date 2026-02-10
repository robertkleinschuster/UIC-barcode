import Foundation

/// FDC1 - Dynamic Content data
/// Matches Java UicDynamicContentDataFDC1.java
/// @Sequence @HasExtensionMarker
/// All 5 fields are @Asn1Optional
public struct DynamicContentFDC1: ASN1Decodable {
    /// Field 0: appId (IA5String, optional)
    public var appId: String?

    /// Field 1: timeStamp (TimeStamp, optional)
    public var timeStamp: TimeStamp?

    /// Field 2: geoCoordinate (GeoCoordinateType, optional)
    public var geoCoordinate: GeoCoordinateType?

    /// Field 3: dynamicContentResponseToChallenge (SEQUENCE OF ExtensionData, optional)
    public var dynamicContentResponseToChallenge: [ExtensionData]?

    /// Field 4: dynamicContentExtension (ExtensionData, optional)
    public var dynamicContentExtension: ExtensionData?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        let presence = try decoder.decodePresenceBitmap(count: 5)

        if presence[0] { appId = try decoder.decodeIA5String() }
        if presence[1] { timeStamp = try TimeStamp(from: &decoder) }
        if presence[2] { geoCoordinate = try GeoCoordinateType(from: &decoder) }
        if presence[3] { dynamicContentResponseToChallenge = try decoder.decodeSequenceOf() }
        if presence[4] { dynamicContentExtension = try ExtensionData(from: &decoder) }

        if hasExtensions {
            let numExt = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt where extPresence[i] {
                try decoder.skipOpenType()
            }
        }
    }

    /// The format identifier for this dynamic content type
    public static var format: String { "FDC1" }
}

// MARK: - DynamicContentFDC1 Convenience

extension DynamicContentFDC1 {

    /// Timestamp as Date
    public var timeStampDate: Date? {
        timeStamp?.toDate()
    }
}

// MARK: - DynamicContentFDC1 Encoding

extension DynamicContentFDC1: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        // Has extension marker
        try encoder.encodeBit(false)
        try encoder.encodePresenceBitmap([
            appId != nil,
            timeStamp != nil,
            geoCoordinate != nil,
            dynamicContentResponseToChallenge != nil,
            dynamicContentExtension != nil
        ])
        if let v = appId { try encoder.encodeIA5String(v) }
        if let v = timeStamp { try v.encode(to: &encoder) }
        if let v = geoCoordinate { try v.encode(to: &encoder) }
        if let v = dynamicContentResponseToChallenge { try encoder.encodeSequenceOf(v) }
        if let v = dynamicContentExtension { try v.encode(to: &encoder) }
    }
}
