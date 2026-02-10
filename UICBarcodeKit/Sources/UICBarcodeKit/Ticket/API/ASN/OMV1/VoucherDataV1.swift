import Foundation

// MARK: - Voucher Data

struct VoucherDataV1: ASN1Decodable {
    var referenceIA5: String?
    var referenceNum: Int?
    var productOwnerNum: Int?
    var productOwnerIA5: String?
    var productIdNum: Int?
    var productIdIA5: String?
    var validFromYear: Int = 2016
    var validFromDay: Int = 0
    var validUntilYear: Int = 2016
    var validUntilDay: Int = 0
    var value: Int?
    var type: Int?
    var infoText: String?
    var extensionData: ExtensionDataV1?

    init() {}

    init(from decoder: inout UPERDecoder) throws {
        let hasExtensions = try decoder.decodeBit()
        // 10 optional+default fields; validFromYear, validFromDay, validUntilYear, validUntilDay are mandatory
        let presence = try decoder.decodePresenceBitmap(count: 10)
        var idx = 0

        if presence[idx] { referenceIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { referenceNum = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1
        if presence[idx] { productOwnerNum = try decoder.decodeConstrainedInt(min: 1, max: 32000) }; idx += 1
        if presence[idx] { productOwnerIA5 = try decoder.decodeIA5String() }; idx += 1
        if presence[idx] { productIdNum = try decoder.decodeConstrainedInt(min: 0, max: 32000) }; idx += 1
        if presence[idx] { productIdIA5 = try decoder.decodeIA5String() }; idx += 1

        // MANDATORY fields
        validFromYear = try decoder.decodeConstrainedInt(min: 2016, max: 2269)
        validFromDay = try decoder.decodeConstrainedInt(min: 0, max: 370)
        validUntilYear = try decoder.decodeConstrainedInt(min: 2016, max: 2269)
        validUntilDay = try decoder.decodeConstrainedInt(min: 0, max: 370)

        if presence[idx] { value = Int(try decoder.decodeUnconstrainedInteger()) } else { value = 0 }; idx += 1
        if presence[idx] { type = try decoder.decodeConstrainedInt(min: 1, max: 32000) }; idx += 1
        if presence[idx] { infoText = try decoder.decodeUTF8String() }; idx += 1
        if presence[idx] { extensionData = try ExtensionDataV1(from: &decoder) }

        if hasExtensions {
            let numExt = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt where extPresence[i] {
                try decoder.skipOpenType()
            }
        }
    }
}

// MARK: - VoucherDataV1 Encoding

extension VoucherDataV1: ASN1Encodable {
    func encode(to encoder: inout UPEREncoder) throws {
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
            type != nil,
            infoText != nil,
            extensionData != nil
        ])
        if let v = referenceIA5 { try encoder.encodeIA5String(v) }
        if let v = referenceNum { try encoder.encodeUnconstrainedInteger(Int64(v)) }
        if let v = productOwnerNum { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        if let v = productOwnerIA5 { try encoder.encodeIA5String(v) }
        if let v = productIdNum { try encoder.encodeConstrainedInt(v, min: 0, max: 32000) }
        if let v = productIdIA5 { try encoder.encodeIA5String(v) }
        try encoder.encodeConstrainedInt(validFromYear, min: 2016, max: 2269)
        try encoder.encodeConstrainedInt(validFromDay, min: 0, max: 370)
        try encoder.encodeConstrainedInt(validUntilYear, min: 2016, max: 2269)
        try encoder.encodeConstrainedInt(validUntilDay, min: 0, max: 370)
        if valuePresent { try encoder.encodeUnconstrainedInteger(Int64(value!)) }
        if let v = type { try encoder.encodeConstrainedInt(v, min: 1, max: 32000) }
        if let v = infoText { try encoder.encodeUTF8String(v) }
        if let v = extensionData { try v.encode(to: &encoder) }
    }
}
