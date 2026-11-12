// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// The report's shared week axis: which weeks carry a label, so a six-month axis stays legible, and what a label reads.
public enum ReportWeekAxis {
    private static let weeksLabelledEach = 14

    public static func labelStride(weekCount: Int) -> Int {
        weekCount > weeksLabelledEach ? 2 : 1
    }

    public static func labelledIndices(weekCount: Int) -> [Int] {
        Array(stride(from: 0, to: weekCount, by: labelStride(weekCount: weekCount)))
    }

    public static func label(for weekStart: Date, locale: Locale, calendar: Calendar) -> String {
        weekStart.formatted(
            Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone).day().month(.abbreviated)
        )
    }
}
