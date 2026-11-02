// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum HistoryList {
    public static func sections(_ entries: [Entry], doses: [Dose], now: Date, calendar: Calendar) -> [DaySection] {
        let days = DayReference(now: now, calendar: calendar)
        let grouped = Dictionary(
            grouping: LoggedItem.newestFirst(entries.map(LoggedItem.entry) + doses.map(LoggedItem.dose))
        ) {
            calendar.startOfDay(for: $0.date)
        }
        return grouped.sorted { $0.key > $1.key }.map { day, items in
            DaySection(id: day, header: days.header(for: day), items: items)
        }
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
