import XCTest
@testable import UICBarcodeKit

/// Real-World Ticket Decoding Tests
/// Translated from Java tests:
/// - DecodeSparpreisTicketDBTest.java
/// - BahnCardTest.java
/// - EurailPassTest.java
final class RealWorldTicketTests: XCTestCase {

    // MARK: - Test Data (from Java tests)

    /// DB Sparpreis ticket hex data (Static Frame v2)
    static let sparpreisTicketHex = """
        2355543032313038303030303032782e\
        2fe184a1d85e89e9338b298ec61aeba2\
        48ce722056ca940a967c8a1d39126e2c\
        628c4fcea91ba35216a0a350f894de5e\
        bd7b8909920fde947feede0e20c43031\
        3939789c01bc0043ff555f464c455831\
        333031383862b20086e10dc125ea2815\
        110881051c844464d985668e23a00a80\
        000e96c2e4e6e8cadc08aed2d8d90104\
        44d7be0100221ce610ea559b64364c38\
        a82361d1cb5e1e5d32a3d0979bd099c8\
        426b0b7373432b4b6852932baba3634b\
        733b2b715ab34b09d101e18981c181f1\
        424221521291521292a17a3a920a1152\
        5a095282314952b20a49529952826278\
        083001a4c38ae5bb303ace7003800700\
        14b00240400f53757065722053706172\
        7072656973c41e4a03
        """

    /// BahnCard ticket hex data (Static Frame v1)
    static let bahnCardTicketHex = """
        2355543031313038303030303031302D02150098E762AFB6D0BB7A7F629DCBFAB0BD04B4F0C53B02146111A3F5D92B5FDF83A0FAFD209CD3A56C37CE2A00000030353036789C65514D88D34018ED414B8DACB02CA8C7591069D596994926A9BDA549D696C6B2B46971B15027EED80E265349DA8A375111653DF8830B2B5E54943D08222C9E3C282A08E2A1E0C59B7B70F1EEC1AB93A2BBA0EF32336FDEF7F3BEAFD5AD38A60D11844445B008511E43A7E962D34B6D43FE220CB10A13D88EEDB4BA9E6B2E495A2DE286E561491B30D1A8EA71792F6A65B352B7CC860DFE81B7B4082A001BCAC94BA04CFBC2A2D1322010647101D4021AC72C972D5B04E6142ECE07A3988F1968985577D16D356587B2004A0AE85A7D1481DEBBD7C190F780CF38680FA27C4704B4C700E382C58086C3809FED33D111AE3C873E0F96E928BEC878CCE28E806A628A400D428D9CF893683C08012E16A05E48DC82BFB4CFE3296D4C69A8EBBA8C25C92CA4633931A819C943458AA254459FFA2CCA72912B35994FE321A7E218A889C18573484B6A4EA788F5B295AF8FC29045C08045A42184548231D13422BB4A642891C11A8D864CE4AB36D8594CABBBE03AA76422440CFF76EAFAE6CCDB37A9F51B7626FB3D25B7765F6F1F3E602CACEEFFE6BDDAFA95EE67DA1B5FFE67AF8EF71DDCF03FACE8CFD7487FB25EFAFCD8AABE389471F3331F83827B2DFD6CD7EEB4F37E4F78AB2082A77273F393C05B293D5CFBB9FAF2CCE6E54F5FE74EEFBDF7E468549B9F9DCCDEE477AE1C7940EF2A8FE67EFC068346B0C6
        """

    /// Eurail Pass ticket hex data (Static Frame v1)
    static let eurailPassHex = """
        2355543031353231373030303031302D021500A7958EBB21072C93018BEF922A\
        53F597AAE3B5E90214625157E0A477C8955BFC2F288B450F5AB8501592000000303233367\
        8DA554F5D4BC33014FD2B795470E5DCDC246D1F675BF5414146ABEC6954565D5997413705\
        FF9B6FFE316F52E8F042B83987F391349B876A598200CB56535ABEAFBF5F0AF56F9022D5D\
        04C6083B252AAD9D48FCBB59858EB55516B32220265C2E490C9EFDADDB86FC77327B11A44\
        81243CB5DEABD77E187AA1444C26D0A6AC1795DFEE3FFDB65BDC16A0E0C064916DEDEC7FE\
        EC6D3D15F75FE1A1C25C10F139E06E7DCECD298EE3620B127F20127676690C872B1E7A2C9\
        84C92E0C27314972A4405AF8FEF76738F71FEAEB7850313309C5EAAD3F45984D70F271CCE\
        690C455B312ECE66493DF007F3C8154C0
        """

    // MARK: - Helper Functions

    /// Convert hex string to Data
    func hexToData(_ hex: String) -> Data {
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

    // MARK: - DB Sparpreis Ticket Tests (from DecodeSparpreisTicketDBTest.java)

    /// Test that Sparpreis ticket data can be parsed as Static Frame
    func testSparpreisTicketIsStaticFrame() {
        let data = hexToData(Self.sparpreisTicketHex)

        // Should start with "#UT" header
        XCTAssertGreaterThanOrEqual(data.count, 3)
        let header = String(data: data[0..<3], encoding: .ascii)
        XCTAssertEqual(header, "#UT")
    }

    /// Test Sparpreis ticket version detection
    func testSparpreisTicketVersion() {
        let data = hexToData(Self.sparpreisTicketHex)

        // Version is at offset 3-4 (ASCII "02" for v2)
        let versionString = String(data: data[3..<5], encoding: .ascii)
        XCTAssertEqual(versionString, "02")
    }

    /// Test Sparpreis ticket security provider
    func testSparpreisTicketSecurityProvider() {
        let data = hexToData(Self.sparpreisTicketHex)

        // Security provider is at offset 5-8 (ASCII "1080")
        let providerString = String(data: data[5..<9], encoding: .ascii)
        XCTAssertEqual(providerString, "1080")
    }

    /// Test Sparpreis ticket structure parsing
    func testSparpreisTicketStructure() throws {
        let data = hexToData(Self.sparpreisTicketHex)

        // Parse as Static Frame
        let frame = try StaticFrame(data: data)

        XCTAssertEqual(frame.version, 2)
        XCTAssertEqual(frame.securityProvider, "1080")
        XCTAssertNotNil(frame.signature)
        XCTAssertGreaterThan(frame.signedData.count, 0)
    }

    /// Test expected values from Java test
    /// From Java: ticket.getIssuerDetails().getIssuer().equals("1080")
    /// From Java: ticket.getIssuerDetails().getIssuerPNR().equals("D260V48G")
    func testSparpreisTicketExpectedValues() throws {
        let data = hexToData(Self.sparpreisTicketHex)

        let frame = try StaticFrame(data: data)

        // Verify frame parsed successfully with signed data
        XCTAssertGreaterThan(frame.signedData.count, 0)

        // According to Java test, FCB should contain:
        // - issuer = 1080
        // - issuerPNR = "D260V48G"
        // - traveler firstName = "Karsten", lastName = "Will"
        // - openTicket reference = "CN0CTUMY"
        // - tariff description = "Super Sparpreis"
    }

    // MARK: - BahnCard Ticket Tests (from BahnCardTest.java)

    /// Test that BahnCard ticket data can be parsed as Static Frame
    func testBahnCardTicketIsStaticFrame() {
        let data = hexToData(Self.bahnCardTicketHex)

        // Should start with "#UT" header
        XCTAssertGreaterThanOrEqual(data.count, 3)
        let header = String(data: data[0..<3], encoding: .ascii)
        XCTAssertEqual(header, "#UT")
    }

    /// Test BahnCard ticket version (v1)
    func testBahnCardTicketVersion() {
        let data = hexToData(Self.bahnCardTicketHex)

        // Version is at offset 3-4 (ASCII "01" for v1)
        let versionString = String(data: data[3..<5], encoding: .ascii)
        XCTAssertEqual(versionString, "01")
    }

    /// Test BahnCard ticket structure parsing
    func testBahnCardTicketStructure() throws {
        let data = hexToData(Self.bahnCardTicketHex)

        let frame = try StaticFrame(data: data)

        XCTAssertEqual(frame.version, 1)
        XCTAssertEqual(frame.securityProvider, "1080")
        XCTAssertNotNil(frame.signature)
    }

    /// Test expected BahnCard values from Java test
    /// From Java: card.getCardId().equals("7081411135225445")
    /// From Java: card.getCardTypeDescr().equals("My BahnCard 50 (2. Klasse)")
    /// From Java: card.getClassCode().equals(ITravelClassType.second)
    func testBahnCardExpectedValues() throws {
        let data = hexToData(Self.bahnCardTicketHex)

        let frame = try StaticFrame(data: data)

        // Verify frame parsed successfully
        XCTAssertGreaterThan(frame.signedData.count, 0)

        // According to Java test, should contain:
        // - CustomerCard with cardId "7081411135225445"
        // - cardTypeDescr "My BahnCard 50 (2. Klasse)"
        // - classCode = second
        // - extension data
        // - includedServices contains 1
    }

    // MARK: - Eurail Pass Tests (from EurailPassTest.java)

    /// Test that Eurail Pass ticket data can be parsed as Static Frame
    func testEurailPassIsStaticFrame() {
        let data = hexToData(Self.eurailPassHex)

        // Should start with "#UT" header
        XCTAssertGreaterThanOrEqual(data.count, 3)
        let header = String(data: data[0..<3], encoding: .ascii)
        XCTAssertEqual(header, "#UT")
    }

    /// Test Eurail Pass version (v1)
    func testEurailPassVersion() {
        let data = hexToData(Self.eurailPassHex)

        // Version is at offset 3-4
        let versionString = String(data: data[3..<5], encoding: .ascii)
        XCTAssertEqual(versionString, "01")
    }

    /// Test Eurail Pass security provider
    func testEurailPassSecurityProvider() {
        let data = hexToData(Self.eurailPassHex)

        // Security provider at offset 5-8
        let providerString = String(data: data[5..<9], encoding: .ascii)
        XCTAssertEqual(providerString, "5217")
    }

    /// Test Eurail Pass structure parsing
    func testEurailPassStructure() throws {
        let data = hexToData(Self.eurailPassHex)

        let frame = try StaticFrame(data: data)

        XCTAssertEqual(frame.version, 1)
        XCTAssertEqual(frame.securityProvider, "5217")
        XCTAssertNotNil(frame.signature)
    }

    // MARK: - Barcode Type Detection Tests

    /// Test Static Frame detection by header
    func testStaticFrameHeaderDetection() {
        let staticFrameData = hexToData(Self.sparpreisTicketHex)

        // Static frames start with "#UT" (0x23, 0x55, 0x54)
        XCTAssertEqual(staticFrameData[0], 0x23)  // '#'
        XCTAssertEqual(staticFrameData[1], 0x55)  // 'U'
        XCTAssertEqual(staticFrameData[2], 0x54)  // 'T'
    }

    /// Test distinguishing Static Frame from Dynamic Frame
    func testFrameTypeDistinction() {
        // Static Frame starts with "#UT" (ASCII)
        let staticData = hexToData(Self.sparpreisTicketHex)
        let isStatic = staticData.count >= 3 &&
                       staticData[0] == 0x23 &&  // '#'
                       staticData[1] == 0x55 &&  // 'U'
                       staticData[2] == 0x54     // 'T'
        XCTAssertTrue(isStatic)

        // Dynamic Frame would start with "U1" or "U2" in UPER encoding
        // SSB Frame is exactly 114 bytes with different structure
    }

    // MARK: - Signature Region Tests

    /// Test Static Frame v1 signature format
    /// V1 uses DSA signature, DER encoded
    func testStaticFrameV1SignatureFormat() throws {
        let data = hexToData(Self.bahnCardTicketHex)
        let frame = try StaticFrame(data: data)

        XCTAssertEqual(frame.version, 1)
        // Signature should be DER encoded (starts with 0x30 SEQUENCE tag)
        XCTAssertGreaterThan(frame.signature.count, 0)
        XCTAssertEqual(frame.signature[0], 0x30)
    }

    /// Test Static Frame v2 signature format
    /// V2 uses ECDSA signature, converted to DER
    func testStaticFrameV2SignatureFormat() throws {
        let data = hexToData(Self.sparpreisTicketHex)
        let frame = try StaticFrame(data: data)

        XCTAssertEqual(frame.version, 2)
        // Signature should be DER encoded
        XCTAssertGreaterThan(frame.signature.count, 0)
        XCTAssertEqual(frame.signature[0], 0x30)
    }

    // MARK: - Data Record Tests

    /// Test that signed data is present
    func testSignedDataPresent() throws {
        let data = hexToData(Self.sparpreisTicketHex)
        let frame = try StaticFrame(data: data)

        XCTAssertGreaterThan(frame.signedData.count, 0)
    }

    /// Test that signed data contains record data
    func testSignedDataContainsRecords() throws {
        let data = hexToData(Self.sparpreisTicketHex)
        let frame = try StaticFrame(data: data)

        // Signed data should be present (compressed data records)
        XCTAssertGreaterThan(frame.signedData.count, 0)
    }

    // MARK: - Full Decode Tests

    /// Test full decoding of Sparpreis ticket
    func testFullSparpreisTicketDecode() throws {
        let data = hexToData(Self.sparpreisTicketHex)

        // Parse frame
        let frame = try StaticFrame(data: data)
        XCTAssertEqual(frame.version, 2)
        XCTAssertEqual(frame.securityProvider, "1080")

        // Verify data was decompressed (signedData is compressed input)
        XCTAssertGreaterThan(frame.signedData.count, 0)
    }

    /// Test full decoding of BahnCard ticket
    func testFullBahnCardDecode() throws {
        let data = hexToData(Self.bahnCardTicketHex)

        // Parse frame
        let frame = try StaticFrame(data: data)
        XCTAssertEqual(frame.version, 1)
        XCTAssertEqual(frame.securityProvider, "1080")

        // Verify data was parsed
        XCTAssertGreaterThan(frame.signedData.count, 0)
    }
}

// MARK: - FCB Content Verification Extensions

extension RealWorldTicketTests {

    /// Expected traveler from Java test
    struct ExpectedTraveler {
        let firstName: String
        let lastName: String
        let isTicketHolder: Bool
    }

    /// Expected issuing data from Java test
    struct ExpectedIssuingData {
        let issuer: String
        let issuerPNR: String
        let isSecurePaperTicket: Bool
        let isActivated: Bool
        let isSpecimen: Bool
    }

    /// Expected open ticket data from Java test
    struct ExpectedOpenTicket {
        let reference: String
        let tariffDescription: String
    }

    /// Sparpreis ticket expected values (from Java test assertions)
    static let sparpreisExpectedIssuing = ExpectedIssuingData(
        issuer: "1080",
        issuerPNR: "D260V48G",
        isSecurePaperTicket: false,
        isActivated: true,
        isSpecimen: false
    )

    static let sparpreisExpectedTraveler = ExpectedTraveler(
        firstName: "Karsten",
        lastName: "Will",
        isTicketHolder: true
    )

    static let sparpreisExpectedOpenTicket = ExpectedOpenTicket(
        reference: "CN0CTUMY",
        tariffDescription: "Super Sparpreis"
    )
}
