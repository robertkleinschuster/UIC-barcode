import Foundation

/// UIC Rail Ticket Data - the main FCB ticket structure
/// This is the root SEQUENCE of the FCB (Flexible Content Barcode)
public struct UicRailTicketData: ASN1Decodable {
    // MARK: - Fields

    /// Issuing details (mandatory)
    public var issuingDetail: IssuingData

    /// Traveler details (optional)
    public var travelerDetail: TravelerData?

    /// Transport documents (optional)
    public var transportDocument: [DocumentData]?

    /// Control details (optional)
    public var controlDetail: ControlData?

    /// Extension data (optional)
    public var extensionData: [ExtensionData]?

    // MARK: - ASN.1 Metadata

    /// Has extension marker in ASN.1 definition
    public static let hasExtensionMarker = true

    /// Number of optional fields in root
    public static let optionalFieldCount = 4

    // MARK: - Initialization

    public init() {
        self.issuingDetail = IssuingData()
    }

    /// Decode from UPER
    public init(from decoder: inout UPERDecoder) throws {
        // Check extension bit
        let hasExtensions = try decoder.decodeBit()

        // Read presence bitmap for optional fields (4 fields)
        let presence = try decoder.decodePresenceBitmap(count: Self.optionalFieldCount)

        // Decode mandatory field: issuingDetail
        self.issuingDetail = try IssuingData(from: &decoder)

        // Decode optional field: travelerDetail
        if presence[0] {
            self.travelerDetail = try TravelerData(from: &decoder)
        }

        // Decode optional field: transportDocument
        if presence[1] {
            self.transportDocument = try decoder.decodeSequenceOf()
        }

        // Decode optional field: controlDetail
        if presence[2] {
            self.controlDetail = try ControlData(from: &decoder)
        }

        // Decode optional field: extension
        if presence[3] {
            self.extensionData = try decoder.decodeSequenceOf()
        }

        // Handle extensions if present
        if hasExtensions {
            let numExtensions = try decoder.decodeBitmaskLength()
            let extensionPresence = try decoder.decodePresenceBitmap(count: numExtensions)

            // Skip unknown extensions
            for i in 0..<numExtensions {
                if extensionPresence[i] {
                    try decoder.skipOpenType()
                }
            }
        }
    }
}

// MARK: - Encoding

extension UicRailTicketData: ASN1Encodable {
    public func encode(to encoder: inout UPEREncoder) throws {
        try encoder.encodeBit(false)
        try encoder.encodePresenceBitmap([
            travelerDetail != nil,
            transportDocument != nil,
            controlDetail != nil,
            extensionData != nil
        ])
        try issuingDetail.encode(to: &encoder)
        if let travelerDetail {
            try travelerDetail.encode(to: &encoder)
        }
        if let transportDocument {
            try encoder.encodeSequenceOf(transportDocument)
        }
        if let controlDetail {
            try controlDetail.encode(to: &encoder)
        }
        if let extensionData {
            try encoder.encodeSequenceOf(extensionData)
        }
    }
}
