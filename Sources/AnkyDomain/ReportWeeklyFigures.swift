// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum WeekMark: Equatable, Sendable {
    case none
    case single(Severity)
    case range(average: Double, lowest: Severity, highest: Severity)

    init(_ severities: [Severity]) {
        let values = severities.map(\.value)
        guard let lowest = severities.min(by: { $0.value < $1.value }),
              let highest = severities.max(by: { $0.value < $1.value })
        else {
            self = .none
            return
        }
        guard values.count > 1 else {
            self = .single(lowest)
            return
        }
        let average = Double(values.reduce(0, +)) / Double(values.count)
        self = .range(average: average, lowest: lowest, highest: highest)
    }
}

public struct WeekFigures: Equatable, Sendable {
    public let weekStart: Date
    public let count: Int
    public let mark: WeekMark

    public init(weekStart: Date, count: Int, mark: WeekMark) {
        self.weekStart = weekStart
        self.count = count
        self.mark = mark
    }
}

public struct KindWeeklyFigures: Equatable, Sendable {
    public let kind: EntryKind
    public let weeks: [WeekFigures]

    public var hasEntries: Bool {
        weeks.contains { $0.count > 0 }
    }

    public var loggedWeekCount: Int {
        weeks.count { $0.count > 0 }
    }

    public init(kind: EntryKind, weeks: [WeekFigures]) {
        self.kind = kind
        self.weeks = weeks
    }
}

/// The report's figures by week: each week starts on the calendar's own first weekday, and an entry counts from the
/// period's start to `now`, both ends included.
public struct ReportWeeklyFigures: Equatable, Sendable {
    public let weekStarts: [Date]
    public let kinds: [KindWeeklyFigures]

    public init(entries: [Entry], period: ReportPeriod, now: Date, calendar: Calendar) {
        let range = period.start(endingAt: now, calendar: calendar) ... now
        let axis = Self.weekStarts(in: range, calendar: calendar)
        let counted = entries.filter { range.contains($0.date) }
        weekStarts = axis
        kinds = EntryKind.allCases.map { kind in
            let severities = Self.severitiesByWeek(counted.filter { $0.kind == kind }, calendar: calendar)
            let weeks = axis.map { start in
                let week = severities[start, default: []]
                return WeekFigures(weekStart: start, count: week.count, mark: WeekMark(week))
            }
            return KindWeeklyFigures(kind: kind, weeks: weeks)
        }
    }

    private static func weekStarts(in range: ClosedRange<Date>, calendar: Calendar) -> [Date] {
        guard var week = calendar.dateInterval(of: .weekOfYear, for: range.lowerBound) else { return [] }
        var starts: [Date] = []
        while week.start <= range.upperBound {
            starts.append(week.start)
            guard let next = calendar.dateInterval(of: .weekOfYear, for: week.end) else { break }
            week = next
        }
        return starts
    }

    private static func severitiesByWeek(_ entries: [Entry], calendar: Calendar) -> [Date: [Severity]] {
        var byWeek: [Date: [Severity]] = [:]
        for entry in entries {
            guard let start = calendar.dateInterval(of: .weekOfYear, for: entry.date)?.start else { continue }
            byWeek[start, default: []].append(entry.severity)
        }
        return byWeek
    }
}
