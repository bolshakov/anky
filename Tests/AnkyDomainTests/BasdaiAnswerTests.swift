// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Testing

struct BasdaiAnswerTests {
    @Test func anUnansweredQuestionHasNoValue() {
        #expect(BasdaiAnswer.unanswered.value == nil)
    }

    @Test(arguments: [0, 4, 10])
    func anAnsweredQuestionHoldsItsValue(value: Int) {
        #expect(BasdaiAnswer.answered(value).value == value)
    }

    @Test func incrementFromUnansweredAnswersOne() {
        #expect(BasdaiAnswer.unanswered.incremented() == .answered(1))
    }

    @Test func decrementFromUnansweredAnswersZero() {
        #expect(BasdaiAnswer.unanswered.decremented() == .answered(0))
    }

    @Test func adjustMovesAnAnswerOneStep() {
        #expect(BasdaiAnswer.answered(4).incremented() == .answered(5))
        #expect(BasdaiAnswer.answered(4).decremented() == .answered(3))
    }

    @Test func adjustStopsAtTheEnds() {
        #expect(BasdaiAnswer.answered(10).incremented() == .answered(10))
        #expect(BasdaiAnswer.answered(0).decremented() == .answered(0))
    }
}
