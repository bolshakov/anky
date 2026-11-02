// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum ReadingWindow {
    public static let length: TimeInterval = 2 * 60 * 60

    /// Compared by whole minute, so a reading in the dose's own minute counts whatever its seconds.
    public static func entries(in entries: [Entry], before doseTime: Date) -> [Entry] {
        let oldestMinute = doseTime.addingTimeInterval(-length).wholeMinute
        let newestMinute = doseTime.wholeMinute
        return entries.enumerated()
            .filter { (oldestMinute ... newestMinute).contains($0.element.date.wholeMinute) }
            .sorted { lhs, rhs in
                let lhsMinute = lhs.element.date.wholeMinute
                let rhsMinute = rhs.element.date.wholeMinute
                if lhsMinute != rhsMinute {
                    return lhsMinute > rhsMinute
                }
                return lhs.offset > rhs.offset
            }
            .map(\.element)
    }

    public static func latest(in entries: [Entry], before doseTime: Date) -> Entry? {
        Self.entries(in: entries, before: doseTime).first
    }

    /// The manual pick if it is still in the window, else the newest in-window entry.
    public static func pick(_ manual: UUID?, in entries: [Entry], before doseTime: Date) -> Entry? {
        let window = Self.entries(in: entries, before: doseTime)
        return window.first { $0.id == manual } ?? window.first
    }
}
