// SPDX-License-Identifier: GPL-3.0-or-later
@testable import AnkyDomain
import Foundation
import Testing

private let english = Locale(identifier: "en_GB")

struct BasdaiScoreTests {
    @Test(arguments: [([0, 0, 0, 0, 0, 0], "0.0"),
                      ([10, 10, 10, 10, 10, 10], "10.0"),
                      ([1, 0, 0, 0, 1, 0], "0.3"),
                      ([4, 6, 3, 5, 7, 4], "4.7")])
    func sixAnswersGiveTheScore(_ answers: [Int], _ score: String) {
        #expect(BasdaiScore.text(tenths: BasdaiScore.tenths(answers), locale: english) == score)
    }

    @Test func questionsOneToFourWeighTwiceQuestionsFiveAndSix() {
        #expect(BasdaiScore.tenths([1, 0, 0, 0, 0, 0]) == 2)
        #expect(BasdaiScore.tenths([0, 0, 0, 1, 0, 0]) == 2)
        #expect(BasdaiScore.tenths([0, 0, 0, 0, 1, 0]) == 1)
        #expect(BasdaiScore.tenths([0, 0, 0, 0, 0, 1]) == 1)
    }

    @Test func tenthsReadWithOneDecimal() {
        #expect(BasdaiScore.text(tenths: 35, locale: english) == "3.5")
        #expect(BasdaiScore.text(tenths: 40, locale: english) == "4.0")
    }

    @Test func aRussianScoreUsesADecimalComma() {
        #expect(BasdaiScore.text(tenths: 47, locale: Locale(identifier: "ru")) == "4,7")
    }

    @Test func theScoreFormatRoundsHalfUp() {
        #expect(1.25.formatted(BasdaiScore.style(locale: english)) == "1.3")
        #expect(2.25.formatted(BasdaiScore.style(locale: english)) == "2.3")
    }
}
