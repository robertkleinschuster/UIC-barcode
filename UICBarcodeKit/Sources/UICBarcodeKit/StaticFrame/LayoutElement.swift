import Foundation

/// A single element in a U_TLAY layout record
/// Java ref: LayoutElement.java
public struct LayoutElement {
    public let line: Int
    public let column: Int
    public let width: Int
    public let height: Int
    public let format: LayoutFormatType
    public let text: String
}
