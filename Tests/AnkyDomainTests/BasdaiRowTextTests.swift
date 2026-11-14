// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct BasdaiRowTextTests {
    private let calendar: Calendar
    private let moment: Date
    private let english = Locale(identifier: "en_US")
    private let german = Locale(identifier: "de_DE")

    private let words = BasdaiRowWords(detail: "Covers last week") { score, time in
        "BASDAI, score \(score), at \(time), covers last week"
    }

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Pacific/Auckland"))
        self.calendar = calendar
        moment = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 28, hour: 20, minute: 1)))
    }

    private func result(_ answers: [Int]) throws -> BasdaiResult {
        try #require(BasdaiResult(id: UUID(), date: moment, answers: answers))
    }

    @Test func theSecondLineHoldsTheTimeAndTheDetail() throws {
        let line = try BasdaiRowText.secondLine(
            for: result([3, 3, 3, 3, 3, 3]),
            words: words,
            calendar: calendar,
            locale: german
        )
        #expect(line == "20:01 · Covers last week")
    }

    @Test func theSecondLineTakesTheTimeInThePersonsClock() throws {
        let line = try BasdaiRowText.secondLine(
            for: result([3, 3, 3, 3, 3, 3]),
            words: words,
            calendar: calendar,
            locale: english
        )
        #expect(line == RowSecondLine.text(
            time: ClockText.text(for: moment, calendar: calendar, locale: english), detail: "Covers last week"
        ))
        #expect(line.hasPrefix("8:01"))
    }

    @Test func theScoreHasOneDecimal() throws {
        #expect(try BasdaiRowText.score(of: result([3, 3, 3, 3, 3, 3]), locale: english) == "3.0")
        #expect(try BasdaiRowText.score(of: result([7, 7, 6, 6, 7, 6]), locale: english) == "6.5")
        #expect(try BasdaiRowText.score(of: result([0, 0, 0, 0, 0, 0]), locale: english) == "0.0")
        #expect(try BasdaiRowText.score(of: result([10, 10, 10, 10, 10, 10]), locale: english) == "10.0")
    }

    @Test func theSpokenLabelNamesTheScoreAndTheTime() throws {
        let label = try BasdaiRowText.spokenLabel(
            for: result([3, 3, 3, 3, 3, 3]), words: words, calendar: calendar, locale: german
        )
        #expect(label == "BASDAI, score 3,0, at 20:01, covers last week")
    }

    @Test func aRegionThatWritesDecimalsWithACommaShowsAndSpeaksTheScoreWithAComma() throws {
        let saved = try result([3, 3, 3, 3, 3, 3])
        #expect(BasdaiRowText.score(of: saved, locale: german) == "3,0")
        #expect(BasdaiRowText.spokenLabel(for: saved, words: words, calendar: calendar, locale: german)
            .contains("score 3,0,"))
    }

    @Test func twoResultsOfOneMinuteReadTheSameTime() throws {
        let later = try #require(BasdaiResult(
            id: UUID(), date: moment.addingTimeInterval(30), answers: [3, 3, 3, 3, 3, 3]
        ))
        let earlier = try result([3, 3, 3, 3, 3, 3])
        #expect(
            BasdaiRowText.secondLine(for: later, words: words, calendar: calendar, locale: german)
                == BasdaiRowText.secondLine(for: earlier, words: words, calendar: calendar, locale: german)
        )
    }
}
