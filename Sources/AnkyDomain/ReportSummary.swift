// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// What a report counts in its period: the entries and the doses taken from the period's start to `now`, both ends
/// included.
public struct ReportSummary: Equatable, Sendable {
    public let entryCount: Int
    public let doseCount: Int
    public let firstEntry: Date?

    public var isEmpty: Bool {
        entryCount == 0 && doseCount == 0
    }

    public init(entries: [Entry], doses: [Dose], period: ReportPeriod, now: Date, calendar: Calendar) {
        // #lizard forgives
        let range = period.start(endingAt: now, calendar: calendar) ... now
        let entryDates = entries.map(\.date).filter(range.contains)
        entryCount = entryDates.count
        doseCount = doses.count { range.contains($0.takenAt) }
        firstEntry = entryDates.min()
    }
}
