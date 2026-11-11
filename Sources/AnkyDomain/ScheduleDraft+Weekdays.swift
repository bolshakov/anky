// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public extension ScheduleDraft {
    mutating func toggle(_ weekday: Locale.Weekday) {
        if weekdays.contains(weekday) {
            guard weekdays.count > 1 else { return }
            weekdays.remove(weekday)
        } else {
            weekdays.insert(weekday)
        }
    }
}
