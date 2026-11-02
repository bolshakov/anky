// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation

enum CheckInDay {
    case today
    case yesterday
    case on(String)

    init(_ date: Date, now: Date) {
        switch ShortDayText.day(for: date, now: now, calendar: .current, locale: .current) {
        case .today:
            self = .today
        case .yesterday:
            self = .yesterday
        case let .sameYear(day):
            self = .on(day)
        case let .otherYear(day, year):
            self = .on(String(localized: "\(day) \(year)"))
        }
    }
}

enum CheckInText {
    static func question(for kind: EntryKind) -> String {
        switch kind {
        case .pain: String(localized: "How is your pain now?")
        case .stiffness: String(localized: "How is your stiffness now?")
        case .fatigue: String(localized: "How is your fatigue now?")
        }
    }

    static func logAction(for kind: EntryKind) -> String {
        switch kind {
        case .pain: String(localized: "Log pain")
        case .stiffness: String(localized: "Log stiffness")
        case .fatigue: String(localized: "Log fatigue")
        }
    }

    static func rowSubtitle(name: String, time: String, day: CheckInDay) -> String {
        switch day {
        case .today: String(localized: "After your \(name) at \(time)")
        case .yesterday: String(localized: "After your \(name) yesterday at \(time)")
        case let .on(date): String(localized: "After your \(name) on \(date) at \(time)")
        }
    }

    static func infoHead(name: String, time: String, day: CheckInDay) -> String {
        switch day {
        case .today: String(localized: "After \(name). Taken at \(time).")
        case .yesterday: String(localized: "After \(name). Taken yesterday at \(time).")
        case let .on(date): String(localized: "After \(name). Taken on \(date) at \(time).")
        }
    }

    static func infoPain(_ entry: Entry) -> String {
        String(localized: "\(String(localized: entry.kind.displayName)) was \(entry.severity.value) of 10 then.")
    }
}
