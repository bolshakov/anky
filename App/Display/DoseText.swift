// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation

extension DoseWords {
    static var app: DoseWords {
        DoseWords(
            kind: String(localized: "Dose"),
            subtitlePain: { pain in
                switch pain {
                case let .before(kind, level):
                    String(localized: "\(kind.subtitleWord) was \(level.value)")
                case let .after(kind, level):
                    String(localized: "\(kind.subtitleWord) \(level.value) after")
                case let .beforeAndAfter(kind, before, after):
                    String(localized: "\(kind.subtitleWord) \(before.value) before, \(after.value) after")
                }
            },
            spokenPain: { pain in
                switch pain {
                case let .before(kind, level):
                    String(localized: "\(kind.spokenName) was \(level.value) of 10")
                case let .after(kind, level):
                    String(localized: "\(kind.spokenName) \(level.value) after")
                case let .beforeAndAfter(kind, before, after):
                    String(localized: "\(kind.spokenName) \(before.value) before, \(after.value) after")
                }
            }
        )
    }
}

private extension EntryKind {
    var subtitleWord: String {
        switch self {
        case .pain: String(localized: "pain")
        case .stiffness: String(localized: "stiffness")
        case .fatigue: String(localized: "fatigue")
        }
    }

    var spokenName: String {
        String(localized: displayName)
    }
}
