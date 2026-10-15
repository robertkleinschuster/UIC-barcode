import Foundation

/// Version-independent parking ground
public class ParkingGroundAPI {
    public var token: TokenAPI?
    public var reference: String?
    public var parkingGroundId: String?
    public var fromParkingDate: Date?
    public var toParkingDate: Date?
    public var stationCodeTable: CodeTableType?
    public var stationNum: Int?
    public var stationIA5: String?
    public var stationNameUTF8: String?
    public var specialInformation: String?
    public var extensionData: TicketExtension?
    public var price: Int?
    public var vatDetails: [VatDetailAPI] = []
    public var productOwner: String?

    public init() {}
}
