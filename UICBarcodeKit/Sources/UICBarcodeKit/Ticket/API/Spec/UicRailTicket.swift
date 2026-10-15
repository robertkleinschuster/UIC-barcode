import Foundation

/// Version-independent UIC rail ticket abstraction.
/// Provides a unified interface over V1, V2, and V3 FCB ticket data.
public protocol UicRailTicket: AnyObject {
    var issuingDetail: IssuingDetail? { get set }
    var travelerDetail: TravelerDetail? { get set }
    var controlDetail: ControlDetail? { get set }
    var documents: [APIDocumentData] { get set }
    var extensions: [TicketExtension] { get set }

    func addDocument(_ document: APIDocumentData)
}
