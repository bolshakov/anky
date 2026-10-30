import Foundation

public enum DayHeader: Equatable, Sendable {
    case today
    case yesterday
    case date(Date, includesYear: Bool)

    public func dateText(calendar: Calendar, locale: Locale) -> String? {
        guard case let .date(day, includesYear) = self else {
            return nil
        }
        var style = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
            .weekday(.wide).day().month(.wide)
        if includesYear {
            style = style.year()
        }
        return day.formatted(style)
    }
}
