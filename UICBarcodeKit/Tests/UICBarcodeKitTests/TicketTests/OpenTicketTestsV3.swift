import XCTest
@testable import UICBarcodeKit

/// OpenTicket Complex V3 Tests
/// Translated from Java: OpenTicketComplexTestV3.java
/// Tests UPER decoding of OpenTicketData with all assertions from Java test
final class OpenTicketTestsV3: XCTestCase {

    // MARK: - Complete Decode Test

    /// Test decoding OpenTicket Complex V3 ticket
    /// Matches Java test: OpenTicketComplexTestV3.java
    func testOpenTicketComplexDecoding() throws {
        // Hex from Java: OpenTestComplexTicketV3.getEncodingHex()
        let data = TestTicketsV3.openTicketComplexData

        // Decode UicRailTicketData
        var decoder = UPERDecoder(data: data)
        let ticket = try UicRailTicketData(from: &decoder)

        // Assert IssuingData
        XCTAssertEqual(ticket.issuingDetail.issuingYear, OpenTicketV3Expected.issuingYear)
        XCTAssertEqual(ticket.issuingDetail.issuingDay, OpenTicketV3Expected.issuingDay)
        XCTAssertEqual(ticket.issuingDetail.specimen, OpenTicketV3Expected.specimen)
        XCTAssertEqual(ticket.issuingDetail.securePaperTicket, OpenTicketV3Expected.securePaperTicket)
        XCTAssertEqual(ticket.issuingDetail.activated, OpenTicketV3Expected.activated)
        XCTAssertEqual(ticket.issuingDetail.issuerPNR, OpenTicketV3Expected.issuerPNR)
        XCTAssertEqual(ticket.issuingDetail.issuedOnLine, OpenTicketV3Expected.issuedOnLine)

        // Assert TravelerData
        XCTAssertNotNil(ticket.travelerDetail)
        XCTAssertEqual(ticket.travelerDetail?.groupName, OpenTicketV3Expected.groupName)
        XCTAssertEqual(ticket.travelerDetail?.traveler?.count, 1)

        if let traveler = ticket.travelerDetail?.traveler?.first {
            XCTAssertEqual(traveler.firstName, OpenTicketV3Expected.firstName)
            XCTAssertEqual(traveler.secondName, OpenTicketV3Expected.secondName)
            XCTAssertEqual(traveler.idCard, OpenTicketV3Expected.idCard)
            XCTAssertEqual(traveler.ticketHolder, OpenTicketV3Expected.ticketHolder)
            XCTAssertEqual(traveler.status?.first?.customerStatusDescr, OpenTicketV3Expected.customerStatusDescr)
        }

        // Assert TransportDocument count
        XCTAssertEqual(ticket.transportDocument?.count, 2)

        // Assert first document: OpenTicket with Token
        if let doc1 = ticket.transportDocument?.first {
            // Token
            XCTAssertEqual(doc1.token?.tokenProviderIA5, OpenTicketV3Expected.tokenProviderIA5)
            XCTAssertEqual(doc1.token?.token, OpenTicketV3Expected.tokenData)

            // OpenTicket
            if case .openTicket(let ot) = doc1.ticket.ticketType {
                XCTAssertEqual(ot.returnIncluded, OpenTicketV3Expected.returnIncluded)
                XCTAssertEqual(ot.classCode?.rawValue, OpenTicketV3Expected.classCode)
                XCTAssertEqual(ot.infoText, OpenTicketV3Expected.openTicketInfoText)

                // VatDetails
                XCTAssertEqual(ot.vatDetails?.count, 1)
                if let vat = ot.vatDetails?.first {
                    XCTAssertEqual(vat.country, OpenTicketV3Expected.vatCountry)
                    XCTAssertEqual(vat.percentage, OpenTicketV3Expected.vatPercentage)
                    XCTAssertEqual(vat.amount, OpenTicketV3Expected.vatAmount)
                    XCTAssertEqual(vat.vatId, OpenTicketV3Expected.vatId)
                }

                // IncludedAddOns
                XCTAssertEqual(ot.includedAddOns?.count, 1)
                if let addOn = ot.includedAddOns?.first {
                    XCTAssertEqual(addOn.productOwnerNum, OpenTicketV3Expected.includedProductOwner)
                    XCTAssertEqual(addOn.classCode?.rawValue, OpenTicketV3Expected.includedClassCode)
                    XCTAssertEqual(addOn.infoText, OpenTicketV3Expected.includedInfoText)
                    XCTAssertEqual(addOn.validFromDay, OpenTicketV3Expected.includedValidFromDay)
                    XCTAssertEqual(addOn.validFromTime, OpenTicketV3Expected.includedValidFromTime)
                    XCTAssertEqual(addOn.validUntilDay, OpenTicketV3Expected.includedValidUntilDay)
                    XCTAssertEqual(addOn.validUntilTime, OpenTicketV3Expected.includedValidUntilTime)

                    // Tariff in IncludedAddOn
                    XCTAssertEqual(addOn.tariffs?.count, 1)
                    if let tariff = addOn.tariffs?.first {
                        XCTAssertEqual(tariff.numberOfPassengers, OpenTicketV3Expected.tariffPassengers)
                        XCTAssertEqual(tariff.passengerType?.rawValue, OpenTicketV3Expected.tariffPassengerType)
                        XCTAssertEqual(tariff.restrictedToCountryOfResidence, false)
                        XCTAssertEqual(tariff.restrictedToRouteSection?.fromStationNum, OpenTicketV3Expected.routeFromStation)
                        XCTAssertEqual(tariff.restrictedToRouteSection?.toStationNum, OpenTicketV3Expected.routeToStation)
                    }

                    // ValidRegion (zones)
                    XCTAssertEqual(addOn.validRegion?.count, 1)
                    if let region = addOn.validRegion?.first {
                        if case .zone(let zone) = region.validity {
                            XCTAssertEqual(zone.zoneId?.first, OpenTicketV3Expected.zoneId)
                        } else {
                            XCTFail("Expected zone validity type")
                        }
                    }
                }
            } else {
                XCTFail("Expected openTicket in first document")
            }
        }

        // Assert second document: StationPassage
        if let doc2 = ticket.transportDocument?[1] {
            if case .stationPassage(let sp) = doc2.ticket.ticketType {
                XCTAssertEqual(sp.productName, OpenTicketV3Expected.passageProductName)
                XCTAssertEqual(sp.stationNameUTF8?.first, OpenTicketV3Expected.passageStation)
                XCTAssertEqual(sp.validFromDay, OpenTicketV3Expected.passageValidFromDay)
                XCTAssertEqual(sp.numberOfDaysValid, OpenTicketV3Expected.passageNumberOfDaysValid)
            } else {
                XCTFail("Expected stationPassage in second document")
            }
        }

        // Assert ControlData
        XCTAssertNotNil(ticket.controlDetail)
        XCTAssertEqual(ticket.controlDetail?.infoText, OpenTicketV3Expected.controlInfoText)
        XCTAssertEqual(ticket.controlDetail?.identificationByCardReference?.first?.trailingCardIdNum, OpenTicketV3Expected.trailingCardIdNum)
        XCTAssertEqual(ticket.controlDetail?.ageCheckRequired, false)
        XCTAssertEqual(ticket.controlDetail?.identificationByIdCard, false)
        XCTAssertEqual(ticket.controlDetail?.identificationByPassportId, false)
        XCTAssertEqual(ticket.controlDetail?.passportValidationRequired, false)
        XCTAssertEqual(ticket.controlDetail?.onlineValidationRequired, false)
        XCTAssertEqual(ticket.controlDetail?.reductionCardCheckRequired, false)

        // Assert TicketLink in ControlData
        if let ticketLink = ticket.controlDetail?.includedTickets?.first {
            XCTAssertEqual(ticketLink.referenceIA5, OpenTicketV3Expected.ticketLinkReferenceIA5)
            XCTAssertEqual(ticketLink.issuerName, OpenTicketV3Expected.ticketLinkIssuerName)
            XCTAssertEqual(ticketLink.issuerPNR, OpenTicketV3Expected.ticketLinkIssuerPNR)
            XCTAssertEqual(ticketLink.productOwnerIA5, OpenTicketV3Expected.ticketLinkProductOwnerIA5)
            XCTAssertEqual(ticketLink.ticketType, .pass)
            XCTAssertEqual(ticketLink.linkMode, .onlyValidInCombination)
        }

        // Assert ExtensionData
        XCTAssertEqual(ticket.extensionData?.count, 2)
        if let ext1 = ticket.extensionData?.first {
            XCTAssertEqual(ext1.extensionId, OpenTicketV3Expected.extension1Id)
            XCTAssertEqual(ext1.extensionData, OpenTicketV3Expected.extension1Data)
        }
        if let ext2 = ticket.extensionData?[1] {
            XCTAssertEqual(ext2.extensionId, OpenTicketV3Expected.extension2Id)
            XCTAssertEqual(ext2.extensionData, OpenTicketV3Expected.extension2Data)
        }
    }

    // MARK: - Individual Component Tests

    /// Test IssuingData decoding
    func testIssuingDataDecoding() throws {
        let data = TestTicketsV3.openTicketComplexData
        var decoder = UPERDecoder(data: data)
        let ticket = try UicRailTicketData(from: &decoder)

        XCTAssertEqual(ticket.issuingDetail.issuingYear, 2018)
        XCTAssertEqual(ticket.issuingDetail.issuingDay, 1)
        XCTAssertEqual(ticket.issuingDetail.specimen, true)
        XCTAssertEqual(ticket.issuingDetail.activated, true)
    }

    /// Test TravelerData decoding
    func testTravelerDataDecoding() throws {
        let data = TestTicketsV3.openTicketComplexData
        var decoder = UPERDecoder(data: data)
        let ticket = try UicRailTicketData(from: &decoder)

        XCTAssertNotNil(ticket.travelerDetail)
        XCTAssertEqual(ticket.travelerDetail?.traveler?.count, 1)
        XCTAssertEqual(ticket.travelerDetail?.traveler?.first?.firstName, "John")
    }

    /// Test OpenTicketData structure
    func testOpenTicketDataStructure() throws {
        let data = TestTicketsV3.openTicketComplexData
        var decoder = UPERDecoder(data: data)
        let ticket = try UicRailTicketData(from: &decoder)

        XCTAssertEqual(ticket.transportDocument?.count, 2)

        if let doc1 = ticket.transportDocument?.first {
            if case .openTicket(let ot) = doc1.ticket.ticketType {
                XCTAssertEqual(ot.returnIncluded, false)
                XCTAssertEqual(ot.classCode, .first)
                XCTAssertEqual(ot.infoText, "openTicketInfo")
            } else {
                XCTFail("Expected openTicket")
            }
        }
    }

    /// Test VatDetailType decoding
    func testVatDetailDecoding() throws {
        let data = TestTicketsV3.openTicketComplexData
        var decoder = UPERDecoder(data: data)
        let ticket = try UicRailTicketData(from: &decoder)

        if let doc1 = ticket.transportDocument?.first,
           case .openTicket(let ot) = doc1.ticket.ticketType,
           let vat = ot.vatDetails?.first {
            XCTAssertEqual(vat.country, 80)
            XCTAssertEqual(vat.percentage, 70)
            XCTAssertEqual(vat.amount, 10)
            XCTAssertEqual(vat.vatId, "IUDGTE")
        } else {
            XCTFail("Could not extract VAT details")
        }
    }

    /// Test IncludedAddOn decoding
    func testIncludedAddOnDecoding() throws {
        let data = TestTicketsV3.openTicketComplexData
        var decoder = UPERDecoder(data: data)
        let ticket = try UicRailTicketData(from: &decoder)

        if let doc1 = ticket.transportDocument?.first,
           case .openTicket(let ot) = doc1.ticket.ticketType,
           let addOn = ot.includedAddOns?.first {
            XCTAssertEqual(addOn.productOwnerNum, 1080)
            XCTAssertEqual(addOn.classCode, .second)
            XCTAssertEqual(addOn.infoText, "included ticket")
            XCTAssertEqual(addOn.validFromDay, 0)
            XCTAssertEqual(addOn.validFromTime, 1000)
        } else {
            XCTFail("Could not extract IncludedAddOn")
        }
    }

    /// Test StationPassageData decoding
    func testStationPassageDecoding() throws {
        let data = TestTicketsV3.openTicketComplexData
        var decoder = UPERDecoder(data: data)
        let ticket = try UicRailTicketData(from: &decoder)

        if let doc2 = ticket.transportDocument?[1],
           case .stationPassage(let sp) = doc2.ticket.ticketType {
            XCTAssertEqual(sp.productName, "passage")
            XCTAssertEqual(sp.stationNameUTF8?.first, "Amsterdam")
            XCTAssertEqual(sp.validFromDay, 0)
            XCTAssertEqual(sp.numberOfDaysValid, 123)
        } else {
            XCTFail("Could not extract StationPassage")
        }
    }

    /// Test ControlData decoding
    func testControlDataDecoding() throws {
        let data = TestTicketsV3.openTicketComplexData
        var decoder = UPERDecoder(data: data)
        let ticket = try UicRailTicketData(from: &decoder)

        XCTAssertNotNil(ticket.controlDetail)
        XCTAssertEqual(ticket.controlDetail?.infoText, "cd")
        XCTAssertEqual(ticket.controlDetail?.ageCheckRequired, false)
        XCTAssertEqual(ticket.controlDetail?.identificationByCardReference?.first?.trailingCardIdNum, 100)
    }

    /// Test ExtensionData decoding
    func testExtensionDataDecoding() throws {
        let data = TestTicketsV3.openTicketComplexData
        var decoder = UPERDecoder(data: data)
        let ticket = try UicRailTicketData(from: &decoder)

        XCTAssertEqual(ticket.extensionData?.count, 2)
        XCTAssertEqual(ticket.extensionData?.first?.extensionId, "1")
        XCTAssertEqual(ticket.extensionData?.first?.extensionData, Data([0x82, 0xDA]))
        XCTAssertEqual(ticket.extensionData?[1].extensionId, "2")
        XCTAssertEqual(ticket.extensionData?[1].extensionData, Data([0x83, 0xDA]))
    }

    /// Test TokenType decoding
    func testTokenTypeDecoding() throws {
        let data = TestTicketsV3.openTicketComplexData
        var decoder = UPERDecoder(data: data)
        let ticket = try UicRailTicketData(from: &decoder)

        if let doc1 = ticket.transportDocument?.first {
            XCTAssertEqual(doc1.token?.tokenProviderIA5, "VDV")
            XCTAssertEqual(doc1.token?.token, Data([0x82, 0xDA]))
        } else {
            XCTFail("Could not extract Token")
        }
    }
}
