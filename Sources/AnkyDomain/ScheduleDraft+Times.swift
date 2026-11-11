// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

extension ScheduleDraft {
    private static let minutesInDay = 24 * 60

    /// Adds an hour after the last time, or the next free minute after that, so a row always appears. Changes nothing
    /// only when every minute of the day is already a time.
    public mutating func addTime() {
        guard let last = times.last else { return }
        let taken = Set(times)
        let first = Self.minuteOfDay(last) + 60
        let free = (0 ..< Self.minutesInDay)
            .lazy
            .compactMap { Self.time(atMinute: first + $0) }
            .first { !taken.contains($0) }
        if let free {
            times.append(free)
        }
    }

    public mutating func removeTime(at index: Int) {
        guard times.count > 1, times.indices.contains(index) else { return }
        times.remove(at: index)
    }

    private static func minuteOfDay(_ time: DoseTime) -> Int {
        time.hour * 60 + time.minute
    }

    private static func time(atMinute minute: Int) -> DoseTime? {
        let wrapped = minute % minutesInDay
        return DoseTime(hour: wrapped / 60, minute: wrapped % 60)
    }
}
