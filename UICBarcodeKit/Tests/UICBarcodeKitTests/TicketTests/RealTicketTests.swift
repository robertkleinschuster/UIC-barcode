import XCTest
@testable import UICBarcodeKit

/// Tests for decoding real-world UIC barcode tickets
final class RealTicketTests: XCTestCase {

    // MARK: - Test Data

    /// Real static frame ticket (v02, provider 1181) - ÖBB FCB v3 pass
    static let ticket2Base64 = "I1VUMDIxMTgxMDAwMTAv7HletC0rsBh51kP4k3pq41pf7xGmsHlAh4dHlvNxATKEiI85MryM38FNUmIrMx/VUnbowekCsR+jNytcFymBMDMwN3icC41383GNMDA2MDa2LFJiVGfi95cQ5ovk5GzYaFOtVJKaW5CTWJIallpUnJmfp2SlZGRiaKpnqWegpKOUX1pSUFoSUlmQChQPdnUODfIMiYwPcAxwDVKqdRAVbuBZcu/IqScvpKbdOHXpzrNjF149e3HqyQy/DwIZ0g8YWGSiJkiElmrKbDiyo1F3Y+vZs1MaQw/OPdk6cUrjy6tbgEJLt7YGLu1dO/VCM19EIy9IxdIeg59Lws7vYExmlPrmcuPSnWunTiw49OxZzAMg0XHq2bEnlx68uHTvjkuJy7Qbl24dWnHp2LVTLxzbdRymvDp36s4JlwhkTccOPTkx6QRQbVICBKQB5UGCy049mvPqFkgCKoCiKgUquOTUG5iqXxwMQhIWF06Vpp1qi3QAAJ23qf4="

    /// Real static frame ticket (v01, provider 1181) - ÖBB layout-only (U_TLAY, no U_FLEX)
    static let ticket3Base64 = "I1VUMDExMTgxMDAwMDgwLAIUdyL43a1Lv1wNhYrKB4xKsRzggvgCFBeEWFDOBiOxHXrFEg47pYAhRPcXAAAAADAzODV4nGWSwU6DQBCG7zzFhGNT68wuLGwPJrSuiNam2UKNvTREiZKQtmnRRI1v5s0XcxatmjiHAb6df3b5Z4vVuUlOkRBDSRSTECSVllrpQIRRHAEHcQgUIQkZ4V0FUKzySXLDoiCK7DgX6PQYcg1pfhHxZVPV6/3tw+O+rXZgN4PBwEOC2STJl6iDmOtDdJKrLM8Num8KHAhwWaTA27h9wV5wuk5SM+WnjATned2+bJuyfek6EAqnEmHAB3Q93Dk40W/drtpXu6e62j2u74/3VdnCFynberNG5VQqZpWKiQZEQMFQKIDUJks4H53BIY5OAC6T2ZmZjoxNYZTwP8G3JByi7ooII5TcULmGqtex3k/6G67dP3hAh4UeSTaVOlNJz6zJ5l8LprCAfewwm+5MEGjN3NhFZmwxTT1b1s1F1boKNsR5K+NxlsO23PJENuvm2fPG2QLczL30471p6/shdFNmonV3I6JXf+QPfcc4AtR+31/8AikUgyUDHpj/9gkVnYW7"

    // MARK: - Tests

    func testTicket2Decode() throws {
        let data = Data(base64Encoded: Self.ticket2Base64)!

        let barcodeDecoder = UICBarcodeDecoder()
        let barcode = try barcodeDecoder.decode(data)

        // Verify it's a static frame v2
        if case .staticFrame(let version) = barcode.frameType {
            XCTAssertEqual(version, .v2)
        } else {
            XCTFail("Expected static frame")
        }

        // FCB v3 data inside a v02 static frame
        XCTAssertEqual(barcode.fcbVersion, 3)

        // Verify ticket data was decoded
        let ticket = try XCTUnwrap(barcode.ticket, "Ticket data should be present")

        // Issuing details
        XCTAssertEqual(ticket.issuingDetail.issuingYear, 2024)
        XCTAssertEqual(ticket.issuingDetail.issuingDay, 123)
        XCTAssertEqual(ticket.issuingDetail.specimen, false)

        // Traveler
        let traveler = try XCTUnwrap(ticket.travelerDetail)
        XCTAssertEqual(traveler.traveler?.count, 1)
        let person = try XCTUnwrap(traveler.traveler?.first)
        XCTAssertEqual(person.firstName, "Robert")
        XCTAssertEqual(person.lastName, "Kleinschuster")

        // Transport document - should be a pass
        let docs = try XCTUnwrap(ticket.transportDocument)
        XCTAssertEqual(docs.count, 1)

        if case .pass = docs[0].ticket.ticketType {
            // OK - it's a pass
        } else {
            XCTFail("Expected pass ticket type")
        }
    }

    func testTicket3LayoutOnly() throws {
        let data = Data(base64Encoded: Self.ticket3Base64)!

        let barcodeDecoder = UICBarcodeDecoder()
        let barcode = try barcodeDecoder.decode(data)

        // Verify it's a static frame v1
        if case .staticFrame(let version) = barcode.frameType {
            XCTAssertEqual(version, .v1)
        } else {
            XCTFail("Expected static frame")
        }

        // This is a layout-only ticket (U_TLAY) with no U_FLEX record
        XCTAssertNil(barcode.ticket, "Layout-only ticket should have no FCB data")
        XCTAssertNil(barcode.fcbVersion)

        // Verify the static frame was parsed correctly
        guard let frame = barcode.rawFrame as? StaticFrame else {
            XCTFail("Expected StaticFrame as raw frame")
            return
        }

        // Should have a U_HEAD record
        XCTAssertNotNil(frame.headerRecord)
        XCTAssertEqual(frame.headerRecord?.issuer, "1181")

        // Should have layout records (U_TLAY)
        XCTAssertFalse(frame.layoutRecords.isEmpty, "Should have U_TLAY layout records")

        // Should NOT have a flex record
        XCTAssertNil(frame.flexRecord, "Layout-only ticket should have no U_FLEX record")
    }
}
