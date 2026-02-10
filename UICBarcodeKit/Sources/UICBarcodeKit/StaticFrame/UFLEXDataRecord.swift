import Foundation

/// Flex data record (U_FLEX) containing FCB ticket
public struct UFLEXDataRecord: DataRecordProtocol {
    public let tag: String
    public let version: String
    public let content: Data

    /// The decoded FCB ticket (nil if not yet decoded)
    public var ticket: UicRailTicketData?

    /// FCB version number
    public var fcbVersion: Int

    public init(data: Data) throws {
        let offset = 12 // Skip tag, version, length

        guard data.count >= offset else {
            throw UICBarcodeError.invalidData("U_FLEX record too short")
        }

        self.tag = String(data: data[0..<6], encoding: .ascii) ?? "U_FLEX"
        self.version = String(data: data[6..<8], encoding: .ascii) ?? "03"
        self.content = Data(data[offset...])

        // Parse FCB version from record version
        self.fcbVersion = FCBVersionDecoder.parseVersion(version)

        // Decode the FCB ticket
        if !content.isEmpty {
            self.ticket = try FCBVersionDecoder.decode(data: content, version: fcbVersion)
        }
    }
}

// MARK: - UFLEXDataRecord Encoding

extension UFLEXDataRecord {

    /// Encode the U_FLEX record to bytes.
    /// Content is UPER-encoded FCB ticket data.
    public func encode() throws -> Data {
        var contentData: Data
        if let ticket = ticket {
            contentData = try FCBVersionEncoder.encode(ticket: ticket)
        } else {
            contentData = content
        }

        return buildRecord(tag: tag, version: version, content: contentData)
    }

    private func buildRecord(tag: String, version: String, content: Data) -> Data {
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
