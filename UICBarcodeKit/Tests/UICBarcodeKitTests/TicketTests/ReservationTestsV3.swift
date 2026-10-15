import XCTest
@testable import UICBarcodeKit

/// Reservation V3 Tests
/// Tests UPER decoding of ReservationData
final class ReservationTestsV3: XCTestCase {

    // MARK: - Structure Tests

    /// Test ReservationData structure
    func testReservationDataStructure() throws {
        var reservation = ReservationData()
        reservation.trainNum = 12345
        reservation.trainIA5 = "ICE123"
        reservation.departureDate = 2
        reservation.referenceIA5 = "RES123456"
        reservation.productOwnerNum = 1080
        reservation.serviceBrand = 12
        reservation.serviceBrandNameUTF8 = "ICE"
        reservation.fromStationNum = 8000001
        reservation.toStationNum = 8000002
        reservation.fromStationNameUTF8 = "Berlin Hbf"
        reservation.toStationNameUTF8 = "München Hbf"
        reservation.departureTime = 480  // 08:00
        reservation.arrivalTime = 720    // 12:00
        reservation.classCode = .first
        reservation.service = .seat
        reservation.price = 9900
        reservation.infoText = "Window seat"

        XCTAssertEqual(reservation.trainNum, 12345)
        XCTAssertEqual(reservation.trainIA5, "ICE123")
        XCTAssertEqual(reservation.departureDate, 2)
        XCTAssertEqual(reservation.referenceIA5, "RES123456")
        XCTAssertEqual(reservation.productOwnerNum, 1080)
        XCTAssertEqual(reservation.serviceBrand, 12)
        XCTAssertEqual(reservation.serviceBrandNameUTF8, "ICE")
        XCTAssertEqual(reservation.fromStationNum, 8000001)
        XCTAssertEqual(reservation.toStationNum, 8000002)
        XCTAssertEqual(reservation.departureTime, 480)
        XCTAssertEqual(reservation.arrivalTime, 720)
        XCTAssertEqual(reservation.classCode, .first)
        XCTAssertEqual(reservation.service, .seat)
        XCTAssertEqual(reservation.price, 9900)
        XCTAssertEqual(reservation.infoText, "Window seat")
    }

    /// Test PlacesType structure
    func testPlacesTypeStructure() throws {
        var places = PlacesType()
        places.coach = "31A"
        places.placeString = "31-47"
        places.placeDescription = "Window"
        places.placeNum = [31, 32]

        XCTAssertEqual(places.coach, "31A")
        XCTAssertEqual(places.placeString, "31-47")
        XCTAssertEqual(places.placeDescription, "Window")
        XCTAssertEqual(places.placeNum?.count, 2)
        XCTAssertEqual(places.placeNum?[0], 31)
    }

    /// Test CompartmentDetailsType structure
    func testCompartmentDetailsStructure() throws {
        var compartment = CompartmentDetailsType()
        compartment.coachType = 1
        compartment.compartmentType = 2
        compartment.specialAllocation = 3
        compartment.coachTypeDescr = "First Class"
        compartment.compartmentTypeDescr = "Quiet Zone"
        compartment.position = .upperLevel

        XCTAssertEqual(compartment.coachType, 1)
        XCTAssertEqual(compartment.compartmentType, 2)
        XCTAssertEqual(compartment.specialAllocation, 3)
        XCTAssertEqual(compartment.coachTypeDescr, "First Class")
        XCTAssertEqual(compartment.compartmentTypeDescr, "Quiet Zone")
        XCTAssertEqual(compartment.position, .upperLevel)
    }

    /// Test BerthDetailData structure
    func testBerthDetailDataStructure() throws {
        var berth = BerthDetailData()
        berth.berthType = .single
        berth.numberOfBerths = 1
        berth.gender = .female

        XCTAssertEqual(berth.berthType, .single)
        XCTAssertEqual(berth.numberOfBerths, 1)
        XCTAssertEqual(berth.gender, .female)
    }

    /// Test ServiceType enum
    func testServiceTypeEnum() {
        XCTAssertEqual(ServiceType.seat.rawValue, 0)
        XCTAssertEqual(ServiceType.couchette.rawValue, 1)
        XCTAssertEqual(ServiceType.berth.rawValue, 2)
        XCTAssertEqual(ServiceType.carCarriage.rawValue, 3)
    }

    /// Test PriceTypeType enum
    func testPriceTypeEnum() {
        XCTAssertEqual(PriceTypeType.noPrice.rawValue, 0)
        XCTAssertEqual(PriceTypeType.reservationFee.rawValue, 1)
        XCTAssertEqual(PriceTypeType.supplement.rawValue, 2)
        XCTAssertEqual(PriceTypeType.travelPrice.rawValue, 3)
    }

    /// Test BerthTypeType enum
    func testBerthTypeEnum() {
        XCTAssertEqual(BerthTypeType.single.rawValue, 0)
        XCTAssertEqual(BerthTypeType.special.rawValue, 1)
        XCTAssertEqual(BerthTypeType.double.rawValue, 2)
        XCTAssertEqual(BerthTypeType.t2.rawValue, 3)
        XCTAssertEqual(BerthTypeType.t3.rawValue, 4)
        XCTAssertEqual(BerthTypeType.t4.rawValue, 5)
    }

    /// Test CompartmentPositionType enum
    func testCompartmentPositionEnum() {
        XCTAssertEqual(CompartmentPositionType.unspecified.rawValue, 0)
        XCTAssertEqual(CompartmentPositionType.upperLevel.rawValue, 1)
        XCTAssertEqual(CompartmentPositionType.lowerLevel.rawValue, 2)
    }

    /// Test CompartmentGenderType enum (matches Java CompartmentGenderType.java)
    func testCompartmentGenderEnum() {
        XCTAssertEqual(CompartmentGenderType.unspecified.rawValue, 0)
        XCTAssertEqual(CompartmentGenderType.family.rawValue, 1)
        XCTAssertEqual(CompartmentGenderType.female.rawValue, 2)
        XCTAssertEqual(CompartmentGenderType.male.rawValue, 3)
        XCTAssertEqual(CompartmentGenderType.mixed.rawValue, 4)
    }

    /// Test carrier arrays
    func testCarrierArrays() throws {
        var reservation = ReservationData()
        reservation.carrierNum = [1080, 1181]
        reservation.carrierIA5 = ["DB", "OEBB"]

        XCTAssertEqual(reservation.carrierNum?.count, 2)
        XCTAssertEqual(reservation.carrierIA5?.count, 2)
        XCTAssertEqual(reservation.carrierNum?[0], 1080)
        XCTAssertEqual(reservation.carrierIA5?[0], "DB")
    }

    /// Test UTC offset handling
    func testUTCOffsetHandling() throws {
        var reservation = ReservationData()
        reservation.departureUTCOffset = -60  // -1 hour
        reservation.arrivalUTCOffset = 60     // +1 hour

        XCTAssertEqual(reservation.departureUTCOffset, -60)
        XCTAssertEqual(reservation.arrivalUTCOffset, 60)
    }
}
