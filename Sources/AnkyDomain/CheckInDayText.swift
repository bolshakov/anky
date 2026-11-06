// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public typealias TextBeforeWords = (String, Entry?) -> String

/// The words of a Check In info card's taken line. The app supplies the localized ones, one whole string per case.
/// The closures take the time, or the day with its time, then the before reading.
public struct CheckInInfoWords {
    public let today: TextBeforeWords
    public let yesterday: TextBeforeWords
    public let onDay: TextBeforeWords

    public init(
        today: @escaping TextBeforeWords,
        yesterday: @escaping TextBeforeWords,
        onDay: @escaping TextBeforeWords
    ) {
        self.today = today
        self.yesterday = yesterday
        self.onDay = onDay
    }
}

/// `onDay` holds the day and time as one phrase the system formats, so the locale orders them.
public enum DayWording: Equatable, Sendable {
    case today(time: String)
    case yesterday(time: String)
    case onDay(String)
}

public enum CheckInDayText {
    public static func wording(for takenAt: Date, now: Date, calendar: Calendar, locale: Locale) -> DayWording {
        let time = DateTemplateText.text(for: takenAt, template: "jmm", calendar: calendar, locale: locale)
        if calendar.isDate(takenAt, inSameDayAs: now) {
            return .today(time: time)
        }
        let previousDay = calendar.date(byAdding: .day, value: -1, to: now)
        if let previousDay, calendar.isDate(takenAt, inSameDayAs: previousDay) {
            return .yesterday(time: time)
        }
        let sameYear = calendar.component(.year, from: takenAt) == calendar.component(.year, from: now)
        let template = sameYear ? "dMMMjmm" : "dMMMyjmm"
        return .onDay(DateTemplateText.text(for: takenAt, template: template, calendar: calendar, locale: locale))
    }

    public static func infoTaken(wording: DayWording, before: Entry?, words: CheckInInfoWords) -> String {
        switch wording {
        case let .today(time):
            words.today(time, before)
        case let .yesterday(time):
            words.yesterday(time, before)
        case let .onDay(dayAndTime):
            words.onDay(dayAndTime, before)
        }
    }
}
