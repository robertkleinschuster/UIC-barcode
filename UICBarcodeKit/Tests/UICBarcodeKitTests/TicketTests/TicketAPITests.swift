import XCTest
@testable import UICBarcodeKit

/// Tests for the version-independent Ticket API layer.
/// Verifies that ASN.1 → API conversion works correctly for V1, V2, and V3.
final class TicketAPITests: XCTestCase {

    // MARK: - V3 API Decoder

    func testV3IssuingDetail() throws {
        let data = TestTicketsV3.allElementsData
        var decoder = UPERDecoder(data: data)
        let asn = try UicRailTicketData(from: &decoder)
        let api = UicRailTicketCoder.decode(asn)

        let issuing = try XCTUnwrap(api.issuingDetail)
        XCTAssertEqual(issuing.securityProvider, "1") // securityProviderIA5 preferred over Num
        XCTAssertEqual(issuing.issuer, "1") // issuerIA5 preferred over Num
        XCTAssertEqual(issuing.issuerName, "name")
        XCTAssertEqual(issuing.specimen, true)
        XCTAssertEqual(issuing.securePaperTicket, false)
        XCTAssertEqual(issuing.activated, true)
        XCTAssertEqual(issuing.currency, "SRF")
        XCTAssertEqual(issuing.currencyFraction, 3)
        XCTAssertEqual(issuing.issuerPNR, "issuerTestPNR")
        XCTAssertEqual(issuing.issuedOnTrain, "123") // IA5 preferred
        XCTAssertEqual(issuing.issuedOnLine, 12)
        XCTAssertNotNil(issuing.issuingDate)
    }

    func testV3TravelerDetail() throws {
        let data = TestTicketsV3.allElementsData
        var decoder = UPERDecoder(data: data)
        let asn = try UicRailTicketData(from: &decoder)
        let api = UicRailTicketCoder.decode(asn)

        let td = try XCTUnwrap(api.travelerDetail)
        XCTAssertEqual(td.groupName, "myGroup")
        XCTAssertEqual(td.preferedLanguage, "EN")

        let t = try XCTUnwrap(td.travelers.first)
        XCTAssertEqual(t.firstName, "John")
        XCTAssertEqual(t.secondName, "Little")
        XCTAssertEqual(t.lastName, "Dow")
        XCTAssertEqual(t.idCard, "12345")
        XCTAssertEqual(t.passportId, "JDTS")
        XCTAssertEqual(t.title, "PhD")
        XCTAssertEqual(t.gender, .male)
        XCTAssertEqual(t.customerId, "DZE5gT") // IA5 preferred
        XCTAssertEqual(t.ticketHolder, true)
        XCTAssertEqual(t.passengerType, .senior)
        XCTAssertEqual(t.passengerWithReducedMobility, false)
        XCTAssertEqual(t.countryOfResidence, 101)
        XCTAssertEqual(t.passportCountry, 102)
        XCTAssertEqual(t.idCardCountry, 103)

        // Date of birth
        XCTAssertNotNil(t.dateOfBirth)

        // Customer status
        XCTAssertEqual(t.status.count, 1)
        XCTAssertEqual(t.status.first?.customerStatus, 1)
        XCTAssertEqual(t.status.first?.customerStatusDescr, "senior")
    }

    func testV3Reservation() throws {
        let data = TestTicketsV3.allElementsData
        var decoder = UPERDecoder(data: data)
        let asn = try UicRailTicketData(from: &decoder)
        let api = UicRailTicketCoder.decode(asn)

        // First document should be a reservation
        guard case .reservation(let r) = api.documents.first else {
            XCTFail("Expected reservation as first document"); return
        }

        // Verify key fields are populated (exact values depend on test hex data)
        XCTAssertNotNil(r.train)
        XCTAssertNotNil(r.reference)
        XCTAssertNotNil(r.productOwner)
        XCTAssertNotNil(r.productId)
        XCTAssertEqual(r.stationCodeTable, .stationUIC)
        XCTAssertNotNil(r.fromStation)
        XCTAssertNotNil(r.toStation)
        XCTAssertEqual(r.fromStationName, "A-STATION")
        XCTAssertEqual(r.toStationName, "B-STATION")
        XCTAssertEqual(r.classCode, .first)
        XCTAssertEqual(r.serviceLevel, "A")
        XCTAssertEqual(r.service, .couchette)
        XCTAssertEqual(r.price, 12345)
        XCTAssertEqual(r.priceType, .travelPrice)
        XCTAssertEqual(r.typeOfSupplement, 9)
        XCTAssertEqual(r.numberOfSupplements, 2)
        XCTAssertEqual(r.numberOfOverbooked, 200)
        XCTAssertEqual(r.infoText, "reservation")
        XCTAssertEqual(r.departureUTCoffset, -60)
        XCTAssertEqual(r.arrivalUTCoffset, 10)

        // Service brand
        XCTAssertEqual(r.serviceBrand?.serviceBrandNum, 12)
        XCTAssertEqual(r.serviceBrand?.serviceBrandAbrUTF8, "TGV")
        XCTAssertEqual(r.serviceBrand?.serviceBrandNameUTF8, "Lyria")

        // Carriers
        XCTAssertEqual(r.carriers, ["1080", "1181"])

        // Places
        XCTAssertEqual(r.places?.coach, "31A")
        XCTAssertEqual(r.places?.placeString, "31-47")
        XCTAssertEqual(r.places?.placeDescription, "Window")

        // Berths
        XCTAssertEqual(r.berths.count, 1)
        XCTAssertEqual(r.berths.first?.berthType, .single)
        XCTAssertEqual(r.berths.first?.gender, .female)
        XCTAssertEqual(r.berths.first?.numberOfBerths, 999)

        // Tariffs
        XCTAssertEqual(r.tariffs.count, 1)
        XCTAssertEqual(r.tariffs.first?.passengerType, .senior)
        XCTAssertEqual(r.tariffs.first?.tariffDesc, "Leasure Fare")

        // VAT
        XCTAssertEqual(r.vatDetails.count, 1)
        XCTAssertEqual(r.vatDetails.first?.country, 80)
        XCTAssertEqual(r.vatDetails.first?.percentage, 70)
        XCTAssertEqual(r.vatDetails.first?.amount, 10)
        XCTAssertEqual(r.vatDetails.first?.vatId, "IUDGTE")

        // Luggage
        XCTAssertNotNil(r.luggageRestriction)
        XCTAssertEqual(r.luggageRestriction?.maxHandLuggagePieces, 2)
        XCTAssertEqual(r.luggageRestriction?.maxNonHandLuggagePieces, 1)
    }

    func testV3ControlDetail() throws {
        let data = TestTicketsV3.allElementsData
        var decoder = UPERDecoder(data: data)
        let asn = try UicRailTicketData(from: &decoder)
        let api = UicRailTicketCoder.decode(asn)

        let ctrl = try XCTUnwrap(api.controlDetail)
        XCTAssertEqual(ctrl.infoText, "control")

        XCTAssertGreaterThan(ctrl.identificationByCardReference.count, 0)
        XCTAssertGreaterThan(ctrl.includedTickets.count, 0)
    }

    func testV3DocumentTypes() throws {
        let data = TestTicketsV3.allElementsData
        var decoder = UPERDecoder(data: data)
        let asn = try UicRailTicketData(from: &decoder)
        let api = UicRailTicketCoder.decode(asn)

        // V3 all-elements should have 12 documents
        XCTAssertEqual(api.documents.count, 12)

        // Verify document types in order
        guard case .reservation = api.documents[0] else { XCTFail("doc 0 should be reservation"); return }
        guard case .carCarriageReservation = api.documents[1] else { XCTFail("doc 1 should be carCarriageReservation"); return }
        guard case .openTicket = api.documents[2] else { XCTFail("doc 2 should be openTicket"); return }
        guard case .pass = api.documents[3] else { XCTFail("doc 3 should be pass"); return }
        guard case .voucher = api.documents[4] else { XCTFail("doc 4 should be voucher"); return }
        guard case .customerCard = api.documents[5] else { XCTFail("doc 5 should be customerCard"); return }
        guard case .counterMark = api.documents[6] else { XCTFail("doc 6 should be counterMark"); return }
        guard case .parkingGround = api.documents[7] else { XCTFail("doc 7 should be parkingGround"); return }
        guard case .fipTicket = api.documents[8] else { XCTFail("doc 8 should be fipTicket"); return }
        guard case .stationPassage = api.documents[9] else { XCTFail("doc 9 should be stationPassage"); return }
        guard case .documentExtension = api.documents[10] else { XCTFail("doc 10 should be documentExtension"); return }
        guard case .delayConfirmation = api.documents[11] else { XCTFail("doc 11 should be delayConfirmation"); return }
    }

    func testV3Extensions() throws {
        let data = TestTicketsV3.allElementsData
        var decoder = UPERDecoder(data: data)
        let asn = try UicRailTicketData(from: &decoder)
        let api = UicRailTicketCoder.decode(asn)

        XCTAssertEqual(api.extensions.count, 2)
        XCTAssertEqual(api.extensions[0].extensionId, "1")
        XCTAssertNotNil(api.extensions[0].extensionData)
        XCTAssertEqual(api.extensions[1].extensionId, "2")
        XCTAssertNotNil(api.extensions[1].extensionData)
    }

    // MARK: - V1 API Decoder

    func testV1APIConversion() throws {
        let data = TestTicketsV1.allElementsData
        // Decode as V1 natively
        var decoder = UPERDecoder(data: data)
        let asnV1 = try UicRailTicketDataV1(from: &decoder)
        let api = UicRailTicketCoder.decode(asnV1)

        // Issuing detail
        let issuing = try XCTUnwrap(api.issuingDetail)
        XCTAssertEqual(issuing.securityProvider, "1") // IA5 preferred
        XCTAssertEqual(issuing.issuerName, "name")
        XCTAssertEqual(issuing.specimen, true)
        XCTAssertEqual(issuing.activated, true)
        XCTAssertEqual(issuing.currency, "SRF")
        XCTAssertEqual(issuing.currencyFraction, 3)
        XCTAssertEqual(issuing.issuerPNR, "issuerTestPNR")
        XCTAssertEqual(issuing.issuedOnLine, 12)
        XCTAssertNotNil(issuing.issuingDate)

        // Traveler detail
        let td = try XCTUnwrap(api.travelerDetail)
        XCTAssertEqual(td.groupName, "myGroup")
        XCTAssertEqual(td.preferedLanguage, "EN")

        let t = try XCTUnwrap(td.travelers.first)
        XCTAssertEqual(t.firstName, "John")
        XCTAssertEqual(t.lastName, "Dow")
        XCTAssertEqual(t.gender, .male)
        XCTAssertEqual(t.ticketHolder, true)
        XCTAssertEqual(t.passengerType, .senior)

        // Documents
        XCTAssertEqual(api.documents.count, 12)

        // Control detail
        XCTAssertNotNil(api.controlDetail)

        // Extensions
        XCTAssertEqual(api.extensions.count, 2)
    }

    func testV1ReservationAPI() throws {
        let data = TestTicketsV1.allElementsData
        var decoder = UPERDecoder(data: data)
        let asnV1 = try UicRailTicketDataV1(from: &decoder)
        let api = UicRailTicketCoder.decode(asnV1)

        guard case .reservation(let r) = api.documents.first else {
            XCTFail("Expected reservation as first document"); return
        }

        XCTAssertEqual(r.train, "12345")
        XCTAssertEqual(r.reference, "810123456789")
        XCTAssertEqual(r.productOwner, "23456")
        XCTAssertEqual(r.productId, "23456")
        XCTAssertEqual(r.stationCodeTable, .stationUIC)
        XCTAssertEqual(r.fromStation, "8100001")
        XCTAssertEqual(r.toStation, "8100002")
        XCTAssertEqual(r.fromStationName, "A-STATION")
        XCTAssertEqual(r.toStationName, "B-STATION")
        XCTAssertEqual(r.classCode, .first)
        XCTAssertEqual(r.serviceLevel, "A")
        XCTAssertEqual(r.service, .couchette)
        XCTAssertEqual(r.price, 12345)
        XCTAssertEqual(r.priceType, .travelPrice)
        XCTAssertEqual(r.infoText, "reservation")
        XCTAssertEqual(r.carriers, ["1080", "1181"])

        // Service brand
        XCTAssertEqual(r.serviceBrand?.serviceBrandNum, 12)
        XCTAssertEqual(r.serviceBrand?.serviceBrandAbrUTF8, "TGV")
        XCTAssertEqual(r.serviceBrand?.serviceBrandNameUTF8, "Lyria")

        // Tariffs
        XCTAssertEqual(r.tariffs.count, 1)
        XCTAssertEqual(r.tariffs.first?.passengerType, .senior)
    }

    // MARK: - V2 API Decoder

    func testV2APIConversion() throws {
        let data = TestTicketsV2.allElementsData
        var decoder = UPERDecoder(data: data)
        let asnV2 = try UicRailTicketDataV2(from: &decoder)
        let api = UicRailTicketCoder.decode(asnV2)

        // Issuing detail
        let issuing = try XCTUnwrap(api.issuingDetail)
        XCTAssertEqual(issuing.securityProvider, "1")
        XCTAssertEqual(issuing.issuerName, "name")
        XCTAssertEqual(issuing.specimen, true)
        XCTAssertEqual(issuing.activated, true)
        XCTAssertEqual(issuing.currency, "SRF")
        XCTAssertEqual(issuing.currencyFraction, 3)
        XCTAssertEqual(issuing.issuerPNR, "issuerTestPNR")
        XCTAssertEqual(issuing.issuedOnLine, 12)
        XCTAssertNotNil(issuing.issuingDate)

        // Traveler detail
        let td = try XCTUnwrap(api.travelerDetail)
        XCTAssertEqual(td.groupName, "myGroup")
        XCTAssertEqual(td.preferedLanguage, "EN")

        let t = try XCTUnwrap(td.travelers.first)
        XCTAssertEqual(t.firstName, "John")
        XCTAssertEqual(t.lastName, "Dow")
        XCTAssertEqual(t.gender, .male)
        XCTAssertEqual(t.ticketHolder, true)
        XCTAssertEqual(t.passengerType, .senior)

        // Documents
        XCTAssertEqual(api.documents.count, 12)

        // Control detail
        XCTAssertNotNil(api.controlDetail)

        // Extensions
        XCTAssertEqual(api.extensions.count, 2)
    }

    func testV2ReservationAPI() throws {
        let data = TestTicketsV2.allElementsData
        var decoder = UPERDecoder(data: data)
        let asnV2 = try UicRailTicketDataV2(from: &decoder)
        let api = UicRailTicketCoder.decode(asnV2)

        guard case .reservation(let r) = api.documents.first else {
            XCTFail("Expected reservation as first document"); return
        }

        // V2 has trainIA5 → train
        XCTAssertNotNil(r.train)
        XCTAssertEqual(r.reference, "810123456789")
        // V2 has productOwnerNum=23456 (no IA5) → "23456"
        XCTAssertEqual(r.productOwner, "23456")
        // V2 has productIdIA5="23456" → "23456"
        XCTAssertEqual(r.productId, "23456")
        XCTAssertEqual(r.stationCodeTable, .stationUIC)
        // V2 has fromStationNum=8100001 (no IA5) → "8100001"
        XCTAssertEqual(r.fromStation, "8100001")
        XCTAssertEqual(r.classCode, .first)
        XCTAssertEqual(r.service, .couchette)
        XCTAssertEqual(r.price, 12345)
        XCTAssertEqual(r.infoText, "reservation")

        // Service brand
        XCTAssertEqual(r.serviceBrand?.serviceBrandNum, 12)
        XCTAssertEqual(r.serviceBrand?.serviceBrandAbrUTF8, "TGV")

        // Tariffs
        XCTAssertEqual(r.tariffs.count, 1)
    }

    // MARK: - Cross-Version Consistency

    func testAllVersionsProduceSameReservationFields() throws {
        // Decode V1
        let v1Data = TestTicketsV1.allElementsData
        var v1Decoder = UPERDecoder(data: v1Data)
        let asnV1 = try UicRailTicketDataV1(from: &v1Decoder)
        let apiV1 = UicRailTicketCoder.decode(asnV1)

        // Decode V2
        let v2Data = TestTicketsV2.allElementsData
        var v2Decoder = UPERDecoder(data: v2Data)
        let asnV2 = try UicRailTicketDataV2(from: &v2Decoder)
        let apiV2 = UicRailTicketCoder.decode(asnV2)

        // Decode V3
        let v3Data = TestTicketsV3.allElementsData
        var v3Decoder = UPERDecoder(data: v3Data)
        let asnV3 = try UicRailTicketData(from: &v3Decoder)
        let apiV3 = UicRailTicketCoder.decode(asnV3)

        // All three should have the same document count
        XCTAssertEqual(apiV1.documents.count, apiV2.documents.count)
        XCTAssertEqual(apiV2.documents.count, apiV3.documents.count)

        // All three should have the same issuing detail structure
        XCTAssertNotNil(apiV1.issuingDetail)
        XCTAssertNotNil(apiV2.issuingDetail)
        XCTAssertNotNil(apiV3.issuingDetail)

        // Issuer name should be the same across all versions
        XCTAssertEqual(apiV1.issuingDetail?.issuerName, "name")
        XCTAssertEqual(apiV2.issuingDetail?.issuerName, "name")
        XCTAssertEqual(apiV3.issuingDetail?.issuerName, "name")

        // Reservation fields should be consistent
        guard case .reservation(let r1) = apiV1.documents[0],
              case .reservation(let r2) = apiV2.documents[0],
              case .reservation(let r3) = apiV3.documents[0] else {
            XCTFail("First document should be reservation in all versions"); return
        }

        // Fields that should be identical across all versions (same test data values)
        XCTAssertEqual(r1.classCode, r2.classCode)
        XCTAssertEqual(r2.classCode, r3.classCode)
        XCTAssertEqual(r1.infoText, r2.infoText)
        XCTAssertEqual(r2.infoText, r3.infoText)
        XCTAssertEqual(r1.price, r2.price)
        XCTAssertEqual(r2.price, r3.price)
        XCTAssertEqual(r1.service, r2.service)
        XCTAssertEqual(r2.service, r3.service)
    }

    // MARK: - DecodedBarcode Integration

    func testDecodedBarcodeRailTicketProperty() throws {
        // Decode a full V3 barcode via FCBVersionDecoder
        let data = TestTicketsV3.allElementsData
        var decoder = UPERDecoder(data: data)
        let ticket = try UicRailTicketData(from: &decoder)

        // Create a mock DecodedBarcode
        let barcode = DecodedBarcode(
            frameType: .dynamicFrame(version: .v2),
            ticket: ticket,
            signatureData: SignatureData(),
            fcbVersion: 3,
            rawFrame: DynamicFrame()
        )

        // Verify the railTicket convenience property
        let railTicket = try XCTUnwrap(barcode.railTicket)
        XCTAssertNotNil(railTicket.issuingDetail)
        XCTAssertEqual(railTicket.issuingDetail?.issuerName, "name")
        XCTAssertEqual(railTicket.documents.count, 12)
        XCTAssertNotNil(railTicket.travelerDetail)
        XCTAssertNotNil(railTicket.controlDetail)
    }

    func testDecodedBarcodeRailTicketNilForSSB() {
        // SSB frame has no FCB ticket
        let barcode = DecodedBarcode(
            frameType: .ssbFrame,
            ticket: nil,
            signatureData: SignatureData(),
            fcbVersion: nil,
            rawFrame: SSBFrame()
        )

        XCTAssertNil(barcode.railTicket)
    }

    // MARK: - Specific Document Type Tests

    func testV3OpenTicketAPI() throws {
        let data = TestTicketsV3.allElementsData
        var decoder = UPERDecoder(data: data)
        let asn = try UicRailTicketData(from: &decoder)
        let api = UicRailTicketCoder.decode(asn)

        guard case .openTicket(let o) = api.documents[2] else {
            XCTFail("doc 2 should be openTicket"); return
        }

        XCTAssertNotNil(o.reference)
        XCTAssertNotNil(o.productOwner)
        XCTAssertNotNil(o.stationCodeTable)
        XCTAssertNotNil(o.fromStation)
        XCTAssertNotNil(o.toStation)
        XCTAssertNotNil(o.classCode)
        XCTAssertNotNil(o.infoText)
    }

    func testV3PassAPI() throws {
        let data = TestTicketsV3.allElementsData
        var decoder = UPERDecoder(data: data)
        let asn = try UicRailTicketData(from: &decoder)
        let api = UicRailTicketCoder.decode(asn)

        guard case .pass(let p) = api.documents[3] else {
            XCTFail("doc 3 should be pass"); return
        }

        XCTAssertNotNil(p.reference)
        XCTAssertNotNil(p.productOwner)
        XCTAssertNotNil(p.classCode)
        XCTAssertNotNil(p.passDescription)
        XCTAssertNotNil(p.infoText)
    }

    func testV3StationPassageAPI() throws {
        let data = TestTicketsV3.allElementsData
        var decoder = UPERDecoder(data: data)
        let asn = try UicRailTicketData(from: &decoder)
        let api = UicRailTicketCoder.decode(asn)

        guard case .stationPassage(let sp) = api.documents[9] else {
            XCTFail("doc 9 should be stationPassage"); return
        }

        XCTAssertNotNil(sp.productOwner)
        XCTAssertEqual(sp.stationCodeTable, .stationUIC)
        XCTAssertGreaterThan(sp.stationNameUTF8.count, 0)
    }

    func testV3VoucherAPI() throws {
        let data = TestTicketsV3.allElementsData
        var decoder = UPERDecoder(data: data)
        let asn = try UicRailTicketData(from: &decoder)
        let api = UicRailTicketCoder.decode(asn)

        guard case .voucher(let v) = api.documents[4] else {
            XCTFail("doc 4 should be voucher"); return
        }

        XCTAssertNotNil(v.productOwner)
        XCTAssertNotNil(v.infoText)
    }

    func testV3CustomerCardAPI() throws {
        let data = TestTicketsV3.allElementsData
        var decoder = UPERDecoder(data: data)
        let asn = try UicRailTicketData(from: &decoder)
        let api = UicRailTicketCoder.decode(asn)

        guard case .customerCard(let c) = api.documents[5] else {
            XCTFail("doc 5 should be customerCard"); return
        }

        XCTAssertNotNil(c.reference)
        XCTAssertNotNil(c.cardTypeDescr)
    }
}
