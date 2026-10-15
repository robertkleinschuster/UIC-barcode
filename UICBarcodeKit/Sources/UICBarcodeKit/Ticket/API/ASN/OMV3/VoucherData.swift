import Foundation

// MARK: - Voucher Data

/// Voucher data - matches Java VoucherData.java
public struct VoucherData: ASN1Decodable {
    // Field 0: referenceIA5 (IA5String, optional)
    public var referenceIA5: String?
    // Field 1: referenceNum (BigInteger, optional)
    public var referenceNum: Int?
    // Field 2: productOwnerNum (1..32000, optional)
    public var productOwnerNum: Int?
    // Field 3: productOwnerIA5 (IA5String, optional)
    public var productOwnerIA5: String?
    // Field 4: productIdNum (0..65535, optional)
    public var productIdNum: Int?
    // Field 5: productIdIA5 (IA5String, optional)
    public var productIdIA5: String?
    // Field 6: validFromYear (2016..2269, MANDATORY)
    public var validFromYear: Int = 2024
    // Field 7: validFromDay (0..500, MANDATORY)
    public var validFromDay: Int = 0
    // Field 8: validUntilYear (2016..2269, MANDATORY)
    public var validUntilYear: Int = 2024
    // Field 9: validUntilDay (0..500, MANDATORY)
    public var validUntilDay: Int = 0
    // Field 10: value (Long, optional, default 0)
    public var value: Int?
    // Field 11: type (1..32000, optional)
    public var voucherType: Int?
    // Field 12: infoText (UTF8String, optional)
    public var infoText: String?
    // Field 13: extension (ExtensionData, optional)
    public var extensionData: ExtensionData?

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 10 optional fields (fields 6-9 are MANDATORY per Java VoucherData.java)
        let optionalCount = 10
        let presence = try decoder.decodePresenceBitmap(count: optionalCount)
        var idx = 0

        // Field 0: referenceIA5 (optional, IA5String)
        if presence[idx] { referenceIA5 = try decoder.decodeIA5String() }; idx += 1
        // Field 1: referenceNum (optional, BigInteger)
        if presence[idx] { referenceNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        // Field 2: productOwnerNum (optional, 1..32000)
        if presence[idx] { productOwnerNum = try decoder.decodeConstrainedInt(min: 1, max: 32000) }; idx += 1
        // Field 3: productOwnerIA5 (optional, IA5String)
        if presence[idx] { productOwnerIA5 = try decoder.decodeIA5String() }; idx += 1
        // Field 4: productIdNum (optional, 0..65535)
        if presence[idx] { productIdNum = try decoder.decodeConstrainedInt(min: 0, max: 65535) }; idx += 1
        // Field 5: productIdIA5 (optional, IA5String)
        if presence[idx] { productIdIA5 = try decoder.decodeIA5String() }; idx += 1

        // Fields 6-9: MANDATORY (no presence bits)
        validFromYear = try decoder.decodeConstrainedInt(min: 2016, max: 2269)
        validFromDay = try decoder.decodeConstrainedInt(min: 0, max: 500)
        validUntilYear = try decoder.decodeConstrainedInt(min: 2016, max: 2269)
        validUntilDay = try decoder.decodeConstrainedInt(min: 0, max: 500)

        // Field 10: value (optional, BigInteger, default 0)
        if presence[idx] { value = Int(try decoder.decodeUnconstrainedInteger()) } else { value = 0 }; idx += 1
        // Field 11: type (optional, 1..32000)
        if presence[idx] { voucherType = try decoder.decodeConstrainedInt(min: 1, max: 32000) }; idx += 1
        // Field 12: infoText (optional, UTF8String)
        if presence[idx] { infoText = try decoder.decodeUTF8String() }; idx += 1
        // Field 13: extension (optional, ExtensionData)
        if presence[idx] { extensionData = try ExtensionData(from: &decoder) }

        if hasExtensions {
            let numExt = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt where extPresence[i] {
                try decoder.skipOpenType()
            }
        }
    }
}

// MARK: - VoucherData Encoding

extension VoucherData: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)

        let valuePresent = value != nil && value != 0

        try encoder.encodePresenceBitmap([
            referenceIA5 != nil,
            referenceNum != nil,
            productOwnerNum != nil,
            productOwnerIA5 != nil,
            productIdNum != nil,
            productIdIA5 != nil,
            valuePresent,
            voucherType != nil,
            infoText != nil,
            extensionData != nil
        ])

        if let v = referenceIA5 { try encoder.encodeIA5String(v) }
        if let v = referenceNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = productOwnerNum { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        if let v = productOwnerIA5 { try encoder.encodeIA5String(v) }
        if let v = productIdNum { try encoder.encodeConstrainedInt(v, min: 0, max: 65535) }
        if let v = productIdIA5 { try encoder.encodeIA5String(v) }
        try encoder.encodeConstrainedInt(validFromYear, min: 2016, max: 2269)
        try encoder.encodeConstrainedInt(validFromDay, min: 0, max: 500)
        try encoder.encodeConstrainedInt(validUntilYear, min: 2016, max: 2269)
        try encoder.encodeConstrainedInt(validUntilDay, min: 0, max: 500)
        if valuePresent { try encoder.encodeUnconstrainedInteger(Int64(value!)) }
        if let v = voucherType { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        if let v = infoText { try encoder.encodeUTF8String(v) }
        if let v = extensionData { try v.encode(to: &encoder) }
    }
}
