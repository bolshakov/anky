// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct DeleteEntrySection: View {
    let onDelete: () throws -> Void
    @State private var isConfirming = false

    var body: some View {
        Button(role: .destructive) {
            isConfirming = true
        } label: {
            Text("Delete entry")
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.red)
        .accessibilityIdentifier("delete-entry")
        .entryDeleteConfirmation(isPresented: $isConfirming, onDelete: onDelete)
    }
}

struct DeleteWords {
    let message: LocalizedStringKey
    let button: LocalizedStringKey
    let failure: LocalizedStringKey

    static var entry: DeleteWords {
        DeleteWords(
            message: "Delete this entry? This can't be undone.",
            button: "Delete entry",
            failure: "This entry could not be deleted."
        )
    }

    static var dose: DeleteWords {
        DeleteWords(
            message: "Delete this dose? This can't be undone.",
            button: "Delete dose",
            failure: "This dose could not be deleted."
        )
    }
}

extension View {
    func entryDeleteConfirmation(
        isPresented: Binding<Bool>,
        words: DeleteWords = .entry,
        onDelete: @escaping () throws -> Void
    ) -> some View {
        modifier(EntryDeleteConfirmation(isPresented: isPresented, words: words, onDelete: onDelete))
    }
}

private struct EntryDeleteConfirmation: ViewModifier {
    @Binding var isPresented: Bool
    let words: DeleteWords
    let onDelete: () throws -> Void
    @State private var isShowingDeleteFailure = false

    func body(content: Content) -> some View {
        content
            .background {
                Color.clear
                    .frame(width: 0, height: 0)
                    // An alert keeps a Cancel button. A confirmation dialog drew without one on iOS 26.5.
                    .alert(words.message, isPresented: $isPresented) {
                        Button(words.button, role: .destructive) {
                            delete()
                        }
                        .accessibilityIdentifier("confirm-delete")
                        Button("Cancel", role: .cancel) {}
                            .accessibilityIdentifier("keep-entry")
                    }
                    .tint(.primary)
            }
            .sensoryFeedback(trigger: isPresented) { _, isNow in isNow ? .warning : nil }
            .alert(words.failure, isPresented: $isShowingDeleteFailure) {
                Button("OK") {}
            }
    }

    private func delete() {
        do {
            try onDelete()
        } catch {
            isShowingDeleteFailure = true
        }
    }
}
