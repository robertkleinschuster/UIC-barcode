import Foundation

public struct CompartmentDetailsAPI {
    public var coachType: Int?
    public var compartmentType: Int?
    public var specialAllocation: Int?
    public var coachTypeDescr: String?
    public var compartmentTypeDescr: String?
    public var specialAllocationDescr: String?
    public var position: CompartmentPositionType?
    public var gender: CompartmentGenderType?

    public init() {}
}
