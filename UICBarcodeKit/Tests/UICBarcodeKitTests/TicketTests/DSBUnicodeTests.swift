import XCTest
@testable import UICBarcodeKit

/// DSB (Danish State Railways) Unicode Length Error Tests
/// Translated from Java: DSBUnicodeLengthErrorTest.java
/// Tests that Static Frame layout handles UTF-8 characters correctly
final class DSBUnicodeTests: XCTestCase {

    // MARK: - Test Data

    /// Static frame ticket with Unicode characters (from DSBUnicodeLengthErrorTest.java)
    static let ticketBase64 = "I1VUMDExMTg2MDAwMDEwLAIUQ/owLvBw503VxO38HljgZC77oe4CFAELL" +
        "FSx+ASz93rCD7/hqq2Pc1wYAAAAADAzMzd42lVRy2qDUBD9FdehTc94n24KpkoSDDGoCW" +
        "QVLAoNiC1J6KJf1n1/rHMVfFx8zJkzjzNzj5dNHEYgQAkiq5WKj6uTibzJYZJ8+IqUIlm" +
        "VdXu8FLvwzEkayN4KHxD8MiYI/kNE+YqhBRE5P2VxHmensNime/hQHCddnHQdQcpnhysA" +
        "Z3AX/ioH1aEpqzt3ocFDcsm24T7O54ovmDcDD7NUhnEw5Un0WgGdVnV7r2FoVkCMCp5fY" +
        "eZQCzkMkvz9vtftR/ndehuOk9Mi3RgzlWrO21FlsHSqNaa8tgPymbMTzk52W6RrxuPE7oI" +
        "kLJlhq6d0vYf19ZDCG4AVo7zDLoxyWGmHCCU8BF1Ef6hXFjg72CZJnJ3XccYufvomyB/Xp" +
        "ql/Ptvae/HyR9lW5a3yJt6vuq2a+kaiW4x1WfZwu969KElI6K5Y12rhDuEJ+AfiQJFI"

    // MARK: - Tests

    /// Test that layout with Unicode (Danish "ø") is decoded correctly
    func testUnicodeLayoutDecoding() throws {
        let data = Data(base64Encoded: Self.ticketBase64)!

        let barcodeDecoder = UICBarcodeDecoder()
        let barcode = try barcodeDecoder.decode(data)

        // Verify it's a static frame
        if case .staticFrame = barcode.frameType {
            // OK
        } else {
            XCTFail("Expected static frame")
        }

        // Get the static frame
        let frame = try XCTUnwrap(barcode.staticFrame)

        // Should have layout records
        XCTAssertFalse(frame.layoutRecords.isEmpty, "Should have layout records")

        // Get the first layout record
        let layout = frame.layoutRecords.first!

        // Should have 32 elements (per Java test)
        XCTAssertEqual(layout.elements.count, 32, "Layout should have 32 elements")

        // Element at index 13 should contain "København H" (with proper UTF-8 encoding of "ø")
        let element13 = layout.elements[13]
        XCTAssertEqual(element13.text, "København H", "Element 13 should contain Danish station name with ø")
    }
}
