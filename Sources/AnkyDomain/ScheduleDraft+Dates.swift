// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public extension ScheduleDraft {
    mutating func setStart(_ day: ScheduleDay) {
        start = day
        if let end, day.isAfter(end) {
            self.end = day
        }
    }

    mutating func setEnd(_ day: ScheduleDay?) {
        end = day.map { start.isAfter($0) ? start : $0 }
    }
}
