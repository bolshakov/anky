// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct DeleteDoseSection: View {
    let onDelete: () throws -> Void
    @State private var isConfirming = false

    var body: some View {
        Button(role: .destructive) {
            isConfirming = true
        } label: {
            Text("Delete dose")
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.red)
        .accessibilityIdentifier("delete-dose")
        .entryDeleteConfirmation(isPresented: $isConfirming, words: .dose, onDelete: onDelete)
    }
}
