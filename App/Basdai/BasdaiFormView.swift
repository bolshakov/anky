// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct BasdaiFormView: View {
    let onSave: ([Int]) throws -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var answers = [BasdaiAnswer](repeating: .unanswered, count: BasdaiQuestion.all.count)
    @State private var isShowingSaveFailure = false
    @State private var isConfirmingDiscard = false
    @AccessibilityFocusState private var focus: BasdaiFormFocus?

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
                        .accessibilityFocused($focus, equals: .intro)
                        .nonCardBlock()
                }
                ForEach(BasdaiQuestion.all, id: \.number) { question in
                    BasdaiQuestionBlock(question: question, answer: $answers[question.number - 1])
                }
                CardSection(footnote: citation, id: "basdai-end", footnoteID: "basdai-citation") {}
            }
            .screenSpacing()
            .accessibilityIdentifier("basdai-form")
            .onAppear { focus = .intro }
            .navigationTitle("BASDAI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Group {
                        Button("Cancel", action: cancel)
                            .frame(minHeight: Spacing.rowMinimumHeight)
                            .contentShape(Rectangle())
                            .accessibilityIdentifier("basdai-cancel")
                            .accessibilityFocused($focus, equals: .cancel)
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
                    focus = .cancel
                }
            }
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

private enum BasdaiFormFocus: Hashable {
    case intro
    case cancel
}
