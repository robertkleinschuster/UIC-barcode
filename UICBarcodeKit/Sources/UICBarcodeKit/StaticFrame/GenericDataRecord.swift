import Foundation

/// Generic/bilateral data record
public struct GenericDataRecord: DataRecordProtocol {
    public let tag: String
    public let version: String
    public let content: Data

    public init(data: Data) throws {
        guard data.count >= 12 else {
            throw UICBarcodeError.invalidData("Data record too short")
        }

        self.tag = String(data: data[0..<6], encoding: .ascii) ?? ""
        self.version = String(data: data[6..<8], encoding: .ascii) ?? "01"

        let lengthStr = String(data: data[8..<12], encoding: .ascii)?.trimmingCharacters(in: .whitespaces) ?? "0"
        let length = Int(lengthStr) ?? 0
        let contentLength = length - 12

        if contentLength > 0 && data.count >= 12 + contentLength {
            self.content = Data(data[12..<(12 + contentLength)])
        } else {
            self.content = Data()
        }
    }
}

// MARK: - GenericDataRecord Encoding

extension GenericDataRecord {

    /// Encode the generic record to bytes.
    public func encode() -> Data {
        let totalLength = 12 + content.count
        var result = Data()
        result.append(contentsOf: Array(tag.padding(toLength: 6, withPad: " ", startingAt: 0).utf8.prefix(6)))
        result.append(contentsOf: Array(version.padding(toLength: 2, withPad: "0", startingAt: 0).utf8.prefix(2)))
        let lengthStr = String(format: "%04d", totalLength)
        result.append(contentsOf: Array(lengthStr.utf8.prefix(4)))
        result.append(content)
        return result
    }
}
