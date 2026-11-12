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

struct BasdaiAnswerTouchTests {
    @Test func touchingAnUnansweredQuestionAnswersZero() {
        #expect(BasdaiAnswer.unanswered.touched() == .answered(0))
    }

    @Test(arguments: [0, 4, 10])
    func touchingAnAnswerKeepsIt(value: Int) {
        #expect(BasdaiAnswer.answered(value).touched() == .answered(value))
    }

    @Test func slidingAwayAndBackToZeroStaysAnswered() {
        let answer = BasdaiAnswer.unanswered.touched().slid(to: 6).slid(to: 0)

        #expect(answer == .answered(0))
    }

    @Test func slidingAnUnansweredQuestionAnswersIt() {
        #expect(BasdaiAnswer.unanswered.slid(to: 3) == .answered(3))
    }
}

struct BasdaiAnswerSetTests {
    private let five = [BasdaiAnswer](repeating: .answered(2), count: 5)

    @Test func freshAnswersAreNeitherCompleteNorStarted() {
        let fresh = [BasdaiAnswer](repeating: .unanswered, count: 6)

        #expect(!fresh.isComplete)
        #expect(!fresh.isAnyAnswered)
        #expect(fresh.completeValues == nil)
    }

    @Test func oneAnswerStartsButDoesNotComplete() {
        let started = [.answered(0)] + [BasdaiAnswer](repeating: .unanswered, count: 5)

        #expect(started.isAnyAnswered)
        #expect(!started.isComplete)
        #expect(started.completeValues == nil)
    }

    @Test func sixAnswersCompleteWithTheirValuesInOrder() {
        let answers = five + [.answered(0)]

        #expect(answers.isComplete)
        #expect(answers.completeValues == [2, 2, 2, 2, 2, 0])
    }

    @Test func fiveAnswersOfSixDoNotComplete() {
        #expect(!(five + [.unanswered]).isComplete)
    }
}
