// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct BasdaiResultTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func result(_ answers: [Int]) -> BasdaiResult? {
        BasdaiResult(id: UUID(), date: date, answers: answers)
    }

    @Test func sixAnswersFromZeroToTenMakeAResult() throws {
        let made = try #require(result([0, 10, 3, 4, 5, 6]))
        #expect(made.answers == [0, 10, 3, 4, 5, 6])
        #expect([made.date, made.createdAt, made.updatedAt] == [date, date, date])
    }

    @Test(arguments: [[1, 2, 3, 4, 5], [1, 2, 3, 4, 5, 6, 7], []])
    func aCountOtherThanSixMakesNoResult(_ answers: [Int]) {
        #expect(result(answers) == nil)
    }

    @Test(arguments: [-1, 11])
    func anAnswerOutsideZeroToTenMakesNoResult(_ value: Int) {
        #expect(result([5, 5, 5, value, 5, 5]) == nil)
    }

    @Test func theScoreTextComesFromTheSixAnswers() throws {
        let made = try #require(result([4, 5, 6, 7, 3, 8]))
        #expect(BasdaiScore.text(of: made, locale: Locale(identifier: "en")) == "5.5")
        #expect(BasdaiScore.text(of: made, locale: Locale(identifier: "ru")) == "5,5")
    }
}
