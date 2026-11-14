// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct BasdaiFormView: View {
    let onSave: ([Int]) throws -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var answers = [BasdaiAnswer](repeating: .unanswered, count: BasdaiQuestion.all.count)
    @State private var isShowingSaveFailure = false
    @AccessibilityFocusState private var isLabelFocused: Bool

    var isComplete: Bool {
        answers.isComplete
    }

    var isAnyAnswered: Bool {
        answers.isAnyAnswered
    }

    var body: some View {
        NavigationStack {
            Form {
                ForEach(BasdaiQuestion.all, id: \.number) { question in
                    questionSection(question)
                }
            }
            .screenSpacing()
            .accessibilityIdentifier("basdai-form")
            .onAppear { isLabelFocused = true }
            .navigationTitle("BASDAI")
            .navigationBarTitleDisplayMode(.inline)
            .discardConfirmation(
                hasChanges: isAnyAnswered,
                cancelID: "basdai-cancel",
                close: { dismiss() }
            )
            .bottomPrimaryButton(Text("Save"), id: "basdai-save", isEnabled: isComplete, action: save)
            .alert("Couldn't save this result. Try again.", isPresented: $isShowingSaveFailure) {
                Button("OK") {}
            }
        }
    }

    private func questionSection(_ question: BasdaiQuestion) -> some View {
        let isFirst = question.number == 1
        let isLast = question.number == BasdaiQuestion.all.count
        return CardSection(
            isFirst ? Text("Last week") : nil,
            footnote: isLast ? citation : nil,
            id: "basdai-q\(question.number)",
            labelID: "basdai-intro",
            footnoteID: "basdai-citation",
            labelFocus: $isLabelFocused
        ) {
            BasdaiQuestionBlock(question: question, answer: $answers[question.number - 1])
        }
    }

    private var citation: Text {
        Text("Garrett S, et al. J Rheumatol 1994;21(12):2286-91.")
    }

    private func save() {
        guard let values = answers.completeValues else { return }
        do {
            try onSave(values)
            dismiss()
        } catch {
            isShowingSaveFailure = true
        }
    }
}
