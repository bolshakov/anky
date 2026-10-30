import Foundation

public enum DayHeader: Equatable, Sendable {
    case today
    case yesterday
    case date(Date, includesYear: Bool)
}
