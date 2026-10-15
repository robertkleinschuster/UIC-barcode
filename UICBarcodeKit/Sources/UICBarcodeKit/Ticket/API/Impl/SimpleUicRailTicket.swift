import Foundation

/// Concrete implementation of the UicRailTicket protocol
public class SimpleUicRailTicket: UicRailTicket {
    public var issuingDetail: IssuingDetail?
    public var travelerDetail: TravelerDetail?
    public var controlDetail: ControlDetail?
    public var documents: [APIDocumentData] = []
    public var extensions: [TicketExtension] = []

    public init() {}

    public func addDocument(_ document: APIDocumentData) {
        documents.append(document)
    }
}
