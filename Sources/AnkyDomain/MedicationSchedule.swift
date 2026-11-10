// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum ScheduleRepeat: Equatable, Sendable {
    case days(Int)
    case weeks(Int, on: Set<Locale.Weekday>)
    case months(Int, onDay: Int)
}

public enum ScheduleError: Error, Equatable {
    case noInterval
    case noWeekday
    case noSuchDay
    case noTime
}

public struct MedicationSchedule: Equatable, Sendable {
    public let `repeat`: ScheduleRepeat
    public let times: [DoseTime]
    public let start: ScheduleDay
    public let end: ScheduleDay?

    public init(
        repeat repetition: ScheduleRepeat,
        times: [DoseTime],
        start: ScheduleDay,
        end: ScheduleDay?
    ) throws(ScheduleError) {
        try Self.validate(repetition)
        guard !times.isEmpty else { throw .noTime }
        self.repeat = repetition
        self.times = Set(times).sorted()
        self.start = start
        self.end = end
    }

    private static func validate(_ repetition: ScheduleRepeat) throws(ScheduleError) {
        switch repetition {
        case let .days(interval):
            guard interval >= 1 else { throw .noInterval }
        case let .weeks(interval, weekdays):
            guard interval >= 1 else { throw .noInterval }
            guard !weekdays.isEmpty else { throw .noWeekday }
        case let .months(interval, day):
            guard interval >= 1 else { throw .noInterval }
            guard (1 ... 31).contains(day) else { throw .noSuchDay }
        }
    }
}
