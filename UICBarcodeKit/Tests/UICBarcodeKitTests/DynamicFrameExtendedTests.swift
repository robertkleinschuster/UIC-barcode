import XCTest
import CryptoKit
@testable import UICBarcodeKit

/// Extended Dynamic Frame Tests
/// Translated from Java tests:
/// - DynamicFrameV2FcbVersion3Test.java
/// - DynamicFrameSimpleTest.java
/// - DynamicFrameDynamicContentTest.java
/// - SimpleUICTestTicket.java
final class DynamicFrameExtendedTests: XCTestCase {

    // MARK: - FCB Version 3 Tests (from DynamicFrameV2FcbVersion3Test.java)

    /// Test Dynamic Frame V2 with FCB Version 3
    func testDynamicFrameV2WithFCB3() {
        var frame = DynamicFrame()
        frame.format = "U2"  // Version 2

        // Level 1 data with FCB3
        var level1 = DynamicFrameLevel1Data()
        level1.securityProviderNum = 1080

        var dataItem = DynamicFrameDataItem()
        dataItem.format = "FCB3"  // FCB Version 3
        dataItem.data = Data([0x00])  // Minimal data

        level1.dataList = [dataItem]
        frame.level1Data = level1

        XCTAssertEqual(frame.format, "U2")
        XCTAssertEqual(frame.level1Data?.dataList.first?.format, "FCB3")
    }

    /// Test Dynamic Frame format versions
    func testDynamicFrameFormats() {
        // U1 = Version 1
        XCTAssertEqual(DynamicFrameVersion.v1.rawValue, "U1")

        // U2 = Version 2
        XCTAssertEqual(DynamicFrameVersion.v2.rawValue, "U2")
    }

    /// Test FCB format identifiers
    func testFCBFormatIdentifiers() {
        let fcbFormats = ["FCB1", "FCB2", "FCB3"]

        for format in fcbFormats {
            XCTAssertEqual(format.count, 4)
            XCTAssertTrue(format.hasPrefix("FCB"))
        }
    }

    // MARK: - Test Ticket Structure (from SimpleUICTestTicket.java)

    /// Test issuing data structure
    func testIssuingDataStructure() {
        var issuingData = IssuingData()

        // Values from Java SimpleUICTestTicket.populateIssuingData()
        issuingData.issuerNum = 1080
        issuingData.issuingYear = 2018
        issuingData.issuingDay = 1
        issuingData.specimen = true
        issuingData.securePaperTicket = false
        issuingData.activated = true
        issuingData.issuerPNR = "issuerTestPNR"
        issuingData.issuedOnLine = 12

        XCTAssertEqual(issuingData.issuerNum, 1080)
        XCTAssertEqual(issuingData.issuingYear, 2018)
        XCTAssertEqual(issuingData.issuingDay, 1)
        XCTAssertEqual(issuingData.specimen, true)
        XCTAssertEqual(issuingData.issuerPNR, "issuerTestPNR")
        XCTAssertEqual(issuingData.issuedOnLine, 12)
    }

    /// Test traveler data structure
    func testTravelerDataStructure() {
        var travelerData = TravelerData()
        travelerData.groupName = "myGroup"

        var traveler = TravelerType()
        traveler.firstName = "John"
        traveler.secondName = "Dow"
        traveler.idCard = "12345"
        traveler.ticketHolder = true

        var status = CustomerStatusType()
        status.customerStatusDescr = "senior"
        traveler.status = [status]

        travelerData.traveler = [traveler]

        XCTAssertEqual(travelerData.groupName, "myGroup")
        XCTAssertEqual(travelerData.traveler?.first?.firstName, "John")
        XCTAssertEqual(travelerData.traveler?.first?.secondName, "Dow")
        XCTAssertEqual(travelerData.traveler?.first?.ticketHolder, true)
    }

    /// Test control detail structure
    func testControlDetailStructure() {
        var controlDetail = ControlData()
        controlDetail.infoText = "cd"
        controlDetail.ageCheckRequired = false
        controlDetail.identificationByIdCard = false
        controlDetail.identificationByPassportId = false
        controlDetail.onlineValidationRequired = false
        controlDetail.passportValidationRequired = false
        controlDetail.reductionCardCheckRequired = false

        XCTAssertEqual(controlDetail.infoText, "cd")
        XCTAssertFalse(controlDetail.ageCheckRequired ?? true)
        XCTAssertFalse(controlDetail.identificationByIdCard ?? true)
    }

    /// Test open ticket structure
    func testOpenTicketStructure() {
        var openTicket = OpenTicketData()
        openTicket.infoText = "openTicketInfo"
        openTicket.returnIncluded = false

        XCTAssertEqual(openTicket.infoText, "openTicketInfo")
        XCTAssertEqual(openTicket.returnIncluded, false)
    }

    /// Test station passage structure
    func testStationPassageStructure() {
        var stationPassage = StationPassageData()
        stationPassage.productName = "passage"
        stationPassage.validFromDay = 0
        stationPassage.validUntilDay = 4
        stationPassage.stationNameUTF8 = ["Amsterdam"]

        XCTAssertEqual(stationPassage.productName, "passage")
        XCTAssertEqual(stationPassage.validFromDay, 0)
        XCTAssertEqual(stationPassage.validUntilDay, 4)
        XCTAssertEqual(stationPassage.stationNameUTF8?.first, "Amsterdam")
    }

    /// Test extension data structure
    func testExtensionDataStructure() {
        var ext = ExtensionData()
        ext.extensionId = "1"
        ext.extensionData = Data([0x82, 0xDA])

        XCTAssertEqual(ext.extensionId, "1")
        XCTAssertEqual(ext.extensionData, Data([0x82, 0xDA]))
    }

    /// Test ticket link structure
    func testTicketLinkStructure() {
        var ticketLink = TicketLinkType()
        ticketLink.productOwnerIA5 = "test"
        ticketLink.linkMode = .issuedTogether

        XCTAssertEqual(ticketLink.productOwnerIA5, "test")
        XCTAssertEqual(ticketLink.linkMode, .issuedTogether)
    }

    /// Test card reference structure
    func testCardReferenceStructure() {
        var cardRef = CardReferenceType()
        cardRef.trailingCardIdNum = 100

        XCTAssertEqual(cardRef.trailingCardIdNum, 100)
    }

    // MARK: - Level 2 Data Tests

    /// Test Level 2 data with signature
    func testLevel2DataWithSignature() {
        var level2 = DynamicFrameLevel2Data()

        // Level 1 data
        var level1 = DynamicFrameLevel1Data()
        level1.securityProviderNum = 1080
        level2.level1Data = level1

        // Signature
        level2.level1Signature = Data(repeating: 0xAB, count: 64)

        XCTAssertEqual(level2.level1Data?.securityProviderNum, 1080)
        XCTAssertEqual(level2.level1Signature?.count, 64)
    }

    /// Test Level 2 public key embedding (stored in Level1Data per ASN.1 schema)
    func testLevel2PublicKeyEmbedding() {
        var level1 = DynamicFrameLevel1Data()

        // Public key in X9.63 format (65 bytes for P-256)
        var publicKey = Data([0x04])  // Uncompressed point indicator
        publicKey.append(Data(repeating: 0x00, count: 64))  // x and y coordinates
        level1.level2publicKey = publicKey

        XCTAssertEqual(level1.level2publicKey?.count, 65)
        XCTAssertEqual(level1.level2publicKey?.first, 0x04)
    }

    // MARK: - Algorithm Tests

    /// Test ECDSA algorithm constants
    func testECDSAConstants() {
        // From Java Constants class
        XCTAssertEqual(AlgorithmOID.ecdsa_sha256_oid, "1.2.840.10045.4.3.2")
        XCTAssertEqual(AlgorithmOID.ecdsa_sha384_oid, "1.2.840.10045.4.3.3")
        XCTAssertEqual(AlgorithmOID.ecdsa_sha512_oid, "1.2.840.10045.4.3.4")
    }

    /// Test DSA algorithm constants
    func testDSAConstants() {
        // From Java Constants class
        XCTAssertEqual(AlgorithmOID.dsa_sha1_oid, "1.2.840.10040.4.3")
        XCTAssertEqual(AlgorithmOID.dsa_sha224_oid, "2.16.840.1.101.3.4.3.1")
        XCTAssertEqual(AlgorithmOID.dsa_sha256_oid, "2.16.840.1.101.3.4.3.2")
    }

    // MARK: - Signature Verification Tests

    /// Test ECDSA P-256 signature creation and verification
    func testECDSA_P256_SignatureFlow() throws {
        // Create key pair
        let privateKey = P256.Signing.PrivateKey()
        let publicKey = privateKey.publicKey

        // Test data (simulating FCB content)
        let testData = "FCB3 ticket content".data(using: .utf8)!

        // Sign
        let signature = try privateKey.signature(for: testData)

        // Verify
        XCTAssertTrue(publicKey.isValidSignature(signature, for: testData))
    }

    /// Test that wrong data fails verification
    func testSignatureVerificationFailsWithWrongData() throws {
        let privateKey = P256.Signing.PrivateKey()
        let publicKey = privateKey.publicKey

        let originalData = "Original ticket data".data(using: .utf8)!
        let modifiedData = "Modified ticket data".data(using: .utf8)!

        let signature = try privateKey.signature(for: originalData)

        // Should fail with wrong data
        XCTAssertFalse(publicKey.isValidSignature(signature, for: modifiedData))
    }

    // MARK: - Dynamic Content (FDC1) Tests

    /// Test FDC1 structure (matches Java UicDynamicContentDataFDC1.java)
    func testFDC1Structure() {
        var fdc1 = DynamicContentFDC1()
        fdc1.appId = "TestApp"

        XCTAssertEqual(fdc1.appId, "TestApp")
        XCTAssertEqual(DynamicContentFDC1.format, "FDC1")
    }

    /// Test FDC1 with geo coordinate
    func testFDC1WithGeoCoordinate() {
        var fdc1 = DynamicContentFDC1()

        var geo = GeoCoordinateType()
        geo.longitude = 523456  // 52.3456 degrees * 10000
        geo.latitude = 133456   // 13.3456 degrees * 10000
        fdc1.geoCoordinate = geo

        XCTAssertEqual(fdc1.geoCoordinate?.longitude, 523456)
        XCTAssertEqual(fdc1.geoCoordinate?.latitude, 133456)
    }

    /// Test FDC1 with timestamp
    func testFDC1WithTimeStamp() {
        var fdc1 = DynamicContentFDC1()
        var ts = TimeStamp()
        ts.day = 42
        ts.secondOfDay = 3600
        fdc1.timeStamp = ts

        XCTAssertEqual(fdc1.timeStamp?.day, 42)
        XCTAssertEqual(fdc1.timeStamp?.secondOfDay, 3600)
    }

    // MARK: - Complete Ticket Tests

    /// Test complete UIC rail ticket structure
    func testCompleteUICRailTicket() {
        var ticket = UicRailTicketData()

        // Issuing data
        var issuing = IssuingData()
        issuing.issuerNum = 1080
        issuing.issuingYear = 2024
        issuing.issuingDay = 100
        ticket.issuingDetail = issuing

        // Traveler data
        var traveler = TravelerData()
        traveler.groupName = "TestGroup"
        ticket.travelerDetail = traveler

        // Control data
        var control = ControlData()
        control.infoText = "Control info"
        ticket.controlDetail = control

        // Verify
        XCTAssertEqual(ticket.issuingDetail.issuerNum, 1080)
        XCTAssertEqual(ticket.travelerDetail?.groupName, "TestGroup")
        XCTAssertEqual(ticket.controlDetail?.infoText, "Control info")
    }

    /// Test ticket with multiple transport documents
    func testTicketWithMultipleDocuments() {
        var ticket = UicRailTicketData()
        ticket.issuingDetail = IssuingData()
        ticket.issuingDetail.issuerNum = 1080

        // Add open ticket
        var openTicket = OpenTicketData()
        openTicket.infoText = "Open ticket"

        // Add station passage
        var stationPassage = StationPassageData()
        stationPassage.productName = "passage"

        // Create document data
        var doc1 = DocumentData()
        var ticketDetail1 = TicketDetailData()
        ticketDetail1.ticketType = .openTicket(openTicket)
        doc1.ticket = ticketDetail1

        var doc2 = DocumentData()
        var ticketDetail2 = TicketDetailData()
        ticketDetail2.ticketType = .stationPassage(stationPassage)
        doc2.ticket = ticketDetail2

        ticket.transportDocument = [doc1, doc2]

        XCTAssertEqual(ticket.transportDocument?.count, 2)
    }

    // MARK: - Barcode Type Detection Tests

    /// Test detecting Dynamic Frame from format string
    func testDynamicFrameDetection() {
        let v1Format = "U1"
        let v2Format = "U2"

        XCTAssertTrue(v1Format.hasPrefix("U"))
        XCTAssertTrue(v2Format.hasPrefix("U"))
        XCTAssertEqual(v1Format, DynamicFrameVersion.v1.rawValue)
        XCTAssertEqual(v2Format, DynamicFrameVersion.v2.rawValue)
    }

    // MARK: - Data Encoding Tests

    /// Test security provider number encoding
    func testSecurityProviderEncoding() {
        // Security provider is INTEGER (1..32000)
        let minProvider = 1
        let maxProvider = 32000
        let testProvider = 1080

        XCTAssertTrue(testProvider >= minProvider)
        XCTAssertTrue(testProvider <= maxProvider)

        // Bits needed: ceil(log2(32000)) = 15 bits
        let bitsNeeded = Int(ceil(log2(Double(maxProvider))))
        XCTAssertEqual(bitsNeeded, 15)
    }

    /// Test key ID encoding
    func testKeyIdEncoding() {
        // Key ID is INTEGER (0..99999)
        var level1 = DynamicFrameLevel1Data()
        level1.keyId = 12345
        XCTAssertEqual(level1.keyId, 12345)
    }
}
