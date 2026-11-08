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
        let formatter = DateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.formattingContext = .middleOfSentence
        return CheckInDayText.infoTaken(taken: formatter.string(from: takenAt), before: before, words: .app)
    }

    static func footnote(for kind: EntryKind, startsAtEarlierReading: Bool) -> Text {
        let saved = savedAs(kind)
        guard startsAtEarlierReading else { return saved }
        let starts = Text("Starts from your earlier entry. Change the level or places if they differ.")
        return Text("\(starts) \(saved)")
    }

    private static func savedAs(_ kind: EntryKind) -> Text {
        switch kind {
        case .pain: Text("Saved as a pain entry.")
        case .stiffness: Text("Saved as a stiffness entry.")
        case .fatigue: Text("Saved as a fatigue entry.")
        }
    }
}
