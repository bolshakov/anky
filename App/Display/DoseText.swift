// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation

extension DoseWords {
    static var app: DoseWords {
        DoseWords(
            kind: String(localized: "Dose"),
            subtitle: DosePainWords.subtitle(for:),
            spoken: DosePainWords.spoken(for:)
        )
    }
}

/// Each phrase is its own catalog key, so a translation never builds a sentence from a kind word.
private extension DosePainWords {
    static func subtitle(for kind: EntryKind) -> DosePainWords {
        switch kind {
        case .pain: subtitlePain
        case .stiffness: subtitleStiffness
        case .fatigue: subtitleFatigue
        }
    }

    static func spoken(for kind: EntryKind) -> DosePainWords {
        switch kind {
        case .pain: spokenPain
        case .stiffness: spokenStiffness
        case .fatigue: spokenFatigue
        }
    }

    static var subtitlePain: DosePainWords {
        DosePainWords(
            before: { String(localized: "Dose · pain was \($0)") },
            after: { String(localized: "pain \($0) after") },
            beforeAndAfter: { String(localized: "pain \($0) before, \($1) after") }
        )
    }

    static var subtitleStiffness: DosePainWords {
        DosePainWords(
            before: { String(localized: "Dose · stiffness was \($0)") },
            after: { String(localized: "stiffness \($0) after") },
            beforeAndAfter: { String(localized: "stiffness \($0) before, \($1) after") }
        )
    }

    static var subtitleFatigue: DosePainWords {
        DosePainWords(
            before: { String(localized: "Dose · fatigue was \($0)") },
            after: { String(localized: "fatigue \($0) after") },
            beforeAndAfter: { String(localized: "fatigue \($0) before, \($1) after") }
        )
    }

    static var spokenPain: DosePainWords {
        DosePainWords(
            before: { String(localized: "Pain was \($0) of 10") },
            after: { String(localized: "Pain \($0) after") },
            beforeAndAfter: { String(localized: "Pain \($0) before, \($1) after") }
        )
    }

    static var spokenStiffness: DosePainWords {
        DosePainWords(
            before: { String(localized: "Stiffness was \($0) of 10") },
            after: { String(localized: "Stiffness \($0) after") },
            beforeAndAfter: { String(localized: "Stiffness \($0) before, \($1) after") }
        )
    }

    static var spokenFatigue: DosePainWords {
        DosePainWords(
            before: { String(localized: "Fatigue was \($0) of 10") },
            after: { String(localized: "Fatigue \($0) after") },
            beforeAndAfter: { String(localized: "Fatigue \($0) before, \($1) after") }
        )
    }
}
