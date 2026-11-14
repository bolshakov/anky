// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain

extension BasdaiRowWords {
    static var app: BasdaiRowWords {
        BasdaiRowWords(
            detail: String(localized: "Covers last week"),
            spoken: { score, time in String(localized: "BASDAI, score \(score), at \(time), covers last week") }
        )
    }
}
