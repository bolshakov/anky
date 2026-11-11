// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

extension MedicationSchedule {
    public func nextDoses(after moment: Date, count: Int, calendar: Calendar) -> [Date] {
        guard count > 0, let days = DayWalk(schedule: self, calendar: calendar) else { return [] }
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
    let calendar: Calendar
    private let gregorian: Calendar
    private let startOfStart: Date

    init?(schedule: MedicationSchedule, calendar: Calendar) {
        let gregorian = Calendar.gregorian(in: calendar.timeZone)
        let start = schedule.start
        guard let startOfStart = gregorian.date(from: DateComponents(
            year: start.year,
            month: start.month,
            day: start.day
        ))
        else { return nil }
        self.schedule = schedule
        self.calendar = calendar
        self.gregorian = gregorian
        self.startOfStart = startOfStart
    }

    func starting(after moment: Date) -> some Sequence<Date> {
        let first = max(0, unitsSinceStart(to: calendar.startOfDay(for: moment)) / interval)
        return sequence(state: first) { index -> [Date]? in
            defer { index += 1 }
            return days(inBlock: index)
        }
        .joined()
        .lazy
        .filter { $0 >= startOfStart }
        .prefix { !isPastEnd($0) }
    }

    private var interval: Int {
        switch schedule.repeat {
        case let .days(interval), let .weeks(interval, _), let .months(interval, _): interval
        }
    }

    private var weekAnchor: Date {
        let weekday = calendar.component(.weekday, from: startOfStart)
        let daysIntoWeek = (weekday - calendar.firstWeekday + 7) % 7
        return calendar.date(byAdding: .day, value: -daysIntoWeek, to: startOfStart) ?? startOfStart
    }

    private var firstOfStartMonth: Date {
        let start = schedule.start
        return gregorian.date(from: DateComponents(year: start.year, month: start.month, day: 1)) ?? startOfStart
    }

    private func unitsSinceStart(to day: Date) -> Int {
        switch schedule.repeat {
        case .days:
            calendar.dateComponents([.day], from: startOfStart, to: day).day ?? 0
        case .weeks:
            (calendar.dateComponents([.day], from: weekAnchor, to: day).day ?? 0) / 7
        case .months:
            gregorian.dateComponents([.month], from: firstOfStartMonth, to: day).month ?? 0
        }
    }

    private func days(inBlock index: Int) -> [Date]? {
        switch schedule.repeat {
        case .days:
            calendar.date(byAdding: .day, value: index * interval, to: startOfStart).map { [$0] }
        case let .weeks(_, weekdays):
            weekdayDays(inWeek: index * interval, on: weekdays)
        case let .months(_, day):
            gregorian.date(byAdding: .month, value: index * interval, to: firstOfStartMonth)
                .flatMap { clamped(day, inMonthOf: $0) }
                .map { [$0] }
        }
    }

    private func weekdayDays(inWeek week: Int, on weekdays: Set<Locale.Weekday>) -> [Date]? {
        let numbers = Set(weekdays.map(\.number))
        return calendar.date(byAdding: .day, value: week * 7, to: weekAnchor).map { firstDay in
            (0 ..< 7)
                .compactMap { calendar.date(byAdding: .day, value: $0, to: firstDay) }
                .filter { numbers.contains(calendar.component(.weekday, from: $0)) }
        }
    }

    private func clamped(_ day: Int, inMonthOf firstOfMonth: Date) -> Date? {
        let lastDay = (gregorian.range(of: .day, in: .month, for: firstOfMonth)?.upperBound ?? 29) - 1
        return gregorian.date(byAdding: .day, value: min(day, lastDay) - 1, to: firstOfMonth)
    }

    private func isPastEnd(_ midnight: Date) -> Bool {
        guard let end = schedule.end else { return false }
        return ScheduleDay(midnight, in: calendar.timeZone).isAfter(end)
    }
}

private extension Locale.Weekday {
    var number: Int {
        switch self {
        case .sunday: 1
        case .monday: 2
        case .tuesday: 3
        case .wednesday: 4
        case .thursday: 5
        case .friday: 6
        case .saturday: 7
        @unknown default: 0
        }
    }
}
