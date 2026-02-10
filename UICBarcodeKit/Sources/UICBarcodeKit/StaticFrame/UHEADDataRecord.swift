import Foundation

/// Header data record (U_HEAD)
/// Java ref: UHEADDataRecord.java
/// Content layout: issuer(4), identifier(20), issuingDate(12, "DDMMYYYYHHMM"), flags(1), language(2), additionalLanguage(2)
public struct UHEADDataRecord: DataRecordProtocol {
    public let tag: String
    public let version: String
    public let content: Data

    public let issuer: String
    public let id: String
    public let issuingDate: Date?
    public let flags: Int
    public let language: String
    public let additionalLanguage: String

    public init(data: Data) throws {
        let offset = 12 // Skip tag, version, length
        guard data.count >= offset else {
            throw UICBarcodeError.invalidData("U_HEAD record too short")
        }

        self.tag = String(data: data[0..<6], encoding: .ascii) ?? "U_HEAD"
        self.version = String(data: data[6..<8], encoding: .ascii) ?? "01"
        self.content = Data(data[offset...])

        // Parse header content
        // issuer (4 bytes at offset 0)
        if content.count >= 4 {
            self.issuer = UHEADDataRecord.decodeString(content, offset: 0, length: 4)
        } else {
            self.issuer = ""
        }

        // identifier (20 bytes at offset 4)
        if content.count >= 24 {
            self.id = UHEADDataRecord.decodeString(content, offset: 4, length: 20)
        } else {
            self.id = ""
        }

        // issuingDate (12 bytes at offset 24, format "DDMMYYYYHHMM")
        if content.count >= 36 {
            let dateStr = UHEADDataRecord.decodeString(content, offset: 24, length: 12)
            let formatter = DateFormatter()
            formatter.dateFormat = "ddMMyyyyHHmm"
            formatter.timeZone = TimeZone(identifier: "UTC")
            self.issuingDate = formatter.date(from: dateStr)
        } else {
            self.issuingDate = nil
        }

        // flags (1 byte at offset 36)
        if content.count >= 37 {
            let flagStr = UHEADDataRecord.decodeString(content, offset: 36, length: 1)
            self.flags = Int(flagStr) ?? 9
        } else {
            self.flags = 9
        }

        // language (2 bytes at offset 37)
        if content.count >= 39 {
            self.language = UHEADDataRecord.decodeString(content, offset: 37, length: 2)
        } else {
            self.language = ""
        }

        // additionalLanguage (2 bytes at offset 39)
        if content.count >= 41 {
            self.additionalLanguage = UHEADDataRecord.decodeString(content, offset: 39, length: 2)
        } else {
            self.additionalLanguage = ""
        }
    }

    /// Decode a string from byte data, replacing newlines with spaces (matches Java behavior)
    private static func decodeString(_ data: Data, offset: Int, length: Int) -> String {
        var chars = [Character]()
        chars.reserveCapacity(length)
        for i in 0..<length {
            guard offset + i < data.count else { break }
            var byte = data[offset + i]
            if byte == 0x0A { // newline -> space
                byte = 0x20
            }
            chars.append(Character(UnicodeScalar(byte)))
        }
        return String(chars)
    }
}

// MARK: - UHEADDataRecord Encoding

extension UHEADDataRecord {

    /// Encode the U_HEAD record to bytes.
    /// Content: issuer(4) + id(20) + issuingDate(12, "DDMMYYYYHHMM") + flags(1) + language(2) + additionalLanguage(2)
    public func encode() throws -> Data {
        // Build content (41 bytes)
        var contentData = Data()

        // issuer (4 bytes)
        contentData.append(contentsOf: padOrTrim(issuer, length: 4))

        // identifier (20 bytes)
        contentData.append(contentsOf: padOrTrim(id, length: 20))

        // issuingDate (12 bytes, format "DDMMYYYYHHMM")
        if let date = issuingDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "ddMMyyyyHHmm"
            formatter.timeZone = TimeZone(identifier: "UTC")
            let dateStr = formatter.string(from: date)
            contentData.append(contentsOf: padOrTrim(dateStr, length: 12))
        } else {
            contentData.append(contentsOf: padOrTrim("", length: 12))
        }

        // flags (1 byte)
        contentData.append(contentsOf: padOrTrim(String(flags), length: 1))

        // language (2 bytes)
        contentData.append(contentsOf: padOrTrim(language, length: 2))

        // additionalLanguage (2 bytes)
        contentData.append(contentsOf: padOrTrim(additionalLanguage, length: 2))

        return buildRecord(tag: "U_HEAD", version: version, content: contentData)
    }

    private func padOrTrim(_ str: String, length: Int) -> [UInt8] {
        let padded = str.padding(toLength: length, withPad: " ", startingAt: 0)
        return Array(padded.utf8.prefix(length))
    }

    private func buildRecord(tag: String, version: String, content: Data) -> Data {
        let totalLength = 12 + content.count // tag(6) + version(2) + length(4) + content
        var result = Data()
        // tag (6 bytes, space-padded)
        result.append(contentsOf: Array(tag.padding(toLength: 6, withPad: " ", startingAt: 0).utf8.prefix(6)))
        // version (2 bytes)
        result.append(contentsOf: Array(version.padding(toLength: 2, withPad: "0", startingAt: 0).utf8.prefix(2)))
        // length (4 bytes, zero-padded)
        let lengthStr = String(format: "%04d", totalLength)
        result.append(contentsOf: Array(lengthStr.utf8.prefix(4)))
        // content
        result.append(content)
        return result
    }
}
