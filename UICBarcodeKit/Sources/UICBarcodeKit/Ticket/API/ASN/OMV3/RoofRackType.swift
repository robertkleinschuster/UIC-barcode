import Foundation

/// Roof rack type
/// Matches Java: RoofRackType.java (9 values)
public enum RoofRackType: Int {
    case norack = 0
    case roofRailing = 1
    case luggageRack = 2
    case skiRack = 3
    case boxRack = 4
    case rackWithOneBox = 5
    case rackWithTwoBoxes = 6
    case bicycleRack = 7
    case otherRack = 8
}
