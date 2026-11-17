// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum ReadingPrompt: Equatable, Sendable {
    case now, earlier

    private static let nowWindow: TimeInterval = 5 * 60

    /// `.now` while the dose is at most 5 minutes before `now` or later, else `.earlier`.
    public static func forDose(at doseTime: Date, now: Date) -> ReadingPrompt {
        now.timeIntervalSince(doseTime) <= nowWindow ? .now : .earlier
    }
}
