// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

private let english = Locale(identifier: "en_GB")

private let wordings = ["How would you describe the overall level of fatigue/tiredness you have experienced?",
                        "How would you describe the overall level of AS **neck, back or hip** pain you have had?",
                        "How would you describe the overall level of pain/swelling in joints **other than** neck, "
                            + "back or hips you have had?",
                        "How would you describe the overall level of discomfort you have had from any areas tender "
                            + "to touch or pressure?",
                        "How would you describe the overall level of morning stiffness you have had from the time "
                            + "you wake up?",
                        "How long does your morning stiffness last from the time you wake up?"]

private let shortNames = ["Fatigue", "Spinal pain", "Joint pain", "Tenderness", "Stiffness severity",
                          "Stiffness duration"]

private let durationTexts = ["0 min", "12 min", "24 min", "36 min", "48 min", "1 hr",
                             "1 hr 12 min", "1 hr 24 min", "1 hr 36 min", "1 hr 48 min", "2 hrs or more"]

private func questions() throws -> [BasdaiQuestion] {
    try CompiledCatalog.withBundle("en") { BasdaiQuestion.questions(bundle: $0, locale: english) }
}

private func marked(_ question: BasdaiQuestion) -> String {
    question.wording.map { $0.isBold ? "**\($0.text)**" : $0.text }.joined()
}

struct BasdaiQuestionTests {
    @Test func theTableHoldsSixQuestionsNumberedOneToSix() {
        #expect(BasdaiQuestion.all.map(\.number) == [1, 2, 3, 4, 5, 6])
    }

    @Test func eachQuestionReadsThePublishedWordingWithItsBoldWords() throws {
        #expect(try questions().map(marked) == wordings)
    }

    @Test func theTextOfAQuestionIsItsWordingWithoutMarks() throws {
        let second = try questions()[1]
        #expect(second.text == "How would you describe the overall level of AS neck, back or hip pain you have had?")
    }

    @Test func eachQuestionHasItsShortName() throws {
        #expect(try questions().map(\.shortName) == shortNames)
    }

    @Test func questionsOneToFiveRunFromNoneToVerySevere() throws {
        for question in try questions().prefix(5) {
            #expect(question.lowLabel == "None")
            #expect(question.highLabel == "Very severe")
            #expect(question.midLabel == nil)
        }
    }

    @Test func questionSixRunsFromNoHoursToTwoOrMoreWithOneHourInTheMiddle() throws {
        let sixth = try questions()[5]
        #expect(sixth.lowLabel == "0 hrs")
        #expect(sixth.midLabel == "1 hr")
        #expect(sixth.highLabel == "2 or more hrs")
    }

    @Test func anUnansweredQuestionIsShownAndSpokenAsNotAnswered() throws {
        try CompiledCatalog.withBundle("en") { en in
            for question in BasdaiQuestion.questions(bundle: en, locale: english) {
                #expect(question.valueText(.unanswered, locale: english, bundle: en) == "Not answered")
                #expect(question.spokenText(.unanswered, locale: english, bundle: en) == "not answered")
            }
        }
    }

    @Test func questionsOneToFiveReadTheirValueOutOfTen() throws {
        try CompiledCatalog.withBundle("en") { en in
            for question in BasdaiQuestion.questions(bundle: en, locale: english).prefix(5) {
                #expect(question.valueText(.answered(4), locale: english, bundle: en) == "4 of 10")
                #expect(question.spokenText(.answered(0), locale: english, bundle: en) == "0 of 10")
            }
        }
    }

    @Test func questionSixReadsTwelveMinutesAStep() throws {
        try CompiledCatalog.withBundle("en") { en in
            let sixth = BasdaiQuestion.questions(bundle: en, locale: english)[5]
            for (step, text) in durationTexts.enumerated() {
                #expect(sixth.valueText(.answered(step), locale: english, bundle: en) == text)
                #expect(sixth.spokenText(.answered(step), locale: english, bundle: en) == text)
            }
        }
    }
}
