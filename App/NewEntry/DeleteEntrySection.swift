// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI
import UIKit

struct DeleteWords {
    let message: LocalizedStringKey
    let button: LocalizedStringKey
    let failure: LocalizedStringKey
    var offersRetry = false
    let announcement: LocalizedStringResource

    static var entry: DeleteWords {
        DeleteWords(
            message: "Delete this entry? This can't be undone.",
            button: "Delete entry",
            failure: "Couldn't delete this entry. Try again.",
            announcement: "Entry deleted"
        )
    }

    static var dose: DeleteWords {
        DeleteWords(
            message: "Delete this dose? This can't be undone.",
            button: "Delete dose",
            failure: "Couldn't delete this dose. Try again.",
            announcement: "Dose deleted"
        )
    }

    static var basdai: DeleteWords {
        DeleteWords(
            message: "Delete this result? This can't be undone.",
            button: "Delete result",
            failure: "Couldn't delete this result. Try again.",
            announcement: "Result deleted"
        )
    }

    static var allData: DeleteWords {
        DeleteWords(
            message: "Erase every entry, dose, medication and BASDAI result on this iPhone? This can't be undone.",
            button: "Erase",
            failure: "Something went wrong while erasing your data. Try again.",
            offersRetry: true,
            announcement: "All data erased"
        )
    }
}

extension View {
    func entryDeleteConfirmation(
        isPresented: Binding<Bool>,
        words: DeleteWords = .entry,
        onDelete: @escaping () async throws -> Void
    ) -> some View {
        modifier(EntryDeleteConfirmation(isPresented: isPresented, words: words, onDelete: onDelete))
    }
}

private struct EntryDeleteConfirmation: ViewModifier {
    @Binding var isPresented: Bool
    let words: DeleteWords
    let onDelete: () async throws -> Void
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
            .alert(words.failure, isPresented: $isShowingDeleteFailure) {
                if words.offersRetry {
                    Button("Retry") {
                        delete()
                    }
                    .accessibilityIdentifier("retry-erase")
                    Button("Cancel", role: .cancel) {}
                } else {
                    Button("OK") {}
                }
            }
    }

    private func delete() {
        Task {
            do {
                try await onDelete()
                UIAccessibility.post(notification: .announcement, argument: String(localized: words.announcement))
            } catch {
                isShowingDeleteFailure = true
            }
        }
    }
}
