import XCTest
@testable import UICBarcodeKit

/// Pass Complex V3 Tests
/// Translated from Java: PassComplexTestV3.java
/// Tests UPER decoding of PassData with all assertions from Java test
final class PassTestsV3: XCTestCase {

    // MARK: - Complete Decode Test

    /// Test decoding Pass Complex V3 ticket
    /// Matches Java test: PassComplexTestV3.java
    func testPassComplexDecoding() throws {
        // Hex from Java: PassComplexTicketV3.getEncodingHex()
        let data = TestTicketsV3.passComplexData

        // Decode UicRailTicketData
        var decoder = UPERDecoder(data: data)
        let ticket = try UicRailTicketData(from: &decoder)

        // Assert IssuingData
        XCTAssertEqual(ticket.issuingDetail.issuingYear, PassV3Expected.issuingYear)
        XCTAssertEqual(ticket.issuingDetail.issuingDay, PassV3Expected.issuingDay)
        XCTAssertEqual(ticket.issuingDetail.specimen, PassV3Expected.specimen)
        XCTAssertEqual(ticket.issuingDetail.activated, PassV3Expected.activated)
        XCTAssertEqual(ticket.issuingDetail.issuerPNR, PassV3Expected.issuerPNR)
        XCTAssertEqual(ticket.issuingDetail.issuedOnLine, PassV3Expected.issuedOnLine)

        // Assert TravelerData (same as OpenTicket)
        XCTAssertNotNil(ticket.travelerDetail)
        XCTAssertEqual(ticket.travelerDetail?.groupName, "myGroup")
        XCTAssertEqual(ticket.travelerDetail?.traveler?.count, 1)

        if let traveler = ticket.travelerDetail?.traveler?.first {
            XCTAssertEqual(traveler.firstName, "John")
            XCTAssertEqual(traveler.secondName, "Dow")
            XCTAssertEqual(traveler.idCard, "12345")
            XCTAssertEqual(traveler.ticketHolder, true)
        }

        // Assert TransportDocument count
        XCTAssertEqual(ticket.transportDocument?.count, 2)

        // Assert first document: Pass with Token
        if let doc1 = ticket.transportDocument?.first {
            // Token
            XCTAssertEqual(doc1.token?.tokenProviderIA5, PassV3Expected.tokenProviderIA5)
            XCTAssertEqual(doc1.token?.token, PassV3Expected.tokenData)

            // PassData
            if case .pass(let pass) = doc1.ticket.ticketType {
                XCTAssertEqual(pass.referenceNum, PassV3Expected.referenceNum)
                XCTAssertEqual(pass.productOwnerNum, PassV3Expected.productOwnerNum)
                XCTAssertEqual(pass.passDescription, PassV3Expected.passDescription)
                XCTAssertEqual(pass.classCode?.rawValue, PassV3Expected.classCode)
                XCTAssertEqual(pass.validFromDay, PassV3Expected.validFromDay)
                XCTAssertEqual(pass.validFromTime, PassV3Expected.validFromTime)
                XCTAssertEqual(pass.validUntilDay, PassV3Expected.validUntilDay)
                XCTAssertEqual(pass.validUntilTime, PassV3Expected.validUntilTime)
                XCTAssertEqual(pass.numberOfDaysOfTravel, PassV3Expected.numberOfDaysOfTravel)
                XCTAssertEqual(pass.price, PassV3Expected.price)
                XCTAssertEqual(pass.infoText, PassV3Expected.infoText)

                // TrainValidity
                XCTAssertNotNil(pass.trainValidity)
                if let tv = pass.trainValidity {
                    XCTAssertEqual(tv.validFromDay, PassV3Expected.trainValidityFromDay)
                    XCTAssertEqual(tv.validFromTime, PassV3Expected.trainValidityFromTime)
                    XCTAssertEqual(tv.validUntilDay, PassV3Expected.trainValidityUntilDay)
                    XCTAssertEqual(tv.validUntilTime, PassV3Expected.trainValidityUntilTime)
                    XCTAssertEqual(tv.includedCarriersNum, PassV3Expected.includedCarriers)
                    XCTAssertEqual(tv.bordingOrArrival?.rawValue, PassV3Expected.boardingOrArrival)
                }

                // ActivatedDays
                XCTAssertEqual(pass.activatedDay, PassV3Expected.activatedDays)

                // Countries
                XCTAssertEqual(pass.countries, PassV3Expected.countries)

                // VatDetails
                XCTAssertEqual(pass.vatDetails?.count, 1)
                if let vat = pass.vatDetails?.first {
                    XCTAssertEqual(vat.country, PassV3Expected.vatCountry)
                    XCTAssertEqual(vat.percentage, PassV3Expected.vatPercentage)
                    XCTAssertEqual(vat.amount, PassV3Expected.vatAmount)
                    XCTAssertEqual(vat.vatId, PassV3Expected.vatId)
                }
            } else {
                XCTFail("Expected pass in first document")
            }
        }

        // Assert second document: StationPassage
        if let doc2 = ticket.transportDocument?[1] {
            if case .stationPassage(let sp) = doc2.ticket.ticketType {
                XCTAssertEqual(sp.productName, "passage")
                XCTAssertEqual(sp.stationNameUTF8?.first, "Amsterdam")
                XCTAssertEqual(sp.validFromDay, 0)
                XCTAssertEqual(sp.numberOfDaysValid, 123)
            } else {
                XCTFail("Expected stationPassage in second document")
            }
        }

        // Assert ControlData
        XCTAssertNotNil(ticket.controlDetail)
        XCTAssertEqual(ticket.controlDetail?.infoText, "cd")

        // Assert ExtensionData
        XCTAssertEqual(ticket.extensionData?.count, 2)
    }

    // MARK: - Individual Component Tests

    /// Test PassData structure decoding
    func testPassDataStructure() throws {
        let data = TestTicketsV3.passComplexData
        var decoder = UPERDecoder(data: data)
        let ticket = try UicRailTicketData(from: &decoder)

        if let doc1 = ticket.transportDocument?.first {
            if case .pass(let pass) = doc1.ticket.ticketType {
                XCTAssertEqual(pass.referenceNum, 123456789)
                XCTAssertEqual(pass.productOwnerNum, 4567)
                XCTAssertEqual(pass.passDescription, "Eurail FlexPass")
                XCTAssertEqual(pass.classCode, .first)
            } else {
                XCTFail("Expected pass ticket type")
            }
        }
    }

    /// Test TrainValidityType decoding
    func testTrainValidityDecoding() throws {
        let data = TestTicketsV3.passComplexData
        var decoder = UPERDecoder(data: data)
        let ticket = try UicRailTicketData(from: &decoder)

        if let doc1 = ticket.transportDocument?.first,
           case .pass(let pass) = doc1.ticket.ticketType,
           let tv = pass.trainValidity {
            XCTAssertEqual(tv.validFromDay, 0)
            XCTAssertEqual(tv.validFromTime, 1000)
            XCTAssertEqual(tv.validUntilDay, 1)
            XCTAssertEqual(tv.validUntilTime, 1000)
            XCTAssertEqual(tv.includedCarriersNum, [1234, 5678])
            XCTAssertEqual(tv.bordingOrArrival, .boarding)
        } else {
            XCTFail("Could not extract TrainValidity")
        }
    }

    /// Test ActivatedDays decoding
    func testActivatedDaysDecoding() throws {
        let data = TestTicketsV3.passComplexData
        var decoder = UPERDecoder(data: data)
        let ticket = try UicRailTicketData(from: &decoder)

        if let doc1 = ticket.transportDocument?.first,
           case .pass(let pass) = doc1.ticket.ticketType {
            XCTAssertEqual(pass.activatedDay?.count, 2)
            XCTAssertEqual(pass.activatedDay?[0], 200)
            XCTAssertEqual(pass.activatedDay?[1], 201)
        } else {
            XCTFail("Could not extract ActivatedDays")
        }
    }

    /// Test Countries decoding
    func testCountriesDecoding() throws {
        let data = TestTicketsV3.passComplexData
        var decoder = UPERDecoder(data: data)
        let ticket = try UicRailTicketData(from: &decoder)

        if let doc1 = ticket.transportDocument?.first,
           case .pass(let pass) = doc1.ticket.ticketType {
            XCTAssertEqual(pass.countries?.count, 2)
            XCTAssertEqual(pass.countries?[0], 10)
            XCTAssertEqual(pass.countries?[1], 20)
        } else {
            XCTFail("Could not extract Countries")
        }
    }

    /// Test VatDetails in PassData decoding
    func testPassVatDetailsDecoding() throws {
        let data = TestTicketsV3.passComplexData
        var decoder = UPERDecoder(data: data)
        let ticket = try UicRailTicketData(from: &decoder)

        if let doc1 = ticket.transportDocument?.first,
           case .pass(let pass) = doc1.ticket.ticketType,
           let vat = pass.vatDetails?.first {
            XCTAssertEqual(vat.country, 80)
            XCTAssertEqual(vat.percentage, 70)
            XCTAssertEqual(vat.amount, 10)
            XCTAssertEqual(vat.vatId, "IUDGTE")
        } else {
            XCTFail("Could not extract VAT details from Pass")
        }
    }

    /// Test Token decoding for Pass
    func testPassTokenDecoding() throws {
        let data = TestTicketsV3.passComplexData
        var decoder = UPERDecoder(data: data)
        let ticket = try UicRailTicketData(from: &decoder)

        if let doc1 = ticket.transportDocument?.first {
            XCTAssertEqual(doc1.token?.tokenProviderIA5, "XYZ")
            XCTAssertEqual(doc1.token?.token, Data([0x82, 0xDA]))
        } else {
            XCTFail("Could not extract Token")
        }
    }

    /// Test price decoding
    func testPriceDecoding() throws {
        let data = TestTicketsV3.passComplexData
        var decoder = UPERDecoder(data: data)
        let ticket = try UicRailTicketData(from: &decoder)

        if let doc1 = ticket.transportDocument?.first,
           case .pass(let pass) = doc1.ticket.ticketType {
            XCTAssertEqual(pass.price, 10000)
        } else {
            XCTFail("Could not extract price")
        }
    }

    /// Test infoText decoding
    func testInfoTextDecoding() throws {
        let data = TestTicketsV3.passComplexData
        var decoder = UPERDecoder(data: data)
        let ticket = try UicRailTicketData(from: &decoder)

        if let doc1 = ticket.transportDocument?.first,
           case .pass(let pass) = doc1.ticket.ticketType {
            XCTAssertEqual(pass.infoText, "pass info")
        } else {
            XCTFail("Could not extract infoText")
        }
    }
}
