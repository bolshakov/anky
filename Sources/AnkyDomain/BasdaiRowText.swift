// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// The words a BASDAI row is built from. The app supplies localized ones: the detail under the title, and the spoken
/// label as one whole phrase around the score and the time.
public struct BasdaiRowWords {
    public let detail: String
    public let spoken: (_ score: String, _ time: String) -> String

    public init(detail: String, spoken: @escaping (_ score: String, _ time: String) -> String) {
        self.detail = detail
        self.spoken = spoken
    }
}

public enum BasdaiRowText {
    public static func score(of result: BasdaiResult, locale: Locale) -> String {
        BasdaiScore.text(tenths: BasdaiScore.tenths(result.answers), locale: locale)
    }

    public static func secondLine(
        for result: BasdaiResult, words: BasdaiRowWords, calendar: Calendar, locale: Locale
    ) -> String {
        RowSecondLine.text(time: time(of: result, calendar: calendar, locale: locale), detail: words.detail)
    }

    public static func spokenLabel(
        for result: BasdaiResult, words: BasdaiRowWords, calendar: Calendar, locale: Locale
    ) -> String {
        words.spoken(score(of: result, locale: locale), time(of: result, calendar: calendar, locale: locale))
    }

    private static func time(of result: BasdaiResult, calendar: Calendar, locale: Locale) -> String {
        ClockText.text(for: result.date, calendar: calendar, locale: locale)
    }
}
