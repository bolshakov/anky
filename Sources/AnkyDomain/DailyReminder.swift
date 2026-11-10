// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public struct DailyReminderTime: Equatable, Sendable {
    public let hour: Int
    public let minute: Int

    public init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }

    public static let standard = DailyReminderTime(hour: 20, minute: 0)
}

public enum DailyReminder {
    /// Not a UUID, so the tap delegate never reads it as a dose check-in.
    public static let identifier = "daily-reminder"

    private static let searchDays = 14

    /// The first moment at `time` after `now` on a day of `calendar` with no entry and no dose, or nil when each of the
    /// next `searchDays` days has one. An entry counts toward the day of its `date`, a dose toward the day of its
    /// `takenAt`.
    public static func fireDate( // swiftlint:disable:this function_parameter_count
        entries: [Entry],
        doses: [Dose],
        time: DailyReminderTime,
        now: Date,
        calendar: Calendar
    ) -> Date? {
        // #lizard forgives
        let loggedDays = Set(entries.map(\.date).map(calendar.startOfDay(for:)))
            .union(doses.map(\.takenAt).map(calendar.startOfDay(for:)))
        let today = calendar.startOfDay(for: now)
        return (0 ..< searchDays)
            .compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
            .filter { !loggedDays.contains($0) }
            .compactMap { calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: $0) }
            .first { $0 > now }
    }
}
