// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation

enum PrefillFootnoteText {
    static func text(for note: PainPrefillNote) -> String {
        switch note.day {
        case .today:
            String(localized: "Filled in from your \(note.clock) entry. Change it if it is different.")
        case .yesterday:
            String(localized: "Filled in from your entry yesterday at \(note.clock). Change it if it is different.")
        case let .sameYear(day):
            onDay(day, clock: note.clock)
        case let .otherYear(day, year):
            onDay(String(localized: "\(day) \(year)"), clock: note.clock)
        }
    }

    private static func onDay(_ day: String, clock: String) -> String {
        String(localized: "Filled in from your entry on \(day) at \(clock). Change it if it is different.")
    }
}
