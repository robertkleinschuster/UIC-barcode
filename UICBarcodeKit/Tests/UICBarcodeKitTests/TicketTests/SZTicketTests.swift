import XCTest
@testable import UICBarcodeKit

/// SZ (Slovenian) Ticket Tests
/// Translated from Java: SZticketTest.java
/// Tests SSB frame decoding of real-world NRT and Group tickets with DSA signature
final class SZTicketTests: XCTestCase {

    // MARK: - Test Data

    /// NRT (Non-Reservation) ticket base64 from SZticketTest.java
    static let nrtBase64 = "MSbEQEACWRUQQQRTUTAAAAJbAAAAg8md4D3SgYAAAAAAAAAAAAAAAAAAA"
        + "AAAAAAAAAAAAAAAAAAAAIYJ9h44ZY0Kh/z3y89kgvrmVBIQAodNRwl3wlNU/1q6qcoOOjir/"
        + "NX8tZlBGPMrZNQAKdG5WoJc"

    /// Group ticket base64 from SZticketTest.java
    static let groupBase64 = "MSbEYoECVQTQQSQZWUAAAAQwAgHgg8D/ADyYTgAAAAAAAAAAAAAAAAA"
        + "AAAAAAAAAAAAAAAAAAAAAACG89Pn+WUG8sh9neiBKh3hV4flrKftbcscFpVI14W2aKoStC7B"
        + "vvy6hR6u89MB80iOxBxmTlddk"

    /// DSA public key (1024-bit) from SZticketTest.java
    static let publicKeyBase64 = "MIIDQzCCAjUGByqGSM44BAEwggIoAoIBAQDdevkGfuV5U5BmSaaC2ymhw"
        + "+SQQcax2yZRbRExZvaTeOr3NkJlqAgzbvpIAUx5U1rZ3J3ZkFWmkADWds8r1sko8vpqJQDpG"
        + "js0iXP1r7GYAlciPgGRffmfdn5eVCWgFeG381CLFZ4pUVC7SbwusVzcnGRt/V1wxNdRRxCXG"
        + "q1O1L63PiSRNW5RJv/JsVHaqZMbCEigh2NXYkCB0BgDFub+2NTAW7GnllX9F656zpP6gwV6K"
        + "AymUha5bH33c1rDuhmO25iNrWwW60Sxrl8rs93k2FQB4AzelCw/6MS9uHerdABdedzlUqN7w"
        + "UleJCgc25w3eoTPKnbEF4xdaeR3afvfAh0AiNWFRF2DOZZ+koG4K39Vr94q47YILo7LOeuPO"
        + "wKCAQBG0Pt3roTa9Aau2U7hZINGcSUI5hLbpMwtrXtAnDtWkQOqPO11vvXJhYHZQkM4wOmhR"
        + "uT4OxolKvWHjvkvlKoGx4gZMdASio8UuaCbtKo2588xQ4SY1+Cs2lhRRuhfYce5rv9DhOjgf"
        + "Yv9zxR7Skt6UAbndJtpmSo6mxBK/G2w6FIxzsWBPekaZ/nXWMHFNv/6SDtIrQM3W+DqCckj8"
        + "c7tG6zLHcMYh/OIfnc0mVN1EgxsovJz/XmN3LsInIZq8cxQNH9l/TsexLVJrQ3odfA5VmcoH"
        + "inIQV8K1Iak3NcclwOzvk5sup8cPKoMf4p1YFO5OcW3WR5HFB42VimkoyK4A4IBBgACggEBA"
        + "Kr1MuBndeKbZDHyZ4opf0a3dJd00lBgp5dH5SF7Um8LnqY2SGYd7IvXBOjP1fdFub4CLNPXn"
        + "265gQF7HkDBu0zd+Sy2glzCabOz7j1LJezaaEGGHDndBwTsGGrQ0JRcB2SR3cCFdmjmzEFlJ"
        + "xarriD7K7N5jSBT1mJCmNvkTk8dgtoBcIW6qxQe+Q72UFyME+6H/6Nnh+X2tv4CbVnmmTXT1"
        + "ktaZjf+RrFc5eT1nPVFDZcNaDwzUapf4fLqGXw46JmB0WM5+o5zTR7Q+1AWHEn0D4eqEWoui"
        + "wXbIxiV/JQEW55eWnz3oSClRLOFNL3zqEydGrr4RSh0AS4wE8EjNIY="

    // MARK: - NRT Ticket Tests

    /// Test decoding NRT (Non-Reservation) SSB ticket
    func testNRTTicketDecoding() throws {
        let data = Data(base64Encoded: Self.nrtBase64)!
        XCTAssertEqual(data.count, 114, "SSB frame must be 114 bytes")

        let frame = try SSBFrame(data: data)

        // Header assertions
        XCTAssertEqual(frame.header.version, 3)
        XCTAssertEqual(frame.header.issuer, 1179)
        XCTAssertEqual(frame.header.keyId, 1)
        XCTAssertEqual(frame.header.ticketType, .nrt)

        // Must have NRT data
        XCTAssertNotNil(frame.nonReservationData)
        XCTAssertNil(frame.reservationData)
        XCTAssertNil(frame.passData)
        XCTAssertNil(frame.groupData)
        XCTAssertNil(frame.nonUicData)

        let nrt = frame.nonReservationData!

        // Common fields
        XCTAssertEqual(nrt.common.numberOfAdults, 1)
        XCTAssertEqual(nrt.common.numberOfChildren, 0)
        XCTAssertEqual(nrt.common.specimen, false)
        XCTAssertEqual(nrt.common.classCode, .second)
        XCTAssertEqual(nrt.common.ticketNumber, "6140001343")
        XCTAssertEqual(nrt.common.year, 2)
        XCTAssertEqual(nrt.common.day, 182)

        // Validity
        XCTAssertEqual(nrt.firstDayOfValidity, 0)
        XCTAssertEqual(nrt.lastDayOfValidity, 0)

        // Stations - numeric mode
        XCTAssertFalse(nrt.stations.alphaNumeric)
        XCTAssertEqual(nrt.stations.codeTable, .nrt)
        XCTAssertEqual(nrt.stations.departureStationCode, "7943100")
        XCTAssertEqual(nrt.stations.arrivalStationCode, "8103171")

        // Info
        XCTAssertEqual(nrt.infoCode, 0)
        XCTAssertEqual(nrt.text, "")

        // Signature parts must exist
        XCTAssertFalse(frame.signaturePart1.isEmpty)
        XCTAssertFalse(frame.signaturePart2.isEmpty)
    }

    /// Test decoding Group SSB ticket
    func testGroupTicketDecoding() throws {
        let data = Data(base64Encoded: Self.groupBase64)!
        XCTAssertEqual(data.count, 114, "SSB frame must be 114 bytes")

        let frame = try SSBFrame(data: data)

        // Header assertions
        XCTAssertEqual(frame.header.version, 3)
        XCTAssertEqual(frame.header.issuer, 1179)
        XCTAssertEqual(frame.header.keyId, 1)
        XCTAssertEqual(frame.header.ticketType, .grp)

        // Must have Group data
        XCTAssertNotNil(frame.groupData)
        XCTAssertNil(frame.nonReservationData)
        XCTAssertNil(frame.reservationData)
        XCTAssertNil(frame.passData)
        XCTAssertNil(frame.nonUicData)

        let grp = frame.groupData!

        // Common fields
        XCTAssertEqual(grp.common.numberOfAdults, 10)
        XCTAssertEqual(grp.common.numberOfChildren, 2)
        XCTAssertEqual(grp.common.specimen, false)
        XCTAssertEqual(grp.common.classCode, .second)
        XCTAssertEqual(grp.common.ticketNumber, "5030020964")
        XCTAssertEqual(grp.common.year, 4)
        XCTAssertEqual(grp.common.day, 96)

        // Not a return journey
        XCTAssertFalse(grp.isReturnJourney)

        // Validity
        XCTAssertEqual(grp.firstDayOfValidity, 16)
        XCTAssertEqual(grp.lastDayOfValidity, 30)

        // Stations - numeric mode
        XCTAssertFalse(grp.stations.alphaNumeric)
        XCTAssertEqual(grp.stations.codeTable, .nrt)
        XCTAssertEqual(grp.stations.departureStationCode, "7872480")
        XCTAssertEqual(grp.stations.arrivalStationCode, "7942300")

        // Group-specific
        XCTAssertEqual(grp.groupName, "")
        XCTAssertEqual(grp.counterMarkNumber, 0)
        XCTAssertEqual(grp.infoCode, 0)
        XCTAssertEqual(grp.text, "")

        // Signature parts must exist
        XCTAssertFalse(frame.signaturePart1.isEmpty)
        XCTAssertFalse(frame.signaturePart2.isEmpty)
    }

    /// Test DSA signature verification for NRT ticket
    func testNRTSignatureVerification() throws {
        let ticketData = Data(base64Encoded: Self.nrtBase64)!
        let publicKeyData = Data(base64Encoded: Self.publicKeyBase64)!

        let frame = try SSBFrame(data: ticketData)
        let dataToVerify = frame.getDataForSignature(ticketData)
        let signature = try frame.getSignature()

        // Verify using DSA
        let result = try SignatureVerifier.verify(
            signature: signature,
            data: dataToVerify,
            publicKey: publicKeyData,
            algorithmOID: AlgorithmOID.dsa_sha224_oid
        )
        XCTAssertTrue(result, "DSA-SHA224 signature should verify for NRT ticket")
    }

    /// Test DSA signature verification for Group ticket
    func testGroupSignatureVerification() throws {
        let ticketData = Data(base64Encoded: Self.groupBase64)!
        let publicKeyData = Data(base64Encoded: Self.publicKeyBase64)!

        let frame = try SSBFrame(data: ticketData)
        let dataToVerify = frame.getDataForSignature(ticketData)
        let signature = try frame.getSignature()

        // Verify using DSA
        let result = try SignatureVerifier.verify(
            signature: signature,
            data: dataToVerify,
            publicKey: publicKeyData,
            algorithmOID: AlgorithmOID.dsa_sha224_oid
        )
        XCTAssertTrue(result, "DSA-SHA224 signature should verify for Group ticket")
    }
}
