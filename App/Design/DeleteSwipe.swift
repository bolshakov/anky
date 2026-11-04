// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

extension View {
    func deleteSwipe(onDelete: @escaping () -> Void) -> some View {
        swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
                .accessibilityIdentifier("history-delete")
        }
    }
}
