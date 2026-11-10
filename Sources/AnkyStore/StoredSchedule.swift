// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation

struct StoredSchedule: Codable {
    struct Day: Codable {
        var year: Int
        var month: Int
        var day: Int
    }

    struct Time: Codable {
        var hour: Int
        var minute: Int
    }

    var unit: String
    var interval: Int
    var weekdays: [Int]
    var dayOfMonth: Int?
    var times: [Time]
    var start: Day
    var end: Day?

    private static let week: [Locale.Weekday] = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]

    static func encoded(_ schedule: MedicationSchedule) throws -> Data {
        do {
            return try JSONEncoder().encode(StoredSchedule(schedule))
        } catch {
            throw MedicationStoreError.notSaved
        }
    }

    static func read(_ data: Data) throws -> MedicationSchedule {
        do {
            return try JSONDecoder().decode(StoredSchedule.self, from: data).value()
        } catch {
            throw MedicationStoreError.unreadable
        }
    }

    func value() throws -> MedicationSchedule {
        do {
            return try MedicationSchedule(
                repeat: repetition(),
                times: times.map { try $0.value() },
                start: start.value(),
                end: end?.value()
            )
        } catch {
            throw MedicationStoreError.unreadable
        }
    }

    private func repetition() throws -> ScheduleRepeat {
        switch unit {
        case "days":
            return .days(interval)
        case "weeks":
            let found = try weekdays.map { number in
                guard Self.week.indices.contains(number - 1) else { throw MedicationStoreError.unreadable }
                return Self.week[number - 1]
            }
            return .weeks(interval, on: Set(found))
        case "months":
            guard let dayOfMonth else { throw MedicationStoreError.unreadable }
            return .months(interval, onDay: dayOfMonth)
        default:
            throw MedicationStoreError.unreadable
        }
    }
}

extension StoredSchedule.Day {
    init(_ day: ScheduleDay) {
        self.init(year: day.year, month: day.month, day: day.day)
    }

    func value() throws -> ScheduleDay {
        guard let value = ScheduleDay(year: year, month: month, day: day) else { throw MedicationStoreError.unreadable }
        return value
    }
}

extension StoredSchedule.Time {
    func value() throws -> DoseTime {
        guard let value = DoseTime(hour: hour, minute: minute) else { throw MedicationStoreError.unreadable }
        return value
    }
}

extension StoredSchedule {
    init(_ schedule: MedicationSchedule) {
        switch schedule.repeat {
        case let .days(interval):
            (unit, self.interval, weekdays, dayOfMonth) = ("days", interval, [], nil)
        case let .weeks(interval, days):
            let numbers = days.compactMap { Self.week.firstIndex(of: $0).map { $0 + 1 } }.sorted()
            (unit, self.interval, weekdays, dayOfMonth) = ("weeks", interval, numbers, nil)
        case let .months(interval, day):
            (unit, self.interval, weekdays, dayOfMonth) = ("months", interval, [], day)
        }
        times = schedule.times.map { Time(hour: $0.hour, minute: $0.minute) }
        start = Day(schedule.start)
        end = schedule.end.map(Day.init)
    }
}
