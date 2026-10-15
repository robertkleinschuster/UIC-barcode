import XCTest
@testable import UICBarcodeKit

/// Debug test to trace UPER decoding step by step
final class DebugDecodingTest: XCTestCase {

    /// Debug trace of decoding - try full decode
    func testFullDecode() throws {
        let data = TestTicketsV3.openTicketComplexData

        print("=== Attempting full UicRailTicketData decode ===")
        print("Data size: \(data.count) bytes")

        var decoder = UPERDecoder(data: data)

        do {
            let ticket = try UicRailTicketData(from: &decoder)
            print("SUCCESS: UicRailTicketData decoded!")
            print("  issuingYear: \(ticket.issuingDetail.issuingYear)")
            print("  issuingDay: \(ticket.issuingDetail.issuingDay)")
            print("  travelerDetail: \(ticket.travelerDetail != nil ? "present" : "nil")")
            print("  transportDocument count: \(ticket.transportDocument?.count ?? 0)")
        } catch {
            print("FAILED: \(error)")
            print("  at position: \(decoder.position)")
            throw error
        }
    }

    /// Debug manual trace to find the issue
    func testManualTrace() throws {
        let hex = TestTicketsV3.openTicketComplexHex
        let data = TestTicketsV3.hexToData(hex)

        print("=== Manual bit-by-bit trace ===")
        print("First 10 bytes: ", terminator: "")
        for byte in data.prefix(10) {
            print(String(format: "%02X ", byte), terminator: "")
        }
        print("")

        var decoder = UPERDecoder(data: data)

        // UicRailTicketData
        let uicExt = try decoder.decodeBit()
        print("pos \(decoder.position): UicRailTicketData ext = \(uicExt)")

        let uicPresence = try decoder.decodePresenceBitmap(count: 4)
        print("pos \(decoder.position): UicRailTicketData presence = \(uicPresence)")

        // IssuingData
        let issuingExt = try decoder.decodeBit()
        print("pos \(decoder.position): IssuingData ext = \(issuingExt)")

        let issuingPresence = try decoder.decodePresenceBitmap(count: 13)
        print("pos \(decoder.position): IssuingData presence = \(issuingPresence)")

        // Decode optional fields before mandatory fields
        if issuingPresence[0] {
            let v = try decoder.decodeConstrainedInt(min: 1, max: 32000)
            print("pos \(decoder.position): securityProviderNum = \(v)")
        }
        if issuingPresence[1] {
            let v = try decoder.decodeIA5String()
            print("pos \(decoder.position): securityProviderIA5 = '\(v)'")
        }
        if issuingPresence[2] {
            let v = try decoder.decodeConstrainedInt(min: 1, max: 32000)
            print("pos \(decoder.position): issuerNum = \(v)")
        }
        if issuingPresence[3] {
            let v = try decoder.decodeIA5String()
            print("pos \(decoder.position): issuerIA5 = '\(v)'")
        }

        let issuingYear = try decoder.decodeConstrainedInt(min: 2016, max: 2269)
        print("pos \(decoder.position): issuingYear = \(issuingYear)")

        let issuingDay = try decoder.decodeConstrainedInt(min: 1, max: 366)
        print("pos \(decoder.position): issuingDay = \(issuingDay)")

        let issuingTime = try decoder.decodeConstrainedInt(min: 0, max: 1439)
        print("pos \(decoder.position): issuingTime = \(issuingTime)")

        if issuingPresence[4] {
            let v = try decoder.decodeUTF8String()
            print("pos \(decoder.position): issuerName = '\(v)'")
        }

        let specimen = try decoder.decodeBoolean()
        print("pos \(decoder.position): specimen = \(specimen)")

        let securePaperTicket = try decoder.decodeBoolean()
        print("pos \(decoder.position): securePaperTicket = \(securePaperTicket)")

        let activated = try decoder.decodeBoolean()
        print("pos \(decoder.position): activated = \(activated)")

        if issuingPresence[5] {
            let v = try decoder.decodeIA5String(constraint: ASN1StringConstraint(type: .ia5String, fixedLength: 3))
            print("pos \(decoder.position): currency = '\(v)'")
        }
        if issuingPresence[6] {
            let v = try decoder.decodeConstrainedInt(min: 1, max: 3)
            print("pos \(decoder.position): currencyFract = \(v)")
        }

        // Check what presence bits indicate
        print("\nPresence interpretation:")
        print("  [0] securityProviderNum: \(issuingPresence[0])")
        print("  [1] securityProviderIA5: \(issuingPresence[1])")
        print("  [2] issuerNum: \(issuingPresence[2])")
        print("  [3] issuerIA5: \(issuingPresence[3])")
        print("  [4] issuerName: \(issuingPresence[4])")
        print("  [5] currency: \(issuingPresence[5])")
        print("  [6] currencyFract: \(issuingPresence[6])")
        print("  [7] issuerPNR: \(issuingPresence[7])")
        print("  [8] extensionData: \(issuingPresence[8])")
        print("  [9] issuedOnTrainNum: \(issuingPresence[9])")
        print("  [10] issuedOnTrainIA5: \(issuingPresence[10])")
        print("  [11] issuedOnLine: \(issuingPresence[11])")
        print("  [12] pointOfSale: \(issuingPresence[12])")

        // Decode optional fields
        if issuingPresence[7] {
            print("\nAttempting issuerPNR decode at position \(decoder.position)...")
            let issuerPNR = try decoder.decodeIA5String()
            print("issuerPNR decoded: '\(issuerPNR)' (length: \(issuerPNR.count))")
            print("Position after issuerPNR: \(decoder.position)")
        }

        if issuingPresence[8] {
            _ = try ExtensionData(from: &decoder)
            print("pos \(decoder.position): extensionData decoded")
        }
        if issuingPresence[9] {
            let v = Int(try decoder.decodeUnconstrainedInteger())
            print("pos \(decoder.position): issuedOnTrainNum = \(v)")
        }
        if issuingPresence[10] {
            let v = try decoder.decodeIA5String()
            print("pos \(decoder.position): issuedOnTrainIA5 = '\(v)'")
        }
        if issuingPresence[11] {
            let v = Int(try decoder.decodeUnconstrainedInteger())
            print("pos \(decoder.position): issuedOnLine = \(v)")
        }
        if issuingPresence[12] {
            _ = try GeoCoordinateType(from: &decoder)
            print("pos \(decoder.position): pointOfSale decoded")
        }

        // IssuingData should be done, check extensions
        if issuingExt {
            print("\nIssuingData has extensions - decoding...")
            let numExt = try decoder.decodeBitmaskLength()
            print("Number of extensions: \(numExt)")
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt where extPresence[i] {
                try decoder.skipOpenType()
            }
        } else {
            print("\nIssuingData has no extensions")
        }

        print("\nPosition after IssuingData: \(decoder.position)")

        // TravelerData (if present) - use real decoder
        if uicPresence[0] {
            print("\n=== Decoding TravelerData ===")
            let startPos = decoder.position
            let travelerData = try TravelerData(from: &decoder)
            print("pos \(decoder.position): TravelerData done (was \(startPos))")
            print("  travelers: \(travelerData.traveler?.count ?? 0)")
            if let first = travelerData.traveler?.first {
                print("  first traveler: \(first.lastName ?? "nil")")
            }
            print("  groupName: \(travelerData.groupName ?? "nil")")
        }

        // Continue with TransportDocument if present
        if uicPresence[1] {
            print("\n=== Decoding TransportDocument sequence ===")
            let docCount = try decoder.decodeLengthDeterminant()
            print("  Document count: \(docCount) (pos: \(decoder.position))")

            for i in 0..<docCount {
                print("\n  --- Document \(i) ---")
                let docExt = try decoder.decodeBit()
                print("  ext = \(docExt) (pos: \(decoder.position))")

                let docPresence = try decoder.decodePresenceBitmap(count: 1)
                print("  presence = \(docPresence)")
                print("    [0] token: \(docPresence[0])")
            }
        }
    }

    /// Test if IA5String length is correctly decoded
    func testIA5LengthDecode() throws {
        print("=== Testing IA5 length decode ===")

        // Create test data with known IA5String: length 5 "Hello"
        // Length 5 is encoded as: 0 (< 128) + 0000101 (5) = 00000101
        // 'H' = 72 = 1001000
        // 'e' = 101 = 1100101
        // 'l' = 108 = 1101100
        // 'l' = 108 = 1101100
        // 'o' = 111 = 1101111

        // Full bit sequence: 0 0000101 1001000 1100101 1101100 1101100 1101111
        // That's 1 + 7 + 5*7 = 43 bits

        // Pack into bytes:
        // 00000101 10010001 10010111 01100110 11001101 111xxxxx
        // 0x05     0x91     0x97     0x66     0xCD     0xE0

        let testData = Data([0x05, 0x91, 0x97, 0x66, 0xCD, 0xE0])
        var decoder = UPERDecoder(data: testData)

        let result = try decoder.decodeIA5String()
        print("Decoded: '\(result)'")
        XCTAssertEqual(result, "Hello")
    }

    /// Test decoding of constrained integer with known values
    func testConstrainedInt() throws {
        print("=== Testing constrained int decode ===")

        // Test issuingYear (range 2016-2269, 8 bits)
        // Value 2018 = offset 2 from min = 00000010 in 8 bits

        // Encode 2018 in 8 bits: 00000010
        let yearData = Data([0x02])  // 00000010
        var decoder1 = UPERDecoder(data: yearData)
        let year = try decoder1.decodeConstrainedInt(min: 2016, max: 2269)
        print("issuingYear: expected 2018, got \(year)")
        XCTAssertEqual(year, 2018)

        // Test issuingDay (range 1-366, 9 bits)
        // Value 1 = offset 0 from min = 000000000 in 9 bits
        // 000000000 packed = 0x00 0x00 (we only need 9 bits)
        let dayData = Data([0x00, 0x00])
        var decoder2 = UPERDecoder(data: dayData)
        let day = try decoder2.decodeConstrainedInt(min: 1, max: 366)
        print("issuingDay: expected 1, got \(day)")
        XCTAssertEqual(day, 1)

        // Test issuingTime (range 0-1439, 11 bits)
        // Value 600 in 11 bits = 01001011000
        // Packed into bytes: 01001011 000xxxxx = 0x4B 0x00
        let timeData = Data([0x4B, 0x00])
        var decoder3 = UPERDecoder(data: timeData)
        let time = try decoder3.decodeConstrainedInt(min: 0, max: 1439)
        print("issuingTime: expected 600, got \(time)")
        XCTAssertEqual(time, 600)
    }

    /// Test with 13-bit presence bitmap (fields 15-18 are NOT marked as extensions in Java)
    func testWith13BitPresence() throws {
        let data = TestTicketsV3.openTicketComplexData

        print("=== Testing with 13-bit presence bitmap ===")
        print("Theory: Fields 15-18 are NOT @IsExtension in Java, so they're in root presence bitmap")

        var decoder = UPERDecoder(data: data)

        // UicRailTicketData
        let uicExt = try decoder.decodeBit()
        print("pos \(decoder.position): UicRailTicketData ext = \(uicExt)")
        let uicPresence = try decoder.decodePresenceBitmap(count: 4)
        print("pos \(decoder.position): UicRailTicketData presence = \(uicPresence)")

        // IssuingData with 13-bit presence (fields 0-3, 7, 11-18)
        let issuingExt = try decoder.decodeBit()
        print("pos \(decoder.position): IssuingData ext = \(issuingExt)")

        let issuingPresence = try decoder.decodePresenceBitmap(count: 13)  // 13 bits!
        print("pos \(decoder.position): IssuingData presence (13 bits) = \(issuingPresence)")
        print("  [0] securityProviderNum: \(issuingPresence[0])")
        print("  [1] securityProviderIA5: \(issuingPresence[1])")
        print("  [2] issuerNum: \(issuingPresence[2])")
        print("  [3] issuerIA5: \(issuingPresence[3])")
        print("  [4] issuerName: \(issuingPresence[4])")
        print("  [5] currency: \(issuingPresence[5])")
        print("  [6] currencyFract: \(issuingPresence[6])")
        print("  [7] issuerPNR: \(issuingPresence[7])")
        print("  [8] extensionData: \(issuingPresence[8])")
        print("  [9] issuedOnTrainNum: \(issuingPresence[9])")
        print("  [10] issuedOnTrainIA5: \(issuingPresence[10])")
        print("  [11] issuedOnLine: \(issuingPresence[11])")
        print("  [12] pointOfSale: \(issuingPresence[12])")

        // Now decode mandatory fields
        let issuingYear = try decoder.decodeConstrainedInt(min: 2016, max: 2269)
        print("pos \(decoder.position): issuingYear = \(issuingYear) (expected: 2018)")

        let issuingDay = try decoder.decodeConstrainedInt(min: 1, max: 366)
        print("pos \(decoder.position): issuingDay = \(issuingDay) (expected: 1)")

        let issuingTime = try decoder.decodeConstrainedInt(min: 0, max: 1439)
        print("pos \(decoder.position): issuingTime = \(issuingTime) (expected: 600)")

        let specimen = try decoder.decodeBoolean()
        print("pos \(decoder.position): specimen = \(specimen) (expected: true)")

        let securePaperTicket = try decoder.decodeBoolean()
        print("pos \(decoder.position): securePaperTicket = \(securePaperTicket) (expected: false)")

        let activated = try decoder.decodeBoolean()
        print("pos \(decoder.position): activated = \(activated) (expected: true)")

        // Decode optional fields based on presence
        if issuingPresence[7] {  // issuerPNR
            print("\nDecoding issuerPNR...")
            let issuerPNR = try decoder.decodeIA5String()
            print("  issuerPNR = '\(issuerPNR)' (expected: issuerTestPNR)")
        }

        if issuingPresence[11] {  // issuedOnLine (now in root!)
            print("\nDecoding issuedOnLine...")
            let issuedOnLine = Int(try decoder.decodeUnconstrainedInteger())
            print("  issuedOnLine = \(issuedOnLine) (expected: 12)")
        }

        print("\n=== Results ===")
        XCTAssertEqual(issuingYear, 2018)
        XCTAssertEqual(issuingDay, 1)
        XCTAssertEqual(issuingTime, 600)
        XCTAssertEqual(specimen, true)
        XCTAssertEqual(activated, true)
    }

    /// Test the actual Java hex against the ASN.1 notation in the comment
    func testHexAgainstComment() throws {
        print("=== Comparing hex to ASN.1 comment ===")
        print("According to the Java comment, the hex should decode to:")
        print("  issuingYear: 2018")
        print("  issuingDay: 1")
        print("  issuingTime: 600")
        print("  specimen: true")
        print("  securePaperTicket: false")
        print("  activated: true")
        print("  issuerPNR: issuerTestPNR")
        print("  issuedOnLine: 12 (extension)")

        // Calculate what bits we EXPECT at each position
        // Position 15: issuingYear (8 bits), value 2 for 2018
        // Expected bits: 00000010

        // Position 23: issuingDay (9 bits), value 0 for day 1
        // Expected bits: 000000000

        // Position 32: issuingTime (11 bits), value 600
        // Expected bits: 01001011000

        // Look at actual bits in the hex
        let data = TestTicketsV3.openTicketComplexData

        print("\nActual bytes 1-6: ", terminator: "")
        for byte in data[1..<6] {
            print(String(format: "%02X ", byte), terminator: "")
        }
        print("")

        print("In binary:")
        for i in 1..<6 {
            let binary = String(data[i], radix: 2).leftPadded(toLength: 8, withPad: "0")
            print("  Byte \(i): \(String(format: "%02X", data[i])) = \(binary)")
        }

        // Extract bits 15-22 (issuingYear)
        print("\nBits 15-22 (issuingYear):")
        for bit in 15...22 {
            let byteIdx = bit / 8
            let bitIdx = 7 - (bit % 8)
            let bitValue = (data[byteIdx] >> bitIdx) & 1
            print("  bit \(bit) (byte \(byteIdx), bit \(bitIdx)): \(bitValue)")
        }

        // Calculate the value
        var yearValue = 0
        for bit in 15...22 {
            let byteIdx = bit / 8
            let bitIdx = 7 - (bit % 8)
            let bitValue = Int((data[byteIdx] >> bitIdx) & 1)
            yearValue = (yearValue << 1) | bitValue
        }
        print("  -> yearValue = \(yearValue), issuingYear = \(2016 + yearValue)")
    }

    /// Trace decoding to find where position 380 fails
    func testTraceToPosition380() throws {
        let data = TestTicketsV3.openTicketComplexData

        print("=== Tracing decode to position 380 ===")
        var decoder = UPERDecoder(data: data)

        // Decode IssuingData via the struct
        let uicExt = try decoder.decodeBit()
        let uicPresence = try decoder.decodePresenceBitmap(count: 4)
        print("pos \(decoder.position): UicRailTicketData ext=\(uicExt) presence=\(uicPresence)")

        print("\n--- Decoding IssuingData ---")
        let issuing = try IssuingData(from: &decoder)
        print("pos \(decoder.position): IssuingData done")
        print("  issuingYear: \(issuing.issuingYear)")
        print("  issuingDay: \(issuing.issuingDay)")
        print("  issuerPNR: \(issuing.issuerPNR ?? "nil")")

        // Decode TravelerData if present
        if uicPresence[0] {
            print("\n--- Decoding TravelerData ---")
            let travExt = try decoder.decodeBit()
            let travPresence = try decoder.decodePresenceBitmap(count: 3)
            print("pos \(decoder.position): TravelerData ext=\(travExt) presence=\(travPresence)")

            // Decode travelers sequence if present
            if travPresence[0] {
                print("\n  --- Decoding travelers sequence ---")
                let count = try decoder.decodeLengthDeterminant()
                print("  pos \(decoder.position): traveler count = \(count)")

                for i in 0..<count {
                    print("\n  --- TravelerType[\(i)] ---")
                    print("  pos \(decoder.position): starting TravelerType")

                    // Decode TravelerType manually to trace
                    let hasExtensions = try decoder.decodeBit()
                    print("  pos \(decoder.position): ext = \(hasExtensions)")

                    let presence = try decoder.decodePresenceBitmap(count: 18)
                    print("  pos \(decoder.position): presence = \(presence)")

                    var idx = 0
                    // Field 0: firstName
                    if presence[idx] {
                        print("  pos \(decoder.position): decoding firstName...")
                        let firstName = try decoder.decodeUTF8String()
                        print("  pos \(decoder.position): firstName = '\(firstName)'")
                    }
                    idx += 1

                    // Field 1: secondName
                    if presence[idx] {
                        print("  pos \(decoder.position): decoding secondName...")
                        let secondName = try decoder.decodeUTF8String()
                        print("  pos \(decoder.position): secondName = '\(secondName)'")
                    }
                    idx += 1

                    // Field 2: lastName
                    if presence[idx] {
                        print("  pos \(decoder.position): decoding lastName...")
                        let lastName = try decoder.decodeUTF8String()
                        print("  pos \(decoder.position): lastName = '\(lastName)'")
                    }
                    idx += 1

                    // Field 3: idCard
                    if presence[idx] {
                        print("  pos \(decoder.position): decoding idCard...")
                        let idCard = try decoder.decodeIA5String()
                        print("  pos \(decoder.position): idCard = '\(idCard)'")
                    }
                    idx += 1

                    // Field 4: passportId
                    if presence[idx] {
                        print("  pos \(decoder.position): decoding passportId...")
                        let passportId = try decoder.decodeIA5String()
                        print("  pos \(decoder.position): passportId = '\(passportId)'")
                    }
                    idx += 1

                    // Field 5: title
                    if presence[idx] {
                        print("  pos \(decoder.position): decoding title...")
                        let title = try decoder.decodeUTF8String()
                        print("  pos \(decoder.position): title = '\(title)'")
                    }
                    idx += 1

                    // Field 6: gender
                    if presence[idx] {
                        print("  pos \(decoder.position): decoding gender...")
                        let gender = try decoder.decodeEnumerated(rootCount: 4)
                        print("  pos \(decoder.position): gender = \(gender)")
                    }
                    idx += 1

                    // Field 7: customerIdIA5
                    if presence[idx] {
                        print("  pos \(decoder.position): decoding customerIdIA5...")
                        let customerId = try decoder.decodeIA5String()
                        print("  pos \(decoder.position): customerIdIA5 = '\(customerId)'")
                    }
                    idx += 1

                    // Field 8: customerIdNum
                    if presence[idx] {
                        print("  pos \(decoder.position): decoding customerIdNum...")
                        let num = try decoder.decodeUnconstrainedInteger()
                        print("  pos \(decoder.position): customerIdNum = \(num)")
                    }
                    idx += 1

                    // Field 9: yearOfBirth
                    if presence[idx] {
                        print("  pos \(decoder.position): decoding yearOfBirth...")
                        let year = try decoder.decodeConstrainedInt(min: 1901, max: 2155)
                        print("  pos \(decoder.position): yearOfBirth = \(year)")
                    }
                    idx += 1

                    // Field 10: monthOfBirth
                    if presence[idx] {
                        print("  pos \(decoder.position): decoding monthOfBirth...")
                        let month = try decoder.decodeConstrainedInt(min: 1, max: 12)
                        print("  pos \(decoder.position): monthOfBirth = \(month)")
                    }
                    idx += 1

                    // Field 11: dayOfBirth
                    if presence[idx] {
                        print("  pos \(decoder.position): decoding dayOfBirth...")
                        let day = try decoder.decodeConstrainedInt(min: 1, max: 31)
                        print("  pos \(decoder.position): dayOfBirth = \(day)")
                    }
                    idx += 1

                    // Field 12: ticketHolder (MANDATORY)
                    print("  pos \(decoder.position): decoding ticketHolder (mandatory)...")
                    let ticketHolder = try decoder.decodeBoolean()
                    print("  pos \(decoder.position): ticketHolder = \(ticketHolder)")

                    // Field 13: passengerType
                    if presence[idx] {
                        print("  pos \(decoder.position): decoding passengerType...")
                        let pt = try decoder.decodeEnumerated(rootCount: 5, hasExtensionMarker: true)
                        print("  pos \(decoder.position): passengerType = \(pt)")
                    }
                    idx += 1

                    // Field 14: passengerWithReducedMobility
                    if presence[idx] {
                        print("  pos \(decoder.position): decoding passengerWithReducedMobility...")
                        let prm = try decoder.decodeBoolean()
                        print("  pos \(decoder.position): passengerWithReducedMobility = \(prm)")
                    }
                    idx += 1

                    // Field 15: countryOfResidence
                    if presence[idx] {
                        print("  pos \(decoder.position): decoding countryOfResidence...")
                        let country = try decoder.decodeConstrainedInt(min: 1, max: 999)
                        print("  pos \(decoder.position): countryOfResidence = \(country)")
                    }
                    idx += 1

                    // Field 16: countryOfPassport
                    if presence[idx] {
                        print("  pos \(decoder.position): decoding countryOfPassport...")
                        let country = try decoder.decodeConstrainedInt(min: 1, max: 999)
                        print("  pos \(decoder.position): countryOfPassport = \(country)")
                    }
                    idx += 1

                    // Field 17: countryOfIdCard
                    if presence[idx] {
                        print("  pos \(decoder.position): decoding countryOfIdCard...")
                        let country = try decoder.decodeConstrainedInt(min: 1, max: 999)
                        print("  pos \(decoder.position): countryOfIdCard = \(country)")
                    }
                    idx += 1

                    // Field 18: status
                    if presence[idx] {
                        print("  pos \(decoder.position): decoding status sequence...")
                        let statusCount = try decoder.decodeLengthDeterminant()
                        print("  pos \(decoder.position): status count = \(statusCount)")
                        for j in 0..<statusCount {
                            print("  pos \(decoder.position): decoding CustomerStatusType[\(j)]...")
                            _ = try CustomerStatusType(from: &decoder)
                        }
                    }

                    // Handle extensions
                    if hasExtensions {
                        let numExt = try decoder.decodeBitmaskLength()
                        print("  pos \(decoder.position): \(numExt) extensions")
                        let extPresence = try decoder.decodePresenceBitmap(count: numExt)
                        for j in 0..<numExt where extPresence[j] {
                            try decoder.skipOpenType()
                        }
                    }

                    print("  pos \(decoder.position): TravelerType[\(i)] done")

                    // Stop if we're past position 380
                    if decoder.position > 400 {
                        print("\n!!! Passed position 400, stopping trace")
                        return
                    }
                }
            }

            // preferedLanguage
            if travPresence[1] {
                print("\n  pos \(decoder.position): decoding preferedLanguage...")
                let lang = try decoder.decodeIA5String(constraint: ASN1StringConstraint(type: .ia5String, fixedLength: 2))
                print("  pos \(decoder.position): preferedLanguage = '\(lang)'")
            }

            // groupName
            if travPresence[2] {
                print("\n  pos \(decoder.position): decoding groupName...")
                let group = try decoder.decodeUTF8String()
                print("  pos \(decoder.position): groupName = '\(group)'")
            }
        }

        print("\n=== Trace complete at position \(decoder.position) ===")
    }

    /// Continue trace using struct decoders
    func testTraceTransportDocument() throws {
        let data = TestTicketsV3.openTicketComplexData

        print("=== Full decode trace using structs ===")
        print("Data: \(data.count) bytes = \(data.count * 8) bits")
        var decoder = UPERDecoder(data: data)

        // UicRailTicketData header
        _ = try decoder.decodeBit() // ext
        let uicPresence = try decoder.decodePresenceBitmap(count: 4)
        print("pos \(decoder.position): UicRailTicketData presence=\(uicPresence)")

        // IssuingData
        _ = try IssuingData(from: &decoder)
        print("pos \(decoder.position): IssuingData done")

        // TravelerData
        if uicPresence[0] {
            _ = try TravelerData(from: &decoder)
            print("pos \(decoder.position): TravelerData done")
        }

        // TransportDocument
        if uicPresence[1] {
            let docCount = try decoder.decodeLengthDeterminant()
            print("pos \(decoder.position): TransportDocument count=\(docCount)")
            for i in 0..<docCount {
                let startPos = decoder.position
                // Manually decode DocumentData to trace
                let docExt = try decoder.decodeBit()
                let docPresence = try decoder.decodePresenceBitmap(count: 1)
                print("pos \(decoder.position): Doc[\(i)] ext=\(docExt) token=\(docPresence[0])")

                if docPresence[0] {
                    _ = try TokenType(from: &decoder)
                    print("pos \(decoder.position): Doc[\(i)] TokenType done")
                }

                // TicketDetailData CHOICE
                let choiceIdx = try decoder.decodeChoiceIndex(rootCount: 12, hasExtensionMarker: true)
                print("pos \(decoder.position): Doc[\(i)] choiceIdx=\(choiceIdx)")

                do {
                    switch choiceIdx {
                    case 2:
                        // Trace OpenTicketData manually
                        let otExt = try decoder.decodeBit()
                        let otPresence = try decoder.decodePresenceBitmap(count: 40)
                        print("pos \(decoder.position): OT ext=\(otExt)")
                        // Print which optional fields are present
                        var presentFields: [Int] = []
                        for j in 0..<40 { if otPresence[j] { presentFields.append(j) } }
                        print("  Present fields: \(presentFields)")

                        var oidx = 0
                        // Fields 0-7 optional
                        if otPresence[oidx] { _ = try decoder.decodeUnconstrainedInteger(); print("pos \(decoder.position): referenceNum") }; oidx += 1
                        if otPresence[oidx] { _ = try decoder.decodeIA5String(); print("pos \(decoder.position): referenceIA5") }; oidx += 1
                        if otPresence[oidx] { _ = try decoder.decodeConstrainedInt(min: 1, max: 32000); print("pos \(decoder.position): productOwnerNum") }; oidx += 1
                        if otPresence[oidx] { _ = try decoder.decodeIA5String(); print("pos \(decoder.position): productOwnerIA5") }; oidx += 1
                        if otPresence[oidx] { _ = try decoder.decodeUnconstrainedInteger(); print("pos \(decoder.position): productIdNum") }; oidx += 1
                        if otPresence[oidx] { _ = try decoder.decodeIA5String(); print("pos \(decoder.position): productIdIA5") }; oidx += 1
                        if otPresence[oidx] { _ = try decoder.decodeUnconstrainedInteger(); print("pos \(decoder.position): externalIssuerId") }; oidx += 1
                        if otPresence[oidx] { _ = try decoder.decodeUnconstrainedInteger(); print("pos \(decoder.position): issuerAuthorizationId") }; oidx += 1
                        // Field 8: returnIncluded MANDATORY
                        let returnInc = try decoder.decodeBoolean()
                        print("pos \(decoder.position): returnIncluded=\(returnInc)")
                        // Fields 9-17
                        if otPresence[oidx] { _ = try decoder.decodeEnumerated(rootCount: 5, hasExtensionMarker: true); print("pos \(decoder.position): stationCodeTable") }; oidx += 1
                        if otPresence[oidx] { _ = try decoder.decodeUnconstrainedInteger(); print("pos \(decoder.position): fromStationNum") }; oidx += 1
                        if otPresence[oidx] { _ = try decoder.decodeIA5String(); print("pos \(decoder.position): fromStationIA5") }; oidx += 1
                        if otPresence[oidx] { _ = try decoder.decodeUnconstrainedInteger(); print("pos \(decoder.position): toStationNum") }; oidx += 1
                        if otPresence[oidx] { _ = try decoder.decodeIA5String(); print("pos \(decoder.position): toStationIA5") }; oidx += 1
                        if otPresence[oidx] { _ = try decoder.decodeUTF8String(); print("pos \(decoder.position): fromStationNameUTF8") }; oidx += 1
                        if otPresence[oidx] { _ = try decoder.decodeUTF8String(); print("pos \(decoder.position): toStationNameUTF8") }; oidx += 1
                        if otPresence[oidx] { _ = try decoder.decodeUTF8String(); print("pos \(decoder.position): validRegionDesc") }; oidx += 1
                        if otPresence[oidx] {
                            let rvCount = try decoder.decodeLengthDeterminant()
                            print("pos \(decoder.position): validRegion count=\(rvCount)")
                            for rv in 0..<rvCount {
                                _ = try RegionalValidityType(from: &decoder)
                                print("pos \(decoder.position): validRegion[\(rv)] done")
                            }
                        }; oidx += 1
                        if otPresence[oidx] { _ = try ReturnRouteDescriptionType(from: &decoder); print("pos \(decoder.position): returnDescription") }; oidx += 1
                        // Fields 19-24
                        if otPresence[oidx] { _ = try decoder.decodeConstrainedInt(min: -367, max: 700); print("pos \(decoder.position): validFromDay") }; oidx += 1
                        if otPresence[oidx] { _ = try decoder.decodeConstrainedInt(min: 0, max: 1439); print("pos \(decoder.position): validFromTime") }; oidx += 1
                        if otPresence[oidx] { _ = try decoder.decodeConstrainedInt(min: -60, max: 60); print("pos \(decoder.position): validFromUTCOffset") }; oidx += 1
                        if otPresence[oidx] { _ = try decoder.decodeConstrainedInt(min: -1, max: 500); print("pos \(decoder.position): validUntilDay") }; oidx += 1
                        if otPresence[oidx] { _ = try decoder.decodeConstrainedInt(min: 0, max: 1439); print("pos \(decoder.position): validUntilTime") }; oidx += 1
                        if otPresence[oidx] { _ = try decoder.decodeConstrainedInt(min: -60, max: 60); print("pos \(decoder.position): validUntilUTCOffset") }; oidx += 1
                        // Fields 25-40
                        if otPresence[oidx] { print("pos \(decoder.position): activatedDay..."); let c = try decoder.decodeLengthDeterminant(); for _ in 0..<c { _ = try decoder.decodeConstrainedInt(min: 0, max: 500) }; print("pos \(decoder.position): activatedDay done") }; oidx += 1
                        if otPresence[oidx] { let v = try decoder.decodeEnumerated(rootCount: 12, hasExtensionMarker: true); print("pos \(decoder.position): classCode=\(v)") }; oidx += 1
                        if otPresence[oidx] { _ = try decoder.decodeIA5String(); print("pos \(decoder.position): serviceLevel") }; oidx += 1
                        if otPresence[oidx] { print("pos \(decoder.position): carrierNum..."); let c = try decoder.decodeLengthDeterminant(); for _ in 0..<c { _ = try decoder.decodeConstrainedInt(min: 1, max: 32000) }; print("pos \(decoder.position): carrierNum done") }; oidx += 1
                        if otPresence[oidx] { print("pos \(decoder.position): carrierIA5..."); let c = try decoder.decodeLengthDeterminant(); for _ in 0..<c { _ = try decoder.decodeIA5String() }; print("pos \(decoder.position): carrierIA5 done") }; oidx += 1
                        if otPresence[oidx] { print("pos \(decoder.position): includedServiceBrands..."); let c = try decoder.decodeLengthDeterminant(); for _ in 0..<c { _ = try decoder.decodeConstrainedInt(min: 0, max: 32000) }; print("pos \(decoder.position): includedServiceBrands done") }; oidx += 1
                        if otPresence[oidx] { print("pos \(decoder.position): excludedServiceBrands..."); let c = try decoder.decodeLengthDeterminant(); for _ in 0..<c { _ = try decoder.decodeConstrainedInt(min: 0, max: 32000) }; print("pos \(decoder.position): excludedServiceBrands done") }; oidx += 1
                        if otPresence[oidx] { print("pos \(decoder.position): tariffs..."); let c = try decoder.decodeLengthDeterminant(); for j in 0..<c { _ = try TariffType(from: &decoder); print("pos \(decoder.position): tariff[\(j)] done") }; print("pos \(decoder.position): tariffs done") }; oidx += 1
                        if otPresence[oidx] { _ = try decoder.decodeUnconstrainedInteger(); print("pos \(decoder.position): price") }; oidx += 1
                        if otPresence[oidx] { print("pos \(decoder.position): vatDetails..."); let c = try decoder.decodeLengthDeterminant(); for j in 0..<c { _ = try VatDetailType(from: &decoder); print("pos \(decoder.position): vatDetail[\(j)] done") }; print("pos \(decoder.position): vatDetails done") }; oidx += 1
                        if otPresence[oidx] { let info = try decoder.decodeUTF8String(); print("pos \(decoder.position): infoText='\(info)'") }; oidx += 1
                        if otPresence[oidx] { print("pos \(decoder.position): includedAddOns..."); let c = try decoder.decodeLengthDeterminant(); for j in 0..<c { _ = try IncludedOpenTicketType(from: &decoder); print("pos \(decoder.position): addon[\(j)] done") }; print("pos \(decoder.position): includedAddOns done") }; oidx += 1
                        if otPresence[oidx] { _ = try LuggageRestrictionType(from: &decoder); print("pos \(decoder.position): luggage") }; oidx += 1
                        if otPresence[oidx] { print("pos \(decoder.position): includedTransportTypes..."); let c = try decoder.decodeLengthDeterminant(); for _ in 0..<c { _ = try decoder.decodeConstrainedInt(min: 0, max: 32000) }; print("pos \(decoder.position): includedTransportTypes done") }; oidx += 1
                        if otPresence[oidx] { print("pos \(decoder.position): excludedTransportTypes..."); let c = try decoder.decodeLengthDeterminant(); for _ in 0..<c { _ = try decoder.decodeConstrainedInt(min: 0, max: 32000) }; print("pos \(decoder.position): excludedTransportTypes done") }; oidx += 1
                        if otPresence[oidx] { _ = try ExtensionData(from: &decoder); print("pos \(decoder.position): extensionData") }

                        // Handle OT extensions
                        if otExt {
                            let numExt = try decoder.decodeBitmaskLength()
                            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
                            for j in 0..<numExt where extPresence[j] {
                                try decoder.skipOpenType()
                            }
                        }
                        print("pos \(decoder.position): Doc[\(i)] OpenTicketData done")

                    case 9:
                        _ = try StationPassageData(from: &decoder)
                        print("pos \(decoder.position): Doc[\(i)] StationPassageData done")
                    default:
                        print("pos \(decoder.position): Doc[\(i)] UNHANDLED choice \(choiceIdx)")
                    }
                } catch {
                    print("pos \(decoder.position): Doc[\(i)] FAILED: \(error)")
                    throw error
                }

                if docExt {
                    let numExt = try decoder.decodeBitmaskLength()
                    let extPresence = try decoder.decodePresenceBitmap(count: numExt)
                    for j in 0..<numExt where extPresence[j] {
                        try decoder.skipOpenType()
                    }
                }
                print("pos \(decoder.position): Doc[\(i)] done")
            }
        }

        // ControlData
        if uicPresence[2] {
            let startPos = decoder.position
            _ = try ControlData(from: &decoder)
            print("pos \(decoder.position): ControlData done (was \(startPos))")
        }

        // ExtensionData
        if uicPresence[3] {
            let startPos = decoder.position
            let extCount = try decoder.decodeLengthDeterminant()
            print("pos \(decoder.position): ExtensionData count=\(extCount) (was \(startPos))")
            for i in 0..<extCount {
                let eStart = decoder.position
                _ = try ExtensionData(from: &decoder)
                print("pos \(decoder.position): Extension[\(i)] done (was \(eStart))")
            }
        }

        print("\n=== Trace complete at position \(decoder.position) / \(data.count * 8) bits ===")
    }
}

// Helper extension for left padding strings
extension String {
    func leftPadded(toLength length: Int, withPad pad: String) -> String {
        let padCount = length - count
        if padCount > 0 {
            return String(repeating: pad, count: padCount) + self
        }
        return self
    }
}
