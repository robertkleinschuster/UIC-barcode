import XCTest
@testable import UICBarcodeKit

final class UPEREncoderTests: XCTestCase {

    // MARK: - Constrained Integer Round-Trip

    func testConstrainedIntRoundTrip() throws {
        let testCases: [(value: Int, min: Int64, max: Int64)] = [
            (0, 0, 255),
            (255, 0, 255),
            (100, 0, 255),
            (0, 0, 0),          // single-value range: 0 bits
            (5, 5, 5),          // single-value range: 0 bits
            (2024, 2016, 2269),
            (1, 1, 366),
            (366, 1, 366),
            (0, 0, 1439),
            (1439, 0, 1439),
            (1, 1, 32000),
            (32000, 1, 32000),
            (0, 0, 65535),
            (65535, 0, 65535),
            (1, 1, 9999999),
        ]

        for tc in testCases {
            var encoder = UPEREncoder()
            try encoder.encodeConstrainedInt(tc.value, min: tc.min, max: tc.max)
            let data = encoder.toData()
            var decoder = UPERDecoder(data: data)
            let decoded = try decoder.decodeConstrainedInt(min: tc.min, max: tc.max)
            XCTAssertEqual(decoded, tc.value, "Failed for value=\(tc.value) min=\(tc.min) max=\(tc.max)")
        }
    }

    func testConstrainedIntWithExtensionMarker() throws {
        var encoder = UPEREncoder()
        try encoder.encodeConstrainedInt(50, min: 0, max: 100, hasExtensionMarker: true)
        let data = encoder.toData()
        var decoder = UPERDecoder(data: data)
        let decoded = try decoder.decodeConstrainedInt(min: 0, max: 100, hasExtensionMarker: true)
        XCTAssertEqual(decoded, 50)
    }

    // MARK: - Unconstrained Integer Round-Trip

    func testUnconstrainedIntegerRoundTrip() throws {
        let testCases: [Int64] = [0, 1, -1, 127, -128, 128, -129, 256, 1000, -1000, 32767, -32768, 100000]

        for value in testCases {
            var encoder = UPEREncoder()
            try encoder.encodeUnconstrainedInteger(value)
            let data = encoder.toData()
            var decoder = UPERDecoder(data: data)
            let decoded = try decoder.decodeUnconstrainedInteger()
            XCTAssertEqual(decoded, value, "Failed for value=\(value)")
        }
    }

    // MARK: - Semi-Constrained Integer Round-Trip

    func testSemiConstrainedIntegerRoundTrip() throws {
        let testCases: [(value: Int64, min: Int64)] = [
            (0, 0),
            (100, 0),
            (255, 0),
            (256, 0),
            (10, 5),
            (5, 5),
        ]

        for tc in testCases {
            var encoder = UPEREncoder()
            try encoder.encodeSemiConstrainedInteger(tc.value, min: tc.min)
            let data = encoder.toData()
            var decoder = UPERDecoder(data: data)
            let decoded = try decoder.decodeSemiConstrainedInteger(min: tc.min)
            XCTAssertEqual(decoded, tc.value, "Failed for value=\(tc.value) min=\(tc.min)")
        }
    }

    // MARK: - Length Determinant Round-Trip

    func testLengthDeterminantRoundTrip() throws {
        let testCases = [0, 1, 5, 50, 127, 128, 200, 1000, 16383]

        for length in testCases {
            var encoder = UPEREncoder()
            try encoder.encodeLengthDeterminant(length)
            let data = encoder.toData()
            var decoder = UPERDecoder(data: data)
            let decoded = try decoder.decodeLengthDeterminant()
            XCTAssertEqual(decoded, length, "Failed for length=\(length)")
        }
    }

    // MARK: - Boolean Round-Trip

    func testBooleanRoundTrip() throws {
        for value in [true, false] {
            var encoder = UPEREncoder()
            try encoder.encodeBoolean(value)
            let data = encoder.toData()
            var decoder = UPERDecoder(data: data)
            let decoded = try decoder.decodeBoolean()
            XCTAssertEqual(decoded, value)
        }
    }

    // MARK: - Enumerated Round-Trip

    func testEnumeratedRoundTrip() throws {
        let rootCount = 5
        for value in 0..<rootCount {
            var encoder = UPEREncoder()
            try encoder.encodeEnumerated(value, rootCount: rootCount)
            let data = encoder.toData()
            var decoder = UPERDecoder(data: data)
            let decoded = try decoder.decodeEnumerated(rootCount: rootCount)
            XCTAssertEqual(decoded, value, "Failed for enumerated value=\(value)")
        }
    }

    func testEnumeratedWithExtensionMarker() throws {
        let rootCount = 3
        for value in 0..<rootCount {
            var encoder = UPEREncoder()
            try encoder.encodeEnumerated(value, rootCount: rootCount, hasExtensionMarker: true)
            let data = encoder.toData()
            var decoder = UPERDecoder(data: data)
            let decoded = try decoder.decodeEnumerated(rootCount: rootCount, hasExtensionMarker: true)
            XCTAssertEqual(decoded, value, "Failed for enumerated value=\(value) with extension marker")
        }
    }

    // MARK: - IA5String Round-Trip

    func testIA5StringUnconstrainedRoundTrip() throws {
        let testStrings = ["", "A", "Hello", "test123", "foo@bar"]

        for str in testStrings {
            var encoder = UPEREncoder()
            try encoder.encodeIA5String(str)
            let data = encoder.toData()
            var decoder = UPERDecoder(data: data)
            let decoded = try decoder.decodeIA5String()
            XCTAssertEqual(decoded, str, "Failed for IA5String '\(str)'")
        }
    }

    func testIA5StringFixedLengthRoundTrip() throws {
        let constraint = ASN1StringConstraint(type: .ia5String, fixedLength: 3)
        let str = "EUR"

        var encoder = UPEREncoder()
        try encoder.encodeIA5String(str, constraint: constraint)
        let data = encoder.toData()
        var decoder = UPERDecoder(data: data)
        let decoded = try decoder.decodeIA5String(constraint: constraint)
        XCTAssertEqual(decoded, str)
    }

    func testIA5StringSizeRangeRoundTrip() throws {
        let constraint = ASN1StringConstraint(type: .ia5String, minLength: 1, maxLength: 10)
        let str = "Hello"

        var encoder = UPEREncoder()
        try encoder.encodeIA5String(str, constraint: constraint)
        let data = encoder.toData()
        var decoder = UPERDecoder(data: data)
        let decoded = try decoder.decodeIA5String(constraint: constraint)
        XCTAssertEqual(decoded, str)
    }

    // MARK: - UTF8String Round-Trip

    func testUTF8StringRoundTrip() throws {
        let testStrings = ["", "Hello", "Ünited", "日本語", "Ça va?"]

        for str in testStrings {
            var encoder = UPEREncoder()
            try encoder.encodeUTF8String(str)
            let data = encoder.toData()
            var decoder = UPERDecoder(data: data)
            let decoded = try decoder.decodeUTF8String()
            XCTAssertEqual(decoded, str, "Failed for UTF8String '\(str)'")
        }
    }

    // MARK: - Octet String Round-Trip

    func testOctetStringUnconstrainedRoundTrip() throws {
        let testData = Data([0x01, 0x02, 0x03, 0xFF, 0x00])

        var encoder = UPEREncoder()
        try encoder.encodeOctetString(testData)
        let data = encoder.toData()
        var decoder = UPERDecoder(data: data)
        let decoded = try decoder.decodeOctetString()
        XCTAssertEqual(decoded, testData)
    }

    func testOctetStringFixedSizeRoundTrip() throws {
        let testData = Data([0xAA, 0xBB, 0xCC])

        var encoder = UPEREncoder()
        try encoder.encodeOctetString(testData, minSize: 3, maxSize: 3)
        let data = encoder.toData()
        var decoder = UPERDecoder(data: data)
        let decoded = try decoder.decodeOctetString(minSize: 3, maxSize: 3)
        XCTAssertEqual(decoded, testData)
    }

    func testOctetStringConstrainedRoundTrip() throws {
        let testData = Data([0x01, 0x02, 0x03, 0x04, 0x05])

        var encoder = UPEREncoder()
        try encoder.encodeOctetString(testData, minSize: 1, maxSize: 10)
        let data = encoder.toData()
        var decoder = UPERDecoder(data: data)
        let decoded = try decoder.decodeOctetString(minSize: 1, maxSize: 10)
        XCTAssertEqual(decoded, testData)
    }

    // MARK: - Presence Bitmap Round-Trip

    func testPresenceBitmapRoundTrip() throws {
        let bitmaps: [[Bool]] = [
            [true, false, true],
            [false, false, false, false],
            [true, true, true, true, true],
            [true, false, false, true, false, true, true, false, false, true, false, false, true],
        ]

        for bitmap in bitmaps {
            var encoder = UPEREncoder()
            try encoder.encodePresenceBitmap(bitmap)
            let data = encoder.toData()
            var decoder = UPERDecoder(data: data)
            let decoded = try decoder.decodePresenceBitmap(count: bitmap.count)
            XCTAssertEqual(decoded, bitmap, "Failed for bitmap \(bitmap)")
        }
    }

    // MARK: - Sequence Of Round-Trip

    func testSequenceOfCountRoundTrip() throws {
        let constraint = ASN1SequenceOfConstraint(minSize: 1, maxSize: 50)
        let count = 7

        var encoder = UPEREncoder()
        try encoder.encodeSequenceOfCount(count, constraint: constraint)
        let data = encoder.toData()
        var decoder = UPERDecoder(data: data)
        let decoded = try decoder.decodeConstrainedInt(min: 1, max: 50)
        XCTAssertEqual(decoded, count)
    }

    func testSequenceOfIntRoundTrip() throws {
        let elements = [10, 20, 30, 40, 50]
        let elementConstraint = ASN1IntegerConstraint(min: 0, max: 100)
        let sizeConstraint = ASN1SequenceOfConstraint(minSize: 1, maxSize: 10)

        var encoder = UPEREncoder()
        try encoder.encodeSequenceOfInt(elements, elementConstraint: elementConstraint, sizeConstraint: sizeConstraint)
        let data = encoder.toData()
        var decoder = UPERDecoder(data: data)
        let decoded = try decoder.decodeSequenceOfInt(elementConstraint: elementConstraint, sizeConstraint: sizeConstraint)
        XCTAssertEqual(decoded, elements)
    }

    // MARK: - Choice Index Round-Trip

    func testChoiceIndexRoundTrip() throws {
        let rootCount = 4
        for index in 0..<rootCount {
            var encoder = UPEREncoder()
            try encoder.encodeChoiceIndex(index, rootCount: rootCount)
            let data = encoder.toData()
            var decoder = UPERDecoder(data: data)
            let decoded = try decoder.decodeChoiceIndex(rootCount: rootCount)
            XCTAssertEqual(decoded, index, "Failed for choice index=\(index)")
        }
    }

    func testChoiceIndexWithExtensionMarker() throws {
        let rootCount = 3
        for index in 0..<rootCount {
            var encoder = UPEREncoder()
            try encoder.encodeChoiceIndex(index, rootCount: rootCount, hasExtensionMarker: true)
            let data = encoder.toData()
            var decoder = UPERDecoder(data: data)
            let decoded = try decoder.decodeChoiceIndex(rootCount: rootCount, hasExtensionMarker: true)
            XCTAssertEqual(decoded, index, "Failed for choice index=\(index) with extension marker")
        }
    }

    // MARK: - Bit String Round-Trip

    func testBitStringRoundTrip() throws {
        let bits: [Bool] = [true, false, true, true, false, false, true, false]

        var encoder = UPEREncoder()
        try encoder.encodeBitString(bits)
        let data = encoder.toData()
        var decoder = UPERDecoder(data: data)
        let decoded = try decoder.decodeBitString()
        XCTAssertEqual(decoded, bits)
    }

    // MARK: - Combined Encoding Round-Trip

    func testMultipleFieldsRoundTrip() throws {
        // Simulate encoding a small SEQUENCE with mixed fields
        var encoder = UPEREncoder()

        // Extension marker
        try encoder.encodeBit(false)
        // Presence bitmap: 3 optional fields, first and third present
        try encoder.encodePresenceBitmap([true, false, true])
        // First optional: constrained int
        try encoder.encodeConstrainedInt(42, min: 0, max: 100)
        // Mandatory: boolean
        try encoder.encodeBoolean(true)
        // Third optional: IA5String
        try encoder.encodeIA5String("AB", constraint: ASN1StringConstraint(type: .ia5String, fixedLength: 2))

        let data = encoder.toData()
        var decoder = UPERDecoder(data: data)

        let hasExt = try decoder.decodeBit()
        XCTAssertFalse(hasExt)
        let presence = try decoder.decodePresenceBitmap(count: 3)
        XCTAssertEqual(presence, [true, false, true])
        let intVal = try decoder.decodeConstrainedInt(min: 0, max: 100)
        XCTAssertEqual(intVal, 42)
        let boolVal = try decoder.decodeBoolean()
        XCTAssertTrue(boolVal)
        let strVal = try decoder.decodeIA5String(constraint: ASN1StringConstraint(type: .ia5String, fixedLength: 2))
        XCTAssertEqual(strVal, "AB")
    }
}
