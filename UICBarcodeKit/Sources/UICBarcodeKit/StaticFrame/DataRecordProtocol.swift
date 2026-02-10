import Foundation

/// Base protocol for data records
public protocol DataRecordProtocol {
    var tag: String { get }
    var version: String { get }
    var content: Data { get }
}
