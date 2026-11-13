// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// One row of the report's BASDAI table. The score is the one the BASDAI list shows.
public struct ReportBasdaiRowText: Equatable, Sendable {
    public let date: String
    public let answers: [String]
    public let score: String

    public init(_ result: BasdaiResult, locale: Locale, calendar: Calendar) {
        date = BasdaiDateText.text(for: result.date, calendar: calendar, locale: locale)
        answers = result.answers.map { $0.formatted(.number.locale(locale)) }
        score = BasdaiScore.text(of: result, locale: locale)
    }
}

/// The line under the table that tells a reader what Q1 to Q6 are and how the score is made.
public enum ReportBasdaiKey {
    public static func text(locale: Locale, bundle: Bundle) -> String {
        let names = BasdaiQuestion.questions(bundle: bundle, locale: locale)
            .map { question in
                let name = question.shortName.lowercased(with: locale)
                return String(localized: "Q\(question.number) \(name)", bundle: bundle, locale: locale)
            }
            .joined(separator: ", ")
        return String(
            localized: """
            \(names). Each answer is 0 to 10; score = (Q1 + Q2 + Q3 + Q4 + (Q5 + Q6) / 2) / 5. \
            Bath Ankylosing Spondylitis Disease Activity Index (Garrett et al., J Rheumatol 1994).
            """,
            bundle: bundle, locale: locale
        )
    }
}
