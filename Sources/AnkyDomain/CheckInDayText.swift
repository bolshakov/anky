// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public typealias TimeWords = (String) -> String
public typealias PairWords = (String, String) -> String
public typealias TripleWords = (String, String, String) -> String

/// The words of a Check In row's subtitle. The app supplies the localized ones. The closures take the name, then the
/// day, then the time, in that order.
public struct CheckInRowWords {
    public let today: PairWords
    public let yesterday: PairWords
    public let onDay: TripleWords
    public let yearDay: PairWords

    public init(
        today: @escaping PairWords,
        yesterday: @escaping PairWords,
        onDay: @escaping TripleWords,
        yearDay: @escaping PairWords
    ) {
        self.today = today
        self.yesterday = yesterday
        self.onDay = onDay
        self.yearDay = yearDay
    }
}

/// The words of a Check In info card's taken line. The app supplies the localized ones. The closures take the day,
/// then the time, in that order.
public struct CheckInInfoWords {
    public let today: TimeWords
    public let yesterday: TimeWords
    public let onDay: PairWords
    public let yearDay: PairWords

    public init(
        today: @escaping TimeWords,
        yesterday: @escaping TimeWords,
        onDay: @escaping PairWords,
        yearDay: @escaping PairWords
    ) {
        self.today = today
        self.yesterday = yesterday
        self.onDay = onDay
        self.yearDay = yearDay
    }
}

/// The day wording of a Check In row and its info card. Both read a dose's day the way the date row reads its day.
public enum CheckInDayText {
    public static func day(for takenAt: Date, now: Date, calendar: Calendar, locale: Locale) -> ShortDay {
        ShortDayText.day(for: takenAt, now: now, calendar: calendar, locale: locale)
    }

    public static func rowSubtitle(name: String, time: String, day: ShortDay, words: CheckInRowWords) -> String {
        switch day {
        case .today:
            words.today(name, time)
        case .yesterday:
            words.yesterday(name, time)
        case let .sameYear(text):
            words.onDay(name, text, time)
        case let .otherYear(text, year):
            words.onDay(name, words.yearDay(text, year), time)
        }
    }

    public static func infoTaken(time: String, day: ShortDay, words: CheckInInfoWords) -> String {
        switch day {
        case .today:
            words.today(time)
        case .yesterday:
            words.yesterday(time)
        case let .sameYear(text):
            words.onDay(text, time)
        case let .otherYear(text, year):
            words.onDay(words.yearDay(text, year), time)
        }
    }
}
