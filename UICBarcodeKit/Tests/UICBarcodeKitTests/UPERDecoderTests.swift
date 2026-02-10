import XCTest
@testable import UICBarcodeKit

final class UPERDecoderTests: XCTestCase {

    // MARK: - Boolean Tests (from UperEncodeBooleanTest.java)

    /// Test decoding true: In Java test, encoding produces "C0" hex
    /// Structure: [presence bit = 1][value bit = 1][padding]
    /// C0 = 11000000 -> presence=1, value=1 (true)
    func testDecodeTrue() throws {
        // Java test: TestRecord with optional Boolean value = true -> "C0"
        // C0 = 0b11000000: first bit = presence (1 = present), second bit = value (1 = true)
        let data = Data([0xC0])
        var decoder = UPERDecoder(data: data)

        // Decode presence bit
        let presence = try decoder.decodeBit()
        XCTAssertTrue(presence, "Presence bit should be set")

        // Decode boolean value
        let value = try decoder.decodeBoolean()
        XCTAssertTrue(value, "Value should be true")
    }

    /// Test decoding false: In Java test, encoding produces "80" hex
    /// Structure: [presence bit = 1][value bit = 0][padding]
    /// 80 = 10000000 -> presence=1, value=0 (false)
    func testDecodeFalse() throws {
        // Java test: TestRecord with optional Boolean value = false -> "80"
        // 80 = 0b10000000: first bit = presence (1 = present), second bit = value (0 = false)
        let data = Data([0x80])
        var decoder = UPERDecoder(data: data)

        // Decode presence bit
        let presence = try decoder.decodeBit()
        XCTAssertTrue(presence, "Presence bit should be set")

        // Decode boolean value
        let value = try decoder.decodeBoolean()
        XCTAssertFalse(value, "Value should be false")
    }

    // MARK: - Constrained Integer Tests (from UperEncodeIntegerConstrainedTest.java)

    /// Test decoding constrained integers
    /// Java test: TestRecord with value1(1..999)=63, value2(0..999)=63, value3(63..999)=63 -> "0F83F000"
    func testDecodeConstrainedIntegers() throws {
        // 0F83F000 hex = the encoded representation
        let data = Data([0x0F, 0x83, 0xF0, 0x00])
        var decoder = UPERDecoder(data: data)

        // value1: INTEGER (1..999) = 63
        // Range = 999-1+1 = 999, needs 10 bits
        // Encoded as 63-1 = 62 (offset from min)
        let value1 = try decoder.decodeConstrainedInt(min: 1, max: 999)
        XCTAssertEqual(value1, 63)

        // value2: INTEGER (0..999) = 63
        // Range = 1000, needs 10 bits
        // Encoded as 63-0 = 63
        let value2 = try decoder.decodeConstrainedInt(min: 0, max: 999)
        XCTAssertEqual(value2, 63)

        // value3: INTEGER (63..999) = 63
        // Range = 937, needs 10 bits
        // Encoded as 63-63 = 0
        let value3 = try decoder.decodeConstrainedInt(min: 63, max: 999)
        XCTAssertEqual(value3, 63)
    }

    func testDecodeConstrainedIntSimple() throws {
        // Test decoding a constrained integer 0-255
        let data = Data([0b10000000]) // Value 128
        var decoder = UPERDecoder(data: data)

        let value = try decoder.decodeConstrainedInt(min: 0, max: 255)
        XCTAssertEqual(value, 128)
    }

    // MARK: - Length Determinant Tests

    func testDecodeLengthDeterminant() throws {
        // Short form: length < 128
        let shortData = Data([0b00110010]) // 50
        var decoder1 = UPERDecoder(data: shortData)
        let shortLength = try decoder1.decodeLengthDeterminant()
        XCTAssertEqual(shortLength, 50)

        // Long form: length 128-16383
        let longData = Data([0b10000000, 0b10000010]) // 130 (128 + 2)
        var decoder2 = UPERDecoder(data: longData)
        let longLength = try decoder2.decodeLengthDeterminant()
        XCTAssertEqual(longLength, 130)
    }

    // MARK: - Boolean Tests

    func testDecodeBoolean() throws {
        let trueData = Data([0b10000000])
        var decoder1 = UPERDecoder(data: trueData)
        XCTAssertTrue(try decoder1.decodeBoolean())

        let falseData = Data([0b00000000])
        var decoder2 = UPERDecoder(data: falseData)
        XCTAssertFalse(try decoder2.decodeBoolean())
    }

    // MARK: - Presence Bitmap Tests

    func testDecodePresenceBitmap() throws {
        let data = Data([0b10110000])
        var decoder = UPERDecoder(data: data)

        let bitmap = try decoder.decodePresenceBitmap(count: 4)
        XCTAssertEqual(bitmap, [true, false, true, true])
    }

    // MARK: - Enumerated Tests

    func testDecodeEnumerated() throws {
        // Enumeration with 4 values (needs 2 bits)
        let data = Data([0b01000000]) // Value 1 (in bits: 01)
        var decoder = UPERDecoder(data: data)

        let value = try decoder.decodeEnumerated(rootCount: 4)
        XCTAssertEqual(value, 1)
    }

    // MARK: - Octet String Tests (from UperEncodeOctetStringTest.java)

    /// Test decoding octet string
    /// Java test: OctetString with bytes [0x83, 0xDA] -> "0283DA"
    func testDecodeOctetString() throws {
        // 02 = length (2 bytes), 83DA = data
        let data = Data([0x02, 0x83, 0xDA])
        var decoder = UPERDecoder(data: data)

        let octetString = try decoder.decodeOctetString()
        XCTAssertEqual(octetString.count, 2)
        XCTAssertEqual(octetString[0], 0x83)
        XCTAssertEqual(octetString[1], 0xDA)
    }

    // MARK: - IA5String Tests (from UperEncodeStringTest.java)

    /// Test decoding IA5 string "Meier"
    func testDecodeIA5String() throws {
        // IA5String uses 7-bit encoding per character
        // "Meier" = 5 characters
        // Length prefix + 7-bit characters
        let encoded = encodeIA5String("Meier")
        var decoder = UPERDecoder(data: encoded)

        let result = try decoder.decodeIA5String()
        XCTAssertEqual(result, "Meier")
    }

    /// Helper to encode IA5String for testing
    private func encodeIA5String(_ string: String) -> Data {
        // Calculate needed bits: 8 for length + 7 per character
        let neededBits = 8 + (string.count * 7)
        var buffer = BitBuffer.allocate(bits: neededBits)

        // Length determinant (< 128)
        try? buffer.putBits(UInt64(string.count), count: 8)

        // Each character as 7 bits
        for char in string.utf8 {
            try? buffer.putBits(UInt64(char), count: 7)
        }

        return buffer.toData()
    }

    // MARK: - Multiple Field Tests

    /// Test decoding sequence with multiple optional fields
    func testDecodeSequenceWithOptionalFields() throws {
        // Simulate a sequence with 3 optional fields, only 1st and 3rd present
        // 3 bits for presence + 8 bits for field 0 + 8 bits for field 2 = 19 bits
        var buffer = BitBuffer.allocate(bits: 24)
        try buffer.putBit(true)   // field 0 present
        try buffer.putBit(false)  // field 1 absent
        try buffer.putBit(true)   // field 2 present

        // Field 0 value: constrained integer 0-255 = 100
        try buffer.putBits(100, count: 8)

        // Field 2 value: constrained integer 0-255 = 200
        try buffer.putBits(200, count: 8)

        var decoder = UPERDecoder(data: buffer.toData())

        let presence = try decoder.decodePresenceBitmap(count: 3)
        XCTAssertEqual(presence, [true, false, true])

        // Decode field 0
        XCTAssertTrue(presence[0])
        let field0 = try decoder.decodeConstrainedInt(min: 0, max: 255)
        XCTAssertEqual(field0, 100)

        // Field 1 skipped
        XCTAssertFalse(presence[1])

        // Decode field 2
        XCTAssertTrue(presence[2])
        let field2 = try decoder.decodeConstrainedInt(min: 0, max: 255)
        XCTAssertEqual(field2, 200)
    }

    // MARK: - Bit Position Tests

    func testBitPositionTracking() throws {
        let data = Data([0xFF, 0x00, 0xAA])
        var decoder = UPERDecoder(data: data)

        XCTAssertEqual(decoder.position, 0)

        _ = try decoder.decodeBit()
        XCTAssertEqual(decoder.position, 1)

        _ = try decoder.decodeBoolean()
        XCTAssertEqual(decoder.position, 2)

        // Decode 6 more bits to align to byte
        for _ in 0..<6 {
            _ = try decoder.decodeBit()
        }
        XCTAssertEqual(decoder.position, 8)
    }

    // MARK: - Edge Cases

    func testDecodeEmptyOctetString() throws {
        let data = Data([0x00]) // Length 0
        var decoder = UPERDecoder(data: data)

        let result = try decoder.decodeOctetString()
        XCTAssertEqual(result.count, 0)
    }

    func testDecodeConstrainedIntMinValue() throws {
        // Range 100-200, decode min value 100
        var buffer = BitBuffer.allocate(bits: 8)
        try buffer.putBits(0, count: 7) // 0 offset = min value

        var decoder = UPERDecoder(data: buffer.toData())
        let value = try decoder.decodeConstrainedInt(min: 100, max: 200)
        XCTAssertEqual(value, 100)
    }

    func testDecodeConstrainedIntMaxValue() throws {
        // Range 100-200, decode max value 200
        var buffer = BitBuffer.allocate(bits: 8)
        try buffer.putBits(100, count: 7) // 100 offset = max value

        var decoder = UPERDecoder(data: buffer.toData())
        let value = try decoder.decodeConstrainedInt(min: 100, max: 200)
        XCTAssertEqual(value, 200)
    }
}
