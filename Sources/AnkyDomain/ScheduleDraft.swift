// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public struct ScheduleDraft: Equatable, Sendable {
    public enum Unit: Equatable, Sendable { case days, weeks, months }

    public enum Preset: Equatable, Sendable, CaseIterable {
        case everyDay, everyWeek, everyTwoWeeks, everyFourWeeks, everyMonth, custom
    }

    public var unit: Unit
    public var interval: Int
    public var weekdays: Set<Locale.Weekday>
    public var dayOfMonth: Int
    public var times: [DoseTime]
    public var start: ScheduleDay
    public var end: ScheduleDay?

    public init(startingOn start: ScheduleDay, calendar _: Calendar) {
        unit = .days
        interval = 1
        weekdays = [start.weekday]
        dayOfMonth = start.day
        times = [DoseTime(hour: 9, minute: 0)].compactMap(\.self)
        self.start = start
        end = nil
    }

    public init(_ schedule: MedicationSchedule, calendar: Calendar) {
        self.init(startingOn: schedule.start, calendar: calendar)
        times = schedule.times
        end = schedule.end
        switch schedule.repeat {
        case let .days(every):
            interval = every
        case let .weeks(every, on: days):
            unit = .weeks
            interval = every
            weekdays = days
        case let .months(every, onDay: day):
            unit = .months
            interval = every
            dayOfMonth = day
        }
    }

    public var preset: Preset {
        Preset.allCases.first { $0.repeatUnit == unit && $0.repeatInterval == interval } ?? .custom
    }

    public mutating func choose(_ preset: Preset) {
        guard let presetUnit = preset.repeatUnit, let presetInterval = preset.repeatInterval else { return }
        unit = presetUnit
        interval = presetInterval
    }

    public func schedule() -> MedicationSchedule? {
        let shape: ScheduleRepeat = switch unit {
        case .days: .days(interval)
        case .weeks: .weeks(interval, on: weekdays)
        case .months: .months(interval, onDay: dayOfMonth)
        }
        return try? MedicationSchedule(repeat: shape, times: times, start: start, end: end)
    }
}

private extension ScheduleDraft.Preset {
    var repeatUnit: ScheduleDraft.Unit? {
        switch self {
        case .everyDay: .days
        case .everyWeek, .everyTwoWeeks, .everyFourWeeks: .weeks
        case .everyMonth: .months
        case .custom: nil
        }
    }

    var repeatInterval: Int? {
        switch self {
        case .everyDay, .everyWeek, .everyMonth: 1
        case .everyTwoWeeks: 2
        case .everyFourWeeks: 4
        case .custom: nil
        }
    }
}

private extension ScheduleDay {
    var weekday: Locale.Weekday {
        let calendar = Calendar.gregorian(in: .gmt)
        let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .distantPast
        let order: [Locale.Weekday] = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
        return order[calendar.component(.weekday, from: date) - 1]
    }
}
