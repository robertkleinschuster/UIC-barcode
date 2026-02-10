import Foundation

/// Enum for supported dynamic content types
public enum DynamicContentType: String {
    case fdc1 = "FDC1"  // GPS/Location data
    case unknown

    public init(identifier: String) {
        switch identifier {
        case "FDC1":
            self = .fdc1
        default:
            self = .unknown
        }
    }
}

/// Wrapper for dynamic content of various types
public enum DynamicContent {
    case fdc1(DynamicContentFDC1)
    case unknown(identifier: String, data: Data)

    /// Parse dynamic content from decoder
    public static func decode(from decoder: inout UPERDecoder) throws -> DynamicContent {
        // Read the identifier
        let identifier = try decoder.decodeIA5String()

        switch DynamicContentType(identifier: identifier) {
        case .fdc1:
            let fdc1 = try DynamicContentFDC1(from: &decoder)
            return .fdc1(fdc1)
        case .unknown:
            // Read as opaque data
            let data = try decoder.decodeOctetString()
            return .unknown(identifier: identifier, data: data)
        }
    }

    /// Get the content type
    public var contentType: DynamicContentType {
        switch self {
        case .fdc1:
            return .fdc1
        case .unknown(let identifier, _):
            return DynamicContentType(identifier: identifier)
        }
    }

    /// Get FDC1 content if available
    public var fdc1Content: DynamicContentFDC1? {
        if case .fdc1(let content) = self {
            return content
        }
        return nil
    }
}
