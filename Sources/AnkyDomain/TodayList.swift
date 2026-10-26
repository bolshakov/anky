import Foundation

public enum TodayList {
    public static func entries(_ all: [Entry], on day: Date, calendar: Calendar) -> [Entry] {
        all.enumerated()
            .filter { calendar.isDate($0.element.date, inSameDayAs: day) }
            .sorted { lhs, rhs in
                if lhs.element.date != rhs.element.date {
                    return lhs.element.date > rhs.element.date
                }
                return lhs.offset > rhs.offset
            }
            .map(\.element)
    }
}
