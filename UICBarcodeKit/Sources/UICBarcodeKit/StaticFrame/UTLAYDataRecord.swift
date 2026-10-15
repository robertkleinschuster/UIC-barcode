import Foundation

/// Layout data record (U_TLAY)
/// Java ref: UTLAYDataRecord.java
/// Content layout: layoutStandard(4), numberOfElements(4), then for each element:
///   line(2), column(2), height(2), width(2), format(1), textLength(4), text(textLength bytes UTF-8)
public struct UTLAYDataRecord: DataRecordProtocol {
    public let tag: String
    public let version: String
    public let content: Data

    public let layoutStandard: String
    public var elements: [LayoutElement] = []

    public init(data: Data) throws {
        let offset = 12 // Skip tag, version, length

        guard data.count >= offset else {
            throw UICBarcodeError.invalidData("U_TLAY record too short")
        }

        self.tag = String(data: data[0..<6], encoding: .ascii) ?? "U_TLAY"
        self.version = String(data: data[6..<8], encoding: .ascii) ?? "01"
        self.content = Data(data[offset...])

        // Parse layout content
        if content.count >= 4 {
            self.layoutStandard = UTLAYDataRecord.decodeString(content, offset: 0, length: 4).trimmingCharacters(in: .whitespaces)
        } else {
            self.layoutStandard = ""
        }

        // Number of elements (4 bytes at offset 4)
        guard content.count >= 8 else { return }
        let numStr = UTLAYDataRecord.decodeString(content, offset: 4, length: 4).trimmingCharacters(in: .whitespaces)
        let numElements = Int(numStr) ?? 0

        guard numElements > 0 else { return }

        // Try standard decoding first (text length = byte length)
        do {
            self.elements = try UTLAYDataRecord.decodeFields(content: content, startOffset: 8, numElements: numElements)
        } catch {
            // Fallback: DSB/SJ UTF-8 error recovery (text length = character length, not byte length)
            if let fallbackElements = UTLAYDataRecord.decodeFieldsWithCharacterLength(
                content: content, startOffset: 8, numElements: numElements, contentLength: content.count
            ) {
                self.elements = fallbackElements
            }
            // If fallback also fails, elements remains empty
        }
    }

    /// Standard field decoding where text length is in bytes
    private static func decodeFields(content: Data, startOffset: Int, numElements: Int) throws -> [LayoutElement] {
        var elements = [LayoutElement]()
        var offset = startOffset
        let remainingTotal = content.count

        for _ in 0..<numElements {
            guard remainingTotal - offset > 13 else { break } // Minimum: 2+2+2+2+1+4 = 13 bytes header

            let line = parseInt(decodeString(content, offset: offset, length: 2))
            offset += 2
            let column = parseInt(decodeString(content, offset: offset, length: 2))
            offset += 2
            let height = parseInt(decodeString(content, offset: offset, length: 2))
            offset += 2
            let width = parseInt(decodeString(content, offset: offset, length: 2))
            offset += 2
            let formatVal = parseInt(decodeString(content, offset: offset, length: 1))
            offset += 1
            let textLength = parseInt(decodeString(content, offset: offset, length: 4))
            offset += 4

            var text = ""
            if textLength > 0 {
                guard offset + textLength <= content.count else {
                    throw UICBarcodeError.invalidData("U_TLAY text extends beyond content")
                }
                let textBytes = Data(content[offset..<(offset + textLength)])
                text = String(data: textBytes, encoding: .utf8)
                    ?? String(data: textBytes, encoding: .isoLatin1)
                    ?? "unsupported character set"
                offset += textLength
            }

            let format = LayoutFormatType(rawValue: formatVal) ?? .normal
            elements.append(LayoutElement(line: line, column: column, width: width, height: height, format: format, text: text))
        }

        return elements
    }

    /// Fallback decoding for DSB/SJ where text length is in characters, not bytes
    /// Returns nil if decoding fails
    private static func decodeFieldsWithCharacterLength(
        content: Data, startOffset: Int, numElements: Int, contentLength: Int
    ) -> [LayoutElement]? {
        var elements = [LayoutElement]()
        var offset = startOffset

        for _ in 0..<numElements {
            guard content.count - offset > 13 else { break }

            guard let line = parseIntOrNil(decodeString(content, offset: offset, length: 2)) else { return nil }
            offset += 2
            guard let column = parseIntOrNil(decodeString(content, offset: offset, length: 2)) else { return nil }
            offset += 2
            guard let height = parseIntOrNil(decodeString(content, offset: offset, length: 2)) else { return nil }
            offset += 2
            guard let width = parseIntOrNil(decodeString(content, offset: offset, length: 2)) else { return nil }
            offset += 2
            guard let formatVal = parseIntOrNil(decodeString(content, offset: offset, length: 1)) else { return nil }
            offset += 1
            guard let charLength = parseIntOrNil(decodeString(content, offset: offset, length: 4)) else { return nil }
            offset += 4

            var text = ""
            if charLength > 0 {
                // Try to find the right number of bytes that decode to charLength characters
                guard let decoded = getUnicodeString(content: content, offset: offset, characterLength: charLength) else {
                    return nil
                }
                text = decoded.text
                offset += decoded.byteLength
            }

            let format = LayoutFormatType(rawValue: formatVal) ?? .normal
            elements.append(LayoutElement(line: line, column: column, width: width, height: height, format: format, text: text))
        }

        return elements
    }

    /// Try to decode a UTF-8 string of exactly `characterLength` characters from the byte data.
    /// If no exact match is found, returns the longest valid UTF-8 string (matching Java behavior
    /// where buggy encoders use character count instead of byte count for length fields).
    private static func getUnicodeString(content: Data, offset: Int, characterLength: Int) -> (text: String, byteLength: Int)? {
        let maxBytes = min(characterLength * 4, content.count - offset)
        guard maxBytes > 0 else { return nil }

        var lastValid: (text: String, byteLength: Int)?
        for byteLen in 1...maxBytes {
            guard offset + byteLen <= content.count else { break }
            let bytes = Data(content[offset..<(offset + byteLen)])
            if let str = String(data: bytes, encoding: .utf8) {
                lastValid = (str, byteLen)
                if str.count == characterLength {
                    return (str, byteLen)
                }
            }
        }
        return lastValid
    }

    /// Decode a string from byte data using ISO-8859-1 (matching Java behavior)
    private static func decodeString(_ data: Data, offset: Int, length: Int) -> String {
        var chars = [Character]()
        chars.reserveCapacity(length)
        for i in 0..<length {
            guard offset + i < data.count else { break }
            chars.append(Character(UnicodeScalar(data[offset + i])))
        }
        return String(chars)
    }

    /// Parse an integer from a trimmed string, returning 0 on failure
    private static func parseInt(_ str: String) -> Int {
        return Int(str.trimmingCharacters(in: .whitespaces)) ?? 0
    }

    /// Parse an integer from a trimmed string, returning nil on failure
    private static func parseIntOrNil(_ str: String) -> Int? {
        return Int(str.trimmingCharacters(in: .whitespaces))
    }
}

// MARK: - UTLAYDataRecord Encoding

extension UTLAYDataRecord {

    /// Encode the U_TLAY record to bytes.
    /// Content: layoutStandard(4) + numberOfElements(4) + elements
    /// Each element: line(2) + column(2) + height(2) + width(2) + format(1) + textLength(4) + text(UTF-8)
    public func encode() throws -> Data {
        var contentData = Data()

        // layoutStandard (4 bytes)
        let standardStr = layoutStandard.padding(toLength: 4, withPad: " ", startingAt: 0)
        contentData.append(contentsOf: Array(standardStr.utf8.prefix(4)))

        // numberOfElements (4 bytes)
        let numStr = String(format: "%04d", elements.count)
        contentData.append(contentsOf: Array(numStr.utf8.prefix(4)))

        // Elements
        for element in elements {
            let lineStr = String(format: "%02d", element.line)
            contentData.append(contentsOf: Array(lineStr.utf8.prefix(2)))

            let colStr = String(format: "%02d", element.column)
            contentData.append(contentsOf: Array(colStr.utf8.prefix(2)))

            let heightStr = String(format: "%02d", element.height)
            contentData.append(contentsOf: Array(heightStr.utf8.prefix(2)))

            let widthStr = String(format: "%02d", element.width)
            contentData.append(contentsOf: Array(widthStr.utf8.prefix(2)))

            let formatStr = String(element.format.rawValue)
            contentData.append(contentsOf: Array(formatStr.utf8.prefix(1)))

            let textBytes = Array(element.text.utf8)
            let textLenStr = String(format: "%04d", textBytes.count)
            contentData.append(contentsOf: Array(textLenStr.utf8.prefix(4)))
            contentData.append(contentsOf: textBytes)
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
