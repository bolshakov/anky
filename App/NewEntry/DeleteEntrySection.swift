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

extension View {
    func entryDeleteConfirmation(isPresented: Binding<Bool>, onDelete: @escaping () throws -> Void) -> some View {
        modifier(EntryDeleteConfirmation(isPresented: isPresented, onDelete: onDelete))
    }
}

private struct EntryDeleteConfirmation: ViewModifier {
    @Binding var isPresented: Bool
    let onDelete: () throws -> Void
    @State private var isShowingDeleteFailure = false

    func body(content: Content) -> some View {
        content
            // An alert keeps a Cancel button. A confirmation dialog drew without one on iOS 26.5.
            .alert("Delete this entry? This can't be undone.", isPresented: $isPresented) {
                Button("Delete entry", role: .destructive) {
                    delete()
                }
                .accessibilityIdentifier("confirm-delete")
                Button("Cancel", role: .cancel) {}
                    .accessibilityIdentifier("keep-entry")
            }
            .sensoryFeedback(trigger: isPresented) { _, isNow in isNow ? .warning : nil }
            .alert("This entry could not be deleted.", isPresented: $isShowingDeleteFailure) {
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
