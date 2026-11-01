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

    /// Newest first by stored time. On an equal time a dose comes before an entry, and within a kind the later saved
    /// comes first.
    public static func items(entries: [Entry], doses: [Dose], on day: Date, calendar: Calendar) -> [LoggedItem] {
        let logged = entries.map(LoggedItem.entry) + doses.map(LoggedItem.dose)
        return logged.enumerated()
            .filter { calendar.isDate($0.element.date, inSameDayAs: day) }
            .sorted { lhs, rhs in
                if lhs.element.date != rhs.element.date {
                    return lhs.element.date > rhs.element.date
                }
                if lhs.element.isDose != rhs.element.isDose {
                    return lhs.element.isDose
                }
                return lhs.offset > rhs.offset
            }
            .map(\.element)
    }
}
