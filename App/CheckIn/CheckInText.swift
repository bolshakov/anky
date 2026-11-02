// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import SwiftUI

extension CheckInRowWords {
    static var app: CheckInRowWords {
        CheckInRowWords(
            today: { name, time in String(localized: "After your \(name) at \(time)") },
            yesterday: { name, time in String(localized: "After your \(name) yesterday at \(time)") },
            onDay: { name, day, time in String(localized: "After your \(name) on \(day) at \(time)") },
            yearDay: { day, year in String(localized: "\(day) \(year)") }
        )
    }
}

extension CheckInInfoWords {
    static var app: CheckInInfoWords {
        CheckInInfoWords(
            today: { time in String(localized: "Taken at \(time).") },
            yesterday: { time in String(localized: "Taken yesterday at \(time).") },
            onDay: { day, time in String(localized: "Taken on \(day) at \(time).") },
            yearDay: { day, year in String(localized: "\(day) \(year)") }
        )
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

    static func severityCaption(for kind: EntryKind) -> LocalizedStringKey {
        switch kind {
        case .pain: "Pain now"
        case .stiffness: "Stiffness now"
        case .fatigue: "Fatigue now"
        }
    }

    static func logAction(for kind: EntryKind) -> String {
        switch kind {
        case .pain: String(localized: "Log pain")
        case .stiffness: String(localized: "Log stiffness")
        case .fatigue: String(localized: "Log fatigue")
        }
    }

    static func rowSubtitle(name: String, time: String, takenAt: Date, now: Date) -> String {
        let day = CheckInDayText.day(for: takenAt, now: now, calendar: .current, locale: .current)
        return CheckInDayText.rowSubtitle(name: name, time: time, day: day, words: .app)
    }

    static func infoTitle(title: String) -> String {
        String(localized: "After \(title)")
    }

    static func infoTaken(time: String, takenAt: Date, now: Date) -> String {
        let day = CheckInDayText.day(for: takenAt, now: now, calendar: .current, locale: .current)
        return CheckInDayText.infoTaken(time: time, day: day, words: .app)
    }

    static func infoPain(_ entry: Entry) -> String {
        String(localized: "\(String(localized: entry.kind.displayName)) was \(entry.severity.value) of 10 then.")
    }
}
