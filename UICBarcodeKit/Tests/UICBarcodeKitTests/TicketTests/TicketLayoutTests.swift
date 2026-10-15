import XCTest
@testable import UICBarcodeKit

/// Ticket Layout (UTLAY) Tests
/// Translated from Java: TicketLayoutTest.java
/// Tests UTLAYDataRecord encoding and decoding
final class TicketLayoutTests: XCTestCase {

    // MARK: - Test Data

    /// Expected encoded hex from Java TicketLayoutTest
    /// U_TLAY + version "01" + length "0040" + "RCT2" + "0001" (1 element)
    /// + "01" (line) + "01" (col) + "01" (height) + "20" (width) + "0" (format normal)
    /// + "0007" (text length in bytes) + "Müller" (7 UTF-8 bytes: M ü=2bytes l l e r)
    static let expectedHex = "555F544C41593031303034305243543230303031303130313031323030303030374DC3BC6C6C6572"

    // MARK: - Tests

    /// Test UTLAY round-trip: decode from expected hex, verify fields, re-encode
    func testTicketLayoutRoundTrip() throws {
        // Decode from expected hex
        let data = hexToData(Self.expectedHex)
        let layout = try UTLAYDataRecord(data: data)

        // Verify layout standard
        XCTAssertEqual(layout.layoutStandard, "RCT2")

        // Verify elements
        XCTAssertEqual(layout.elements.count, 1)

        let element = layout.elements.first!
        XCTAssertEqual(element.line, 1)
        XCTAssertEqual(element.column, 1)
        XCTAssertEqual(element.height, 1)
        XCTAssertEqual(element.width, 20)
        XCTAssertEqual(element.format, .normal)
        XCTAssertEqual(element.text, "Müller", "UTF-8 text should decode correctly")

        // Re-encode and verify hex matches
        let reEncoded = try layout.encode()
        let reEncodedHex = reEncoded.map { String(format: "%02X", $0) }.joined()
        XCTAssertEqual(reEncodedHex, Self.expectedHex, "Round-trip encoding should match original hex")
    }

    /// Test UTLAY tag and version
    func testTicketLayoutMetadata() throws {
        let data = hexToData(Self.expectedHex)
        let layout = try UTLAYDataRecord(data: data)

        XCTAssertEqual(layout.tag, "U_TLAY")
        XCTAssertEqual(layout.version, "01")
    }

    // MARK: - Helper

    private func hexToData(_ hex: String) -> Data {
        let cleanHex = hex.replacingOccurrences(of: " ", with: "")
                          .replacingOccurrences(of: "\n", with: "")
        var data = Data()
        var index = cleanHex.startIndex
        while index < cleanHex.endIndex {
            let nextIndex = cleanHex.index(index, offsetBy: 2)
            if let byte = UInt8(cleanHex[index..<nextIndex], radix: 16) {
                data.append(byte)
            }
            index = nextIndex
        }
        return data
    }
}
