// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// One line of a day's log, an entry, a dose or a BASDAI result, so all kinds are listed in one order.
public enum LoggedItem: Identifiable, Equatable, Sendable {
    case entry(Entry)
    case dose(Dose)
    case basdai(BasdaiResult)

    public var id: UUID {
        switch self {
        case let .entry(entry): entry.id
        case let .dose(dose): dose.id
        case let .basdai(result): result.id
        }
    }

    public var date: Date {
        switch self {
        case let .entry(entry): entry.date
        case let .dose(dose): dose.takenAt
        case let .basdai(result): result.date
        }
    }

    /// Newest minute first. Within a minute a dose comes before an entry and an entry before a BASDAI result. Two
    /// entries list the later saved first, and two doses or two results list the later stored first, then the later
    /// position.
    static func newestFirst(_ saved: [LoggedItem]) -> [LoggedItem] {
        saved.enumerated().sorted { lhs, rhs in
            let lhsMinute = lhs.element.date.wholeMinute
            let rhsMinute = rhs.element.date.wholeMinute
            if lhsMinute != rhsMinute {
                return lhsMinute > rhsMinute
            }
            if lhs.element.minuteRank != rhs.element.minuteRank {
                return lhs.element.minuteRank < rhs.element.minuteRank
            }
            if lhs.element.ordersByDateInAMinute, lhs.element.date != rhs.element.date {
                return lhs.element.date > rhs.element.date
            }
            return lhs.offset > rhs.offset
        }
        .map(\.element)
    }

    var isDose: Bool {
        if case .dose = self {
            true
        } else {
            false
        }
    }

    private var minuteRank: Int {
        switch self {
        case .dose: 0
        case .entry: 1
        case .basdai: 2
        }
    }

    private var ordersByDateInAMinute: Bool {
        if case .entry = self {
            false
        } else {
            true
        }
    }
}
