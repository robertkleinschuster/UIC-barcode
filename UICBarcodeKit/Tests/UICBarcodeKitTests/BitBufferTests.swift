import XCTest
@testable import UICBarcodeKit

final class BitBufferTests: XCTestCase {

    func testGetBit() throws {
        let data = Data([0b10110100])
        var buffer = BitBuffer(data: data)

        XCTAssertTrue(try buffer.getBit())   // 1
        XCTAssertFalse(try buffer.getBit())  // 0
        XCTAssertTrue(try buffer.getBit())   // 1
        XCTAssertTrue(try buffer.getBit())   // 1
        XCTAssertFalse(try buffer.getBit())  // 0
        XCTAssertTrue(try buffer.getBit())   // 1
        XCTAssertFalse(try buffer.getBit())  // 0
        XCTAssertFalse(try buffer.getBit())  // 0
    }

    func testGetBits() throws {
        let data = Data([0b10110100, 0b11001010])
        var buffer = BitBuffer(data: data)

        let first4 = try buffer.getBits(4)
        XCTAssertEqual(first4, 0b1011)

        let next8 = try buffer.getBits(8)
        XCTAssertEqual(next8, 0b01001100)
    }

    func testGetInteger() throws {
        let data = Data([0xFF, 0x00, 0xAB])
        let buffer = BitBuffer(data: data)

        let value = try buffer.getInteger(at: 0, length: 8)
        XCTAssertEqual(value, 255)

        let value2 = try buffer.getInteger(at: 8, length: 8)
        XCTAssertEqual(value2, 0)

        let value3 = try buffer.getInteger(at: 4, length: 8)
        XCTAssertEqual(value3, 0xF0)
    }

    func testRemaining() throws {
        let data = Data([0xFF, 0xFF])
        var buffer = BitBuffer(data: data)

        XCTAssertEqual(buffer.remaining, 16)

        _ = try buffer.getBits(5)
        XCTAssertEqual(buffer.remaining, 11)
    }

    func testBufferUnderflow() {
        let data = Data([0xFF])
        var buffer = BitBuffer(data: data)

        XCTAssertThrowsError(try buffer.getBits(16)) { error in
            guard case UICBarcodeError.bufferUnderflow = error else {
                XCTFail("Expected bufferUnderflow error")
                return
            }
        }
    }
}
