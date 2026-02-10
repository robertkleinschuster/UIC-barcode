import Foundation

/// Level 2 data containing level 1 data and its signature
/// Java ref: Level2DataType.java (v1 and v2)
/// ASN.1 (same for V1 and V2, no extension marker):
///   Level2DataType ::= SEQUENCE {
///     level1Data       Level1DataType,              -- mandatory
///     level1Signature  OCTET STRING    OPTIONAL,
///     level2Data       DataType        OPTIONAL
///   }
public struct DynamicFrameLevel2Data {
    /// The level 1 data (mandatory)
    public var level1Data: DynamicFrameLevel1Data?

    /// Signature of level 1 data
    public var level1Signature: Data?

    /// Level 2 dynamic data (e.g. FDC1 content)
    public var level2Data: DynamicFrameDataItem?

    public init() {}

    public init(from decoder: inout UPERDecoder, version: DynamicFrameVersion) throws {
        // No extension marker

        // 2 optional fields: level1Signature, level2Data
        let presence = try decoder.decodePresenceBitmap(count: 2)

        // level1Data (mandatory)
        level1Data = try DynamicFrameLevel1Data(from: &decoder, version: version)

        // level1Signature (optional)
        if presence[0] {
            level1Signature = try decoder.decodeOctetString()
        }

        // level2Data (optional)
        if presence[1] {
            level2Data = try DynamicFrameDataItem(from: &decoder)
        }
    }
}

// MARK: - DynamicFrameLevel2Data Encoding

extension DynamicFrameLevel2Data {

    func encode(to encoder: inout UPEREncoder, version: DynamicFrameVersion) throws {
        // No extension marker
        // 2 optional fields: level1Signature, level2Data
        try encoder.encodePresenceBitmap([
            level1Signature != nil,
            level2Data != nil
        ])

        // level1Data (mandatory)
        guard let l1 = level1Data else {
            throw UICBarcodeError.encodingFailed("Level2Data has no level1Data")
        }
        try l1.encode(to: &encoder, version: version)

        // level1Signature (optional)
        if let sig = level1Signature {
            try encoder.encodeOctetString(sig)
        }

        // level2Data (optional)
        if let item = level2Data {
            try item.encode(to: &encoder)
        }
    }
}
