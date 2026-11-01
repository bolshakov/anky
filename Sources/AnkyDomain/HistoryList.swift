// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum HistoryList {
    public static func sections(_ entries: [Entry], doses: [Dose], now: Date, calendar: Calendar) -> [DaySection] {
        let days = DayReference(now: now, calendar: calendar)
        let grouped = Dictionary(grouping: newestFirst(entries.map(LoggedItem.entry) + doses.map(LoggedItem.dose))) {
            calendar.startOfDay(for: $0.date)
        }
        return grouped.sorted { $0.key > $1.key }.map { day, items in
            DaySection(id: day, header: days.header(for: day), items: items)
        }
    }

    /// Newest minute first. Within a minute a dose comes before an entry, two entries list the later saved first, and
    /// two doses list the later stored first, then the later position.
    private static func newestFirst(_ saved: [LoggedItem]) -> [LoggedItem] {
        saved.enumerated().sorted { lhs, rhs in
            let lhsMinute = wholeMinute(lhs.element.date)
            let rhsMinute = wholeMinute(rhs.element.date)
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

    private static func wholeMinute(_ date: Date) -> Double {
        (date.timeIntervalSinceReferenceDate / 60).rounded(.down)
    }
}

private struct DayReference {
    let calendar: Calendar
    let today: Date
    let yesterday: Date?
    let year: Int

    init(now: Date, calendar: Calendar) {
        self.calendar = calendar
        today = calendar.startOfDay(for: now)
        yesterday = calendar.date(byAdding: .day, value: -1, to: today).map { calendar.startOfDay(for: $0) }
        year = calendar.component(.year, from: now)
    }

    func header(for day: Date) -> DayHeader {
        if day == today {
            return .today
        }
        if day == yesterday {
            return .yesterday
        }
        return .date(day, includesYear: calendar.component(.year, from: day) != year)
    }
}
