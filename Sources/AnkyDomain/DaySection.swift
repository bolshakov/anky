import Foundation

public struct DaySection: Identifiable, Equatable, Sendable {
    public let id: Date
    public let header: DayHeader
    public let entries: [Entry]
}
