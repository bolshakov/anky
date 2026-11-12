// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI
import UIKit

struct DeleteWords {
    let message: LocalizedStringKey
    let button: LocalizedStringKey
    let failure: LocalizedStringKey
    var partialFailures: [PartialDelete.Kept: LocalizedStringKey] = [:]
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
        let medicationsKept: LocalizedStringKey = """
        Your entries were erased, but your medications, doses and BASDAI results were not. \
        Try again to erase the rest.
        """
        let basdaiKept: LocalizedStringKey = """
        Your entries, doses and medications were erased, but your BASDAI results were not. \
        Try again to erase the rest.
        """
        return DeleteWords(
            message: "Erase every entry, dose, medication and BASDAI result on this iPhone? This can't be undone.",
            button: "Erase",
            failure: "Couldn't erase your data. Try again.",
            partialFailures: [.medicationsAndBasdai: medicationsKept, .basdai: basdaiKept],
            announcement: "All data erased"
        )
    }
}

/// Thrown by a delete action that finished some of its work. The person sees the `DeleteWords.partialFailures` text
/// for what was kept, with no announcement.
struct PartialDelete: Error {
    enum Kept {
        case medicationsAndBasdai
        case basdai
    }

    let kept: Kept
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
    @State private var isShowingPartialFailure = false
    @State private var partialFailure: LocalizedStringKey = ""

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
                Button("OK") {}
            }
            .alert(partialFailure, isPresented: $isShowingPartialFailure) {
                Button("OK") {}
            }
    }

    private func delete() {
        do {
            try onDelete()
            UIAccessibility.post(notification: .announcement, argument: String(localized: words.announcement))
        } catch let partial as PartialDelete {
            partialFailure = words.partialFailures[partial.kept] ?? words.failure
            isShowingPartialFailure = true
        } catch {
            isShowingDeleteFailure = true
        }
    }
}
