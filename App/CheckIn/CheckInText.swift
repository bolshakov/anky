// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import SwiftUI

extension CheckInInfoWords {
    static var app: CheckInInfoWords {
        CheckInInfoWords(
            today: { time, before in
                guard let before else { return String(localized: "Taken at \(time).") }
                let level = before.severity.value
                switch before.kind {
                case .pain: return String(localized: "Taken at \(time). Before: Pain \(level).")
                case .stiffness: return String(localized: "Taken at \(time). Before: Stiffness \(level).")
                case .fatigue: return String(localized: "Taken at \(time). Before: Fatigue \(level).")
                }
            },
            yesterday: { time, before in
                guard let before else { return String(localized: "Taken yesterday at \(time).") }
                let level = before.severity.value
                switch before.kind {
                case .pain: return String(localized: "Taken yesterday at \(time). Before: Pain \(level).")
                case .stiffness: return String(localized: "Taken yesterday at \(time). Before: Stiffness \(level).")
                case .fatigue: return String(localized: "Taken yesterday at \(time). Before: Fatigue \(level).")
                }
            },
            onDay: { dayAndTime, before in
                guard let before else { return String(localized: "Taken \(dayAndTime).") }
                let level = before.severity.value
                switch before.kind {
                case .pain: return String(localized: "Taken \(dayAndTime). Before: Pain \(level).")
                case .stiffness: return String(localized: "Taken \(dayAndTime). Before: Stiffness \(level).")
                case .fatigue: return String(localized: "Taken \(dayAndTime). Before: Fatigue \(level).")
                }
            }
        )
    }
}

enum CheckInText {
    static func severityCaption(for kind: EntryKind) -> LocalizedStringKey {
        switch kind {
        case .pain: "Pain now"
        case .stiffness: "Stiffness now"
        case .fatigue: "Fatigue now"
        }
    }

    static func infoTaken(takenAt: Date, before: Entry?, now: Date) -> String {
        let wording = CheckInDayText.wording(for: takenAt, now: now, calendar: .current, locale: .current)
        return CheckInDayText.infoTaken(wording: wording, before: before, words: .app)
    }

    static func footnote(for kind: EntryKind, startsAtEarlierReading: Bool) -> LocalizedStringKey {
        switch (kind, startsAtEarlierReading) {
        case (.pain, false): "Saved as a Pain entry."
        case (.stiffness, false): "Saved as a Stiffness entry."
        case (.fatigue, false): "Saved as a Fatigue entry."
        case (.pain, true): """
            Starts at your earlier reading, with the same places. Change either if it is different. \
            Saved as a Pain entry.
            """
        case (.stiffness, true): """
            Starts at your earlier reading, with the same places. Change either if it is different. \
            Saved as a Stiffness entry.
            """
        case (.fatigue, true): """
            Starts at your earlier reading, with the same places. Change either if it is different. \
            Saved as a Fatigue entry.
            """
        }
    }
}
