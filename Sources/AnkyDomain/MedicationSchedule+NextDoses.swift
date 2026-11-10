// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

extension MedicationSchedule {
    public func nextDoses(after moment: Date, count: Int, calendar: Calendar) -> [Date] {
        guard count > 0, case let .days(interval) = `repeat` else { return [] }
        let days = DayWalk(schedule: self, interval: interval, calendar: calendar)
        var doses: [Date] = []
        for midnight in days.starting(after: moment) {
            doses += times.compactMap { setTime($0, on: midnight, in: calendar) }.filter { $0 > moment }
            if doses.count >= count {
                break
            }
        }
        return Array(doses.prefix(count))
    }

    private func setTime(_ time: DoseTime, on day: Date, in calendar: Calendar) -> Date? {
        calendar.date(
            bySettingHour: time.hour,
            minute: time.minute,
            second: 0,
            of: day,
            matchingPolicy: .nextTime,
            repeatedTimePolicy: .first,
            direction: .forward
        )
    }
}

private struct DayWalk {
    let schedule: MedicationSchedule
    let interval: Int
    let calendar: Calendar

    func starting(after moment: Date) -> some Sequence<Date> {
        let startOfStart = Calendar.gregorian(in: calendar.timeZone).date(
            from: DateComponents(year: schedule.start.year, month: schedule.start.month, day: schedule.start.day)
        )
        let first = startOfStart.map { firstIndex(from: $0, after: moment) } ?? 0
        return sequence(state: first) { index -> Date? in
            defer { index += 1 }
            guard let startOfStart,
                  let midnight = calendar.date(byAdding: .day, value: index * interval, to: startOfStart),
                  !isPastEnd(midnight) else { return nil }
            return midnight
        }
    }

    private func firstIndex(from startOfStart: Date, after moment: Date) -> Int {
        let momentsDay = calendar.startOfDay(for: moment)
        let daysSinceStart = calendar.dateComponents([.day], from: startOfStart, to: momentsDay).day ?? 0
        return max(0, (daysSinceStart + interval - 1) / interval)
    }

    private func isPastEnd(_ midnight: Date) -> Bool {
        guard let end = schedule.end else { return false }
        return ScheduleDay(midnight, in: calendar.timeZone).isAfter(end)
    }
}
