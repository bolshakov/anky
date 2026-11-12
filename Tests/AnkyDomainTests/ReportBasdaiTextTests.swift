// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct ReportBasdaiTextTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    private let english = Locale(identifier: "en_GB")

    private func row(answers: [Int], locale: Locale? = nil) throws -> ReportBasdaiRowText {
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 9, hour: 8)))
        return ReportBasdaiRowText(
            madeUpBasdai(date: date, answers: answers), locale: locale ?? english, calendar: calendar
        )
    }

    @Test func theRowWritesTheDateOutInFull() throws {
        #expect(try row(answers: [4, 6, 5, 3, 7, 2]).date == "9 November 2026")
    }

    @Test func theRowShowsTheSixStoredAnswersInOrder() throws {
        #expect(try row(answers: [8, 7, 9, 6, 5, 10]).answers == ["8", "7", "9", "6", "5", "10"])
    }

    @Test func theRowScoreIsTheListsScoreText() throws {
        let answers = [4, 6, 5, 3, 7, 2]
        let result = try #require(BasdaiResult(id: UUID(), date: .now, answers: answers))
        for locale in [english, Locale(identifier: "ru_RU")] {
            #expect(try row(answers: answers, locale: locale).score == BasdaiScore.text(of: result, locale: locale))
        }
        #expect(try row(answers: answers).score == "4.5")
    }

    @Test func aResultWithEveryAnswerZeroShowsTheScoreZeroPointZero() throws {
        #expect(try row(answers: [0, 0, 0, 0, 0, 0]).score == "0.0")
    }

    @Test func aResultWithEveryAnswerTenShowsTheTopScore() throws {
        #expect(try row(answers: [10, 10, 10, 10, 10, 10]).score == "10.0")
    }

    @Test func theKeyNamesTheSixQuestionsTheFormulaAndTheCitation() throws {
        let key = try CompiledCatalog.withBundle("en") { ReportBasdaiKey.text(locale: english, bundle: $0) }
        #expect(key == """
        Q1 fatigue, Q2 spinal pain, Q3 joint pain, Q4 tenderness, Q5 stiffness severity, Q6 stiffness duration. \
        Each answer is 0 to 10; score = (Q1 + Q2 + Q3 + Q4 + (Q5 + Q6) / 2) / 5. \
        Bath Ankylosing Spondylitis Disease Activity Index (Garrett et al., J Rheumatol 1994).
        """)
    }

    @Test func theKeyHoldsNoVerdictOrThreshold() throws {
        let key = try CompiledCatalog.withBundle("en") { ReportBasdaiKey.text(locale: english, bundle: $0) }
        for word in ["active", "remission", "high", "low", "good", "poor", "≥", "<", ">"] {
            #expect(!key.localizedCaseInsensitiveContains(word), "\(word) reads as an interpretation")
        }
    }
}
