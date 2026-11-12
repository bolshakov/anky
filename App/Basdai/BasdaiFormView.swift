// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct BasdaiFormView: View {
    let onSave: ([Int]) throws -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var answers = [BasdaiAnswer](repeating: .unanswered, count: BasdaiQuestion.all.count)
    @State private var isShowingSaveFailure = false
    @State private var isConfirmingDiscard = false
    @AccessibilityFocusState private var isLabelFocused: Bool
    @AccessibilityFocusState private var isCancelFocused: Bool

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
                CardSection(footnote: citation, id: "basdai-end", footnoteID: "basdai-citation") {}
            }
            .screenSpacing()
            .accessibilityIdentifier("basdai-form")
            .onAppear { isLabelFocused = true }
            .navigationTitle("BASDAI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Group {
                        Button("Cancel", action: cancel)
                            .frame(minHeight: Spacing.rowMinimumHeight)
                            .contentShape(Rectangle())
                            .accessibilityIdentifier("basdai-cancel")
                            .accessibilityFocused($isCancelFocused)
                            .confirmationDialog(
                                "Discard answers?",
                                isPresented: $isConfirmingDiscard,
                                titleVisibility: .visible
                            ) {
                                discardButtons
                            }
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("basdai-cancel-item")
                }
            }
            .bottomPrimaryButton(Text("Save"), id: "basdai-save", isEnabled: isComplete, action: save)
            .alert("Couldn't save this result. Try again.", isPresented: $isShowingSaveFailure) {
                Button("OK") {}
            }
            .background {
                BasdaiDismissGuard { isConfirmingDiscard = true }
                    .accessibilityHidden(true)
            }
            .interactiveDismissDisabled(isAnyAnswered)
            .onChange(of: isConfirmingDiscard) { _, isShowing in
                if !isShowing {
                    isCancelFocused = true
                }
            }
        }
    }

    private func questionSection(_ question: BasdaiQuestion) -> some View {
        let isFirst = question.number == 1
        return CardSection(
            isFirst ? Text("Last week") : nil,
            id: "basdai-q\(question.number)",
            labelID: "basdai-intro",
            labelFocus: $isLabelFocused
        ) {
            BasdaiQuestionBlock(question: question, answer: $answers[question.number - 1])
        }
    }

    @ViewBuilder
    private var discardButtons: some View {
        Button("Discard", role: .destructive) { dismiss() }
            .accessibilityIdentifier("basdai-discard")
        // A cancel role drops the button from a confirmation dialog on iOS 26.5.
        Button("Keep Editing") {}
            .accessibilityIdentifier("basdai-keep-editing")
    }

    private func cancel() {
        if isAnyAnswered {
            isConfirmingDiscard = true
        } else {
            dismiss()
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
