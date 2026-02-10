import Foundation

/// Data item within level 1
/// Java ref: DataType.java (v1 and v2)
public struct DynamicFrameDataItem {
    /// Data format identifier (e.g., "FCB1", "FCB2", "FCB3")
    public var format: String = ""

    /// The actual data
    public var data: Data = Data()

    public init() {}

    public init(from decoder: inout UPERDecoder) throws {
        format = try decoder.decodeIA5String()
        data = try decoder.decodeOctetString()
    }
}

// MARK: - DynamicFrameDataItem Encoding

extension DynamicFrameDataItem: ASN1Encodable {

    public func encode(to encoder: inout UPEREncoder) throws {
        // No extension marker, no optional fields
        try encoder.encodeIA5String(format)
        try encoder.encodeOctetString(data)
    }
}
