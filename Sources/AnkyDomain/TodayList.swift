// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum TodayList {
    public static func entries(_ all: [Entry], on day: Date, calendar: Calendar) -> [Entry] {
        all.enumerated()
            .filter { calendar.isDate($0.element.date, inSameDayAs: day) }
            .sorted { lhs, rhs in
                if lhs.element.date != rhs.element.date {
                    return lhs.element.date > rhs.element.date
                }
                return lhs.offset > rhs.offset
            }
            .map(\.element)
    }

    /// Ordered as the History list orders a day, so the two lists agree.
    public static func items(entries: [Entry], doses: [Dose], on day: Date, calendar: Calendar) -> [LoggedItem] {
        let logged = entries.map(LoggedItem.entry) + doses.map(LoggedItem.dose)
        return LoggedItem.newestFirst(logged.filter { calendar.isDate($0.date, inSameDayAs: day) })
    }
}
