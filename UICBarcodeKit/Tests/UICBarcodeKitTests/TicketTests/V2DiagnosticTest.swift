import XCTest
@testable import UICBarcodeKit

/// Diagnostic test to debug V2 UPER decoding
final class V2DiagnosticTest: XCTestCase {

    func testFullStructDecode() throws {
        let data = TestTicketsV2.allElementsData
        let ticket = try FCBVersionDecoder.decode(data: data, version: 2)
        print("Decoded OK!")
        print("issuingYear = \(ticket.issuingDetail.issuingYear)")
    }

    func testDocumentByDocument() throws {
        let data = TestTicketsV2.allElementsData
        var decoder = UPERDecoder(data: data)

        // Root struct
        let rootExt = try decoder.decodeBit()
        let rootPresence = try decoder.decodePresenceBitmap(count: 4)
        print("Root: ext=\(rootExt), presence=\(rootPresence)")

        // IssuingData
        let _ = try IssuingDataV2(from: &decoder)
        print("IssuingData OK, pos=\(decoder.position)")

        // TravelerData
        if rootPresence[0] {
            let _ = try TravelerDataV2(from: &decoder)
            print("TravelerData OK, pos=\(decoder.position)")
        }

        // TransportDocument - decode count then each one individually
        if rootPresence[1] {
            let docCount = try decoder.decodeLengthDeterminant()
            print("TransportDocument count=\(docCount), pos=\(decoder.position)")

            let docNames = ["reservation", "carCarriage", "openTicket", "pass",
                           "voucher", "customerCard", "countermark", "parking",
                           "fipTicket", "stationPassage", "extension", "delayConfirm"]

            for i in 0..<docCount {
                let posBefore = decoder.position
                do {
                    let doc = try DocumentDataV2(from: &decoder)
                    print("  doc[\(i)] (\(i < docNames.count ? docNames[i] : "?")): OK, pos=\(decoder.position)")
                    _ = doc
                } catch {
                    print("  doc[\(i)] (\(i < docNames.count ? docNames[i] : "?")): FAILED at pos=\(posBefore), error=\(error)")
                    throw error
                }
            }
        }
    }

    func testReservationFieldByField() throws {
        let data = TestTicketsV2.allElementsData
        var decoder = UPERDecoder(data: data)

        // Skip to where reservation starts
        let _ = try decoder.decodeBit() // root ext
        let rootPresence = try decoder.decodePresenceBitmap(count: 4)
        let issuingData = try IssuingDataV2(from: &decoder)
        print("V2 IssuingData OK, pos=\(decoder.position), issuingTime=\(issuingData.issuingTime as Any)")
        if rootPresence[0] {
            let _ = try TravelerDataV2(from: &decoder)
            print("V2 TravelerData OK, pos=\(decoder.position)")
        }
        let _ = try decoder.decodeLengthDeterminant() // doc count
        print("V2 docCount pos=\(decoder.position)")

        // DocumentData header
        let _ = try decoder.decodeBit() // doc ext
        let _ = try decoder.decodePresenceBitmap(count: 1) // token presence
        // Token not present (no token decoded)

        // TicketDetailData CHOICE
        let _ = try decoder.decodeChoiceIndex(rootCount: 12, hasExtensionMarker: true)
        print("V2 reservation start pos=\(decoder.position)")

        // ReservationDataV2 - decode field by field
        let hasExtensions = try decoder.decodeBit()
        let presence = try decoder.decodePresenceBitmap(count: 43)
        print("  V2 Reservation presence bitmap: \(presence.map { $0 ? "1" : "0" }.joined())")
        print("  V2 Reservation hasExtensions=\(hasExtensions)")
        var idx = 0

        let fieldNames = [
            "trainNum", "trainIA5", "departureDate", "referenceIA5", "referenceNum",
            "productOwnerNum", "productOwnerIA5", "productIdNum", "productIdIA5",
            "serviceBrand", "serviceBrandAbrUTF8", "serviceBrandNameUTF8",
            "service", "stationCodeTable", "fromStationNum", "fromStationIA5",
            "toStationNum", "toStationIA5", "fromStationNameUTF8", "toStationNameUTF8",
            "departureTime(MANDATORY)", "departureUTCOffset", "arrivalDate", "arrivalTime", "arrivalUTCOffset",
            "carrierNum", "carrierIA5", "classCode", "serviceLevel",
            "places", "additionalPlaces", "bicyclePlaces", "compartmentDetails",
            "numberOfOverbooked", "berth", "tariff", "priceType",
            "price", "vatDetail", "typeOfSupplement", "numberOfSupplements",
            "luggage", "infoText", "extensionData"
        ]

        // Decode each field with error reporting
        func tryField(_ name: String, _ block: () throws -> Void) throws {
            let posBefore = decoder.position
            do {
                try block()
                print("  \(name): OK, pos=\(decoder.position)")
            } catch {
                print("  \(name): FAILED at pos=\(posBefore), error=\(error)")
                throw error
            }
        }

        try tryField("trainNum") { if presence[idx] { let _ = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1 }
        try tryField("trainIA5") { if presence[idx] { let _ = try decoder.decodeIA5String() }; idx += 1 }
        try tryField("departureDate") { if presence[idx] { let _ = try decoder.decodeConstrainedInt(min: -1, max: 370) }; idx += 1 }
        try tryField("referenceIA5") { if presence[idx] { let _ = try decoder.decodeIA5String() }; idx += 1 }
        try tryField("referenceNum") { if presence[idx] { let _ = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1 }
        try tryField("productOwnerNum") { if presence[idx] { let _ = try decoder.decodeConstrainedInt(min: 1, max: 32000) }; idx += 1 }
        try tryField("productOwnerIA5") { if presence[idx] { let _ = try decoder.decodeIA5String() }; idx += 1 }
        try tryField("productIdNum") { if presence[idx] { let _ = try decoder.decodeConstrainedInt(min: 0, max: 65535) }; idx += 1 }
        try tryField("productIdIA5") { if presence[idx] { let _ = try decoder.decodeIA5String() }; idx += 1 }
        try tryField("serviceBrand") { if presence[idx] { let _ = try decoder.decodeConstrainedInt(min: 0, max: 32000) }; idx += 1 }
        try tryField("serviceBrandAbrUTF8") { if presence[idx] { let _ = try decoder.decodeUTF8String() }; idx += 1 }
        try tryField("serviceBrandNameUTF8") { if presence[idx] { let _ = try decoder.decodeUTF8String() }; idx += 1 }
        try tryField("service") { if presence[idx] { let _ = try ServiceTypeV2(from: &decoder) }; idx += 1 }
        try tryField("stationCodeTable") { if presence[idx] { let _ = try CodeTableTypeV2(from: &decoder) }; idx += 1 }
        try tryField("fromStationNum") { if presence[idx] { let _ = try decoder.decodeConstrainedInt(min: 1, max: 9999999) }; idx += 1 }
        try tryField("fromStationIA5") { if presence[idx] { let _ = try decoder.decodeIA5String() }; idx += 1 }
        try tryField("toStationNum") { if presence[idx] { let _ = try decoder.decodeConstrainedInt(min: 1, max: 9999999) }; idx += 1 }
        try tryField("toStationIA5") { if presence[idx] { let _ = try decoder.decodeIA5String() }; idx += 1 }
        try tryField("fromStationNameUTF8") { if presence[idx] { let _ = try decoder.decodeUTF8String() }; idx += 1 }
        try tryField("toStationNameUTF8") { if presence[idx] { let _ = try decoder.decodeUTF8String() }; idx += 1 }
        try tryField("departureTime") { let _ = try decoder.decodeConstrainedInt(min: 0, max: 1439) }
        try tryField("departureUTCOffset") { if presence[idx] { let _ = try decoder.decodeConstrainedInt(min: -60, max: 60) }; idx += 1 }
        try tryField("arrivalDate") { if presence[idx] { let _ = try decoder.decodeConstrainedInt(min: -1, max: 20) }; idx += 1 }
        try tryField("arrivalTime") { if presence[idx] { let _ = try decoder.decodeConstrainedInt(min: 0, max: 1439) }; idx += 1 }
        try tryField("arrivalUTCOffset") { if presence[idx] { let _ = try decoder.decodeConstrainedInt(min: -60, max: 60) }; idx += 1 }
        try tryField("carrierNum") {
            if presence[idx] {
                let count = try decoder.decodeLengthDeterminant()
                for _ in 0..<count { let _ = try decoder.decodeConstrainedInt(min: 1, max: 32000) }
            }; idx += 1
        }
        try tryField("carrierIA5") {
            if presence[idx] {
                let count = try decoder.decodeLengthDeterminant()
                for _ in 0..<count { let _ = try decoder.decodeIA5String() }
            }; idx += 1
        }
        try tryField("classCode") { if presence[idx] { let _ = try TravelClassTypeV2(from: &decoder) }; idx += 1 }
        try tryField("serviceLevel") {
            if presence[idx] {
                let _ = try decoder.decodeIA5String(constraint: ASN1StringConstraint(type: .ia5String, minLength: 1, maxLength: 2))
            }; idx += 1
        }
        try tryField("places") { if presence[idx] { let _ = try PlacesTypeV2(from: &decoder) }; idx += 1 }
        try tryField("additionalPlaces") { if presence[idx] { let _ = try PlacesTypeV2(from: &decoder) }; idx += 1 }
        try tryField("bicyclePlaces") { if presence[idx] { let _ = try PlacesTypeV2(from: &decoder) }; idx += 1 }
        try tryField("compartmentDetails") { if presence[idx] { let _ = try CompartmentDetailsTypeV2(from: &decoder) }; idx += 1 }
        try tryField("numberOfOverbooked") { if presence[idx] { let _ = try decoder.decodeConstrainedInt(min: 0, max: 200) }; idx += 1 }
        try tryField("berth") {
            if presence[idx] {
                let berthCount = try decoder.decodeLengthDeterminant()
                print("    berth count=\(berthCount), pos after count=\(decoder.position)")
                for bi in 0..<berthCount {
                    let berthPos = decoder.position
                    let berth = try BerthDetailDataV2(from: &decoder)
                    print("    berth[\(bi)]: type=\(berth.berthType), num=\(berth.numberOfBerths), gender=\(berth.gender as Any), pos=\(decoder.position) (consumed \(decoder.position - berthPos) bits)")
                }
            }; idx += 1
        }
        try tryField("tariff") { if presence[idx] { let _: [TariffTypeV2] = try decoder.decodeSequenceOf() }; idx += 1 }
        try tryField("priceType") { if presence[idx] { let _ = try PriceTypeTypeV2(from: &decoder) }; idx += 1 }
        try tryField("price") { if presence[idx] { let _ = Int(try decoder.decodeUnconstrainedInteger()) }; idx += 1 }
        try tryField("vatDetail") { if presence[idx] { let _: [VatDetailTypeV2] = try decoder.decodeSequenceOf() }; idx += 1 }
        try tryField("typeOfSupplement") { if presence[idx] { let _ = try decoder.decodeConstrainedInt(min: 0, max: 9) }; idx += 1 }
        try tryField("numberOfSupplements") { if presence[idx] { let _ = try decoder.decodeConstrainedInt(min: 0, max: 200) }; idx += 1 }
        try tryField("luggage") { if presence[idx] { let _ = try LuggageRestrictionTypeV2(from: &decoder) }; idx += 1 }
        try tryField("infoText") { if presence[idx] { let _ = try decoder.decodeUTF8String() }; idx += 1 }
        try tryField("extensionData") { if presence[idx] { let _ = try ExtensionDataV2(from: &decoder) } }

        if hasExtensions {
            let numExt = try decoder.decodeBitmaskLength()
            let extPresence = try decoder.decodePresenceBitmap(count: numExt)
            for i in 0..<numExt where extPresence[i] {
                try decoder.skipOpenType()
            }
        }

        print("Reservation complete, pos=\(decoder.position)")
    }
}
