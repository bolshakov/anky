// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public extension BasdaiScore {
    static func text(of result: BasdaiResult, locale: Locale) -> String {
        text(tenths: tenths(result.answers), locale: locale)
    }
}
