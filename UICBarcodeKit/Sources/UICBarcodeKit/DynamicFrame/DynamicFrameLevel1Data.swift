import Foundation

/// Level 1 data containing the actual ticket payload
/// Java ref: Level1DataType.java (v1 and v2)
/// ASN.1 V1 (no extension marker):
///   Level1DataType ::= SEQUENCE {
///     securityProviderNum  INTEGER (1..32000)  OPTIONAL,
///     securityProviderIA5  IA5String           OPTIONAL,
///     keyId                INTEGER (0..99999)  OPTIONAL,
///     dataSequence         SEQUENCE OF DataType,          -- mandatory
///     level1KeyAlg         OBJECT IDENTIFIER   OPTIONAL,
///     level2KeyAlg         OBJECT IDENTIFIER   OPTIONAL,
///     level1SigningAlg     OBJECT IDENTIFIER   OPTIONAL,
///     level2SigningAlg     OBJECT IDENTIFIER   OPTIONAL,
///     level2PublicKey       OCTET STRING        OPTIONAL
///   }
/// V2 adds after level2PublicKey:
///     endOfValidityYear    INTEGER (2016..2269) OPTIONAL,
///     endOfValidityDay     INTEGER (1..366)     OPTIONAL,
///     endOfValidityTime    INTEGER (0..1439)    OPTIONAL,
///     validityDuration     INTEGER (1..3600)    OPTIONAL
public struct DynamicFrameLevel1Data {
    /// Security provider number (RICS code, 1..32000)
    public var securityProviderNum: Int?

    /// Security provider IA5 string
    public var securityProviderIA5: String?

    /// Key ID (0..99999)
    public var keyId: Int?

    /// Data contained in level 1
    public var dataList: [DynamicFrameDataItem] = []

    /// Level 1 key algorithm OID
    public var level1KeyAlg: String?

    /// Level 2 key algorithm OID
    public var level2KeyAlg: String?

    /// Level 1 signing algorithm OID
    public var level1SigningAlg: String?

    /// Level 2 signing algorithm OID
    public var level2SigningAlg: String?

    /// Level 2 public key
    public var level2publicKey: Data?

    /// End of validity year (V2 only, 2016..2269)
    public var endOfValidityYear: Int?

    /// End of validity day (V2 only, 1..366)
    public var endOfValidityDay: Int?

    /// End of validity time in minutes (V2 only, 0..1439)
    public var endOfValidityTime: Int?

    /// Validity duration in seconds (V2 only, 1..3600)
    public var validityDuration: Int?

    /// Raw encoded data (for signature verification)
    public var encodedData: Data = Data()

    public init() {}

    public init(from decoder: inout UPERDecoder, version: DynamicFrameVersion) throws {
        let startPos = decoder.position

        // No extension marker in either V1 or V2 schema

        // Presence bitmap: V1 has 8 optional fields, V2 has 12
        let optionalCount = version == .v1 ? 8 : 12
        let presence = try decoder.decodePresenceBitmap(count: optionalCount)
        var idx = 0

        // Field 0: securityProviderNum (optional, 1..32000)
        if presence[idx] {
            securityProviderNum = try decoder.decodeConstrainedInt(min: 1, max: 32000)
        }
        idx += 1

        // Field 1: securityProviderIA5 (optional)
        if presence[idx] {
            securityProviderIA5 = try decoder.decodeIA5String()
        }
        idx += 1

        // Field 2: keyId (optional, 0..99999)
        if presence[idx] {
            keyId = try decoder.decodeConstrainedInt(min: 0, max: 99999)
        }
        idx += 1

        // Field 3: dataSequence (mandatory - SEQUENCE OF DataType)
        let dataCount = try decoder.decodeLengthDeterminant()
        for _ in 0..<dataCount {
            let item = try DynamicFrameDataItem(from: &decoder)
            dataList.append(item)
        }

        // Field 4: level1KeyAlg (optional, OBJECT IDENTIFIER)
        if presence[idx] {
            level1KeyAlg = try decodeObjectIdentifier(from: &decoder)
        }
        idx += 1

        // Field 5: level2KeyAlg (optional, OBJECT IDENTIFIER)
        if presence[idx] {
            level2KeyAlg = try decodeObjectIdentifier(from: &decoder)
        }
        idx += 1

        // Field 6: level1SigningAlg (optional, OBJECT IDENTIFIER)
        if presence[idx] {
            level1SigningAlg = try decodeObjectIdentifier(from: &decoder)
        }
        idx += 1

        // Field 7: level2SigningAlg (optional, OBJECT IDENTIFIER)
        if presence[idx] {
            level2SigningAlg = try decodeObjectIdentifier(from: &decoder)
        }
        idx += 1

        // Field 8: level2PublicKey (optional, OCTET STRING)
        if presence[idx] {
            level2publicKey = try decoder.decodeOctetString()
        }
        idx += 1

        // V2-only fields
        if version == .v2 {
            // Field 9: endOfValidityYear (optional, 2016..2269)
            if presence[idx] {
                endOfValidityYear = try decoder.decodeConstrainedInt(min: 2016, max: 2269)
            }
            idx += 1

            // Field 10: endOfValidityDay (optional, 1..366)
            if presence[idx] {
                endOfValidityDay = try decoder.decodeConstrainedInt(min: 1, max: 366)
            }
            idx += 1

            // Field 11: endOfValidityTime (optional, 0..1439)
            if presence[idx] {
                endOfValidityTime = try decoder.decodeConstrainedInt(min: 0, max: 1439)
            }
            idx += 1

            // Field 12: validityDuration (optional, 1..3600)
            if presence[idx] {
                validityDuration = try decoder.decodeConstrainedInt(min: 1, max: 3600)
            }
            idx += 1
        }

        // Capture raw encoded data for signature verification
        let endPos = decoder.position
        encodedData = decoder.buffer.extractBytes(startBit: startPos, endBit: endPos)
    }

    /// Decode an ASN.1 OBJECT IDENTIFIER
    private func decodeObjectIdentifier(from decoder: inout UPERDecoder) throws -> String {
        let length = try decoder.decodeLengthDeterminant()
        var oid = [UInt64]()

        var accumulator: UInt64 = 0
        for _ in 0..<length {
            let byte = try decoder.buffer.getByte()

            accumulator = (accumulator << 7) | UInt64(byte & 0x7F)

            if (byte & 0x80) == 0 {
                // Last byte of this component
                if oid.isEmpty {
                    // First two components are encoded together
                    oid.append(accumulator / 40)
                    oid.append(accumulator % 40)
                } else {
                    oid.append(accumulator)
                }
                accumulator = 0
            }
        }

        return oid.map { String($0) }.joined(separator: ".")
    }
}

// MARK: - DynamicFrameLevel1Data Encoding

extension DynamicFrameLevel1Data {

    func encode(to encoder: inout UPEREncoder, version: DynamicFrameVersion) throws {
        // No extension marker
        // V1: 8 optional fields, V2: 12 optional fields
        // dataList is mandatory (not in bitmap)
        var bitmap: [Bool] = [
            securityProviderNum != nil,
            securityProviderIA5 != nil,
            keyId != nil,
            // dataList is mandatory - not in bitmap
            level1KeyAlg != nil,
            level2KeyAlg != nil,
            level1SigningAlg != nil,
            level2SigningAlg != nil,
            level2publicKey != nil
        ]

        if version == .v2 {
            bitmap.append(contentsOf: [
                endOfValidityYear != nil,
                endOfValidityDay != nil,
                endOfValidityTime != nil,
                validityDuration != nil
            ])
        }

        try encoder.encodePresenceBitmap(bitmap)

        // Field 0: securityProviderNum (optional, 1..32000)
        if let v = securityProviderNum {
            try encoder.encodeConstrainedInt(v, min: 1, max: 32000)
        }

        // Field 1: securityProviderIA5 (optional)
        if let v = securityProviderIA5 {
            try encoder.encodeIA5String(v)
        }

        // Field 2: keyId (optional, 0..99999)
        if let v = keyId {
            try encoder.encodeConstrainedInt(v, min: 0, max: 99999)
        }

        // Field 3: dataSequence (mandatory - SEQUENCE OF DataType)
        try encoder.encodeLengthDeterminant(dataList.count)
        for item in dataList {
            try item.encode(to: &encoder)
        }

        // Field 4: level1KeyAlg (optional, OBJECT IDENTIFIER)
        if let v = level1KeyAlg {
            try encoder.encodeObjectIdentifier(v)
        }

        // Field 5: level2KeyAlg (optional, OBJECT IDENTIFIER)
        if let v = level2KeyAlg {
            try encoder.encodeObjectIdentifier(v)
        }

        // Field 6: level1SigningAlg (optional, OBJECT IDENTIFIER)
        if let v = level1SigningAlg {
            try encoder.encodeObjectIdentifier(v)
        }

        // Field 7: level2SigningAlg (optional, OBJECT IDENTIFIER)
        if let v = level2SigningAlg {
            try encoder.encodeObjectIdentifier(v)
        }

        // Field 8: level2PublicKey (optional, OCTET STRING)
        if let v = level2publicKey {
            try encoder.encodeOctetString(v)
        }

        // V2-only fields
        if version == .v2 {
            // Field 9: endOfValidityYear (optional, 2016..2269)
            if let v = endOfValidityYear {
                try encoder.encodeConstrainedInt(v, min: 2016, max: 2269)
            }

            // Field 10: endOfValidityDay (optional, 1..366)
            if let v = endOfValidityDay {
                try encoder.encodeConstrainedInt(v, min: 1, max: 366)
            }

            // Field 11: endOfValidityTime (optional, 0..1439)
            if let v = endOfValidityTime {
                try encoder.encodeConstrainedInt(v, min: 0, max: 1439)
            }

            // Field 12: validityDuration (optional, 1..3600)
            if let v = validityDuration {
                try encoder.encodeConstrainedInt(v, min: 1, max: 3600)
            }
        }
    }
}
