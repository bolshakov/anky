import SwiftUI

struct DeleteEntrySection: View {
    let onDelete: () throws -> Void
    @State private var isConfirming = false
    @State private var isShowingDeleteFailure = false

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
        // An alert keeps a Cancel button; a confirmation dialog drew without one on iOS 26.5.
        .alert("Delete this entry? This can't be undone.", isPresented: $isConfirming) {
            Button("Delete entry", role: .destructive) {
                delete()
            }
            .accessibilityIdentifier("confirm-delete")
            Button("Cancel", role: .cancel) {}
                .accessibilityIdentifier("keep-entry")
        }
        .sensoryFeedback(trigger: isConfirming) { _, isNow in isNow ? .warning : nil }
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
