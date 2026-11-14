// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

extension View {
    func discardConfirmation(hasChanges: Bool, cancelID: String, close: @escaping () -> Void) -> some View {
        modifier(DiscardConfirmation(hasChanges: hasChanges, cancelID: cancelID, close: close))
    }
}

private struct DiscardConfirmation: ViewModifier {
    let hasChanges: Bool
    let cancelID: String
    let close: () -> Void
    @State private var isAsking = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    cancelButton
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("\(cancelID)-item")
                }
            }
            .interactiveDismissDisabled(hasChanges)
    }

    private var cancelButton: some View {
        Button("Cancel", action: cancel)
            .frame(minHeight: Spacing.tapTarget)
            .contentShape(Rectangle())
            .accessibilityIdentifier(cancelID)
            .confirmationDialog(Text(verbatim: ""), isPresented: $isAsking, titleVisibility: .hidden) {
                Button("Discard Changes", role: .destructive, action: close)
                    .accessibilityIdentifier("discard-changes")
            } message: {
                Text("Are you sure you want to discard your changes?")
            }
    }

    private func cancel() {
        if hasChanges {
            isAsking = true
        } else {
            close()
        }
    }
}
