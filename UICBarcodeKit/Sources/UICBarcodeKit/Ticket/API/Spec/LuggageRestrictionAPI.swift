import Foundation

public struct LuggageRestrictionAPI {
    public var maxHandLuggagePieces: Int?
    public var maxNonHandLuggagePieces: Int?
    public var registeredLuggage: [RegisteredLuggageAPI] = []

    public init() {}
}
