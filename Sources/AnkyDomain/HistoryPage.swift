// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// How many of the newest days a page of History shows, and the clock that names them.
public struct HistoryWindow: Sendable {
    public let days: Int
    public let now: Date
    public let calendar: Calendar

    public init(days: Int, now: Date, calendar: Calendar) {
        self.days = days
        self.now = now
        self.calendar = calendar
    }
}

public struct HistoryPage: Equatable, Sendable {
    public let sections: [DaySection]
    public let hasOlderDays: Bool
}

public extension HistoryList {
    static let pageDays = 30

    /// The newest days that hold an entry or a dose, by logged time, each whole. They equal the same days of
    /// `sections` over the whole log.
    static func page(_ entries: [Entry], doses: [Dose], window: HistoryWindow) -> HistoryPage {
        let calendar = window.calendar
        let days = Set(entries.map { calendar.startOfDay(for: $0.date) })
            .union(doses.map { calendar.startOfDay(for: $0.takenAt) })
            .sorted(by: >)
        let shown = max(window.days, 0)
        guard shown > 0 else {
            return HistoryPage(sections: [], hasOlderDays: !days.isEmpty)
        }
        guard days.count > shown else {
            return HistoryPage(
                sections: sections(entries, doses: doses, now: window.now, calendar: calendar),
                hasOlderDays: false
            )
        }
        let oldestShown = days[shown - 1]
        return HistoryPage(
            sections: sections(
                entries.filter { $0.date >= oldestShown },
                doses: doses.filter { $0.takenAt >= oldestShown },
                now: window.now,
                calendar: calendar
            ),
            hasOlderDays: true
        )
    }
}
