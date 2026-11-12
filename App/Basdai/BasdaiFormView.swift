// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct BasdaiFormView: View {
    let onSave: ([Int]) throws -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var answers = [BasdaiAnswer](repeating: .unanswered, count: BasdaiQuestion.all.count)

    var isComplete: Bool {
        answers.isComplete
    }

    var isAnyAnswered: Bool {
        answers.isAnyAnswered
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("All questions refer to **last week**.")
                        .accessibilityIdentifier("basdai-intro")
                        .nonCardBlock()
                }
                ForEach(BasdaiQuestion.all, id: \.number) { question in
                    BasdaiQuestionBlock(question: question, answer: $answers[question.number - 1])
                }
                CardSection(footnote: citation, id: "basdai-end", footnoteID: "basdai-citation") {}
            }
            .screenSpacing()
            .accessibilityIdentifier("basdai-form")
            .navigationTitle("BASDAI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Group {
                        Button("Cancel") { dismiss() }
                            .frame(minHeight: Spacing.rowMinimumHeight)
                            .contentShape(Rectangle())
                            .accessibilityIdentifier("basdai-cancel")
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("basdai-cancel-item")
                }
            }
            .bottomPrimaryButton(Text("Save"), id: "basdai-save", isEnabled: isComplete, action: save)
        }
    }

    private var citation: Text {
        Text("Garrett S, et al. J Rheumatol 1994;21(12):2286-91.")
    }

    private func save() {
        guard let values = answers.completeValues, (try? onSave(values)) != nil else { return }
        dismiss()
    }
}
