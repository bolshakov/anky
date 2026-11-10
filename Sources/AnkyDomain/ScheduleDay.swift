// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public struct ScheduleDay: Equatable, Hashable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int

    public init?(year: Int, month: Int, day: Int) {
        let calendar = Calendar.gregorian(in: .gmt)
        let parts = DateComponents(year: year, month: month, day: day)
        guard let date = calendar.date(from: parts) else { return nil }
        let found = calendar.dateComponents([.year, .month, .day], from: date)
        guard found.year == year, found.month == month, found.day == day else { return nil }
        self.year = year
        self.month = month
        self.day = day
    }

    public init(_ date: Date, in timeZone: TimeZone) {
        let calendar = Calendar.gregorian(in: timeZone)
        year = calendar.component(.year, from: date)
        month = calendar.component(.month, from: date)
        day = calendar.component(.day, from: date)
    }

    func isAfter(_ other: ScheduleDay) -> Bool {
        (year, month, day) > (other.year, other.month, other.day)
    }
}

extension Calendar {
    static func gregorian(in timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
}
