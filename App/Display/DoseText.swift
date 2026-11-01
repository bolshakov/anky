// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation

extension DoseWords {
    static var app: DoseWords {
        DoseWords(
            kind: String(localized: "Dose"),
            subtitlePain: { pain in
                switch pain {
                case let .before(level):
                    String(localized: "pain was \(level.value) of 10")
                case let .beforeAndAfter(before, after):
                    String(localized: "pain \(before.value) before, \(after.value) after")
                }
            },
            spokenPain: { pain in
                switch pain {
                case let .before(level):
                    String(localized: "Pain was \(level.value) of 10")
                case let .beforeAndAfter(before, after):
                    String(localized: "Pain \(before.value) before, \(after.value) after")
                }
            }
        )
    }
}
