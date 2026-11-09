// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import SwiftUI

extension CheckInInfoWords {
    static var app: CheckInInfoWords {
        CheckInInfoWords(
            taken: { String(localized: "Taken \($0).") },
            before: { kind, level in
                switch kind {
                case .pain: String(localized: "Before: pain \(level).")
                case .stiffness: String(localized: "Before: stiffness \(level).")
                case .fatigue: String(localized: "Before: fatigue \(level).")
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

    static func infoTaken(takenAt: Date, before: Entry?) -> String {
        let taken = CheckInDayText.takenText(for: takenAt, calendar: .current, locale: .current)
        return CheckInDayText.infoTaken(taken: taken, before: before, words: .app)
    }

    static func footnote(for kind: EntryKind, startsAtEarlierReading: Bool) -> Text {
        let saved = savedAs(kind)
        guard startsAtEarlierReading else { return Text(verbatim: saved) }
        let starts = String(localized: "Starts from your earlier entry. Change the level or places if they differ.")
        return Text(verbatim: "\(starts) \(saved)")
    }

    private static func savedAs(_ kind: EntryKind) -> String {
        switch kind {
        case .pain: String(localized: "Saved as a pain entry.")
        case .stiffness: String(localized: "Saved as a stiffness entry.")
        case .fatigue: String(localized: "Saved as a fatigue entry.")
        }
    }
}
