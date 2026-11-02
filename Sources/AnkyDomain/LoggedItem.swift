// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// One line of a day's log, an entry or a dose, so both kinds are listed in one order.
public enum LoggedItem: Identifiable, Equatable, Sendable {
    case entry(Entry)
    case dose(Dose)

    public var id: UUID {
        switch self {
        case let .entry(entry): entry.id
        case let .dose(dose): dose.id
        }
    }

    public var date: Date {
        switch self {
        case let .entry(entry): entry.date
        case let .dose(dose): dose.takenAt
        }
    }

    /// Newest minute first. Within a minute a dose comes before an entry, two entries list the later saved first, and
    /// two doses list the later stored first, then the later position.
    static func newestFirst(_ saved: [LoggedItem]) -> [LoggedItem] {
        saved.enumerated().sorted { lhs, rhs in
            let lhsMinute = lhs.element.date.wholeMinute
            let rhsMinute = rhs.element.date.wholeMinute
            if lhsMinute != rhsMinute {
                return lhsMinute > rhsMinute
            }
            if lhs.element.isDose != rhs.element.isDose {
                return lhs.element.isDose
            }
            if lhs.element.isDose, lhs.element.date != rhs.element.date {
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
}
