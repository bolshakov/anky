// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct EntryMoreMenu: View {
    let onDelete: () -> Void

    var body: some View {
        Menu {
            Button("Delete entry", systemImage: "trash", role: .destructive, action: onDelete)
                .accessibilityIdentifier("delete-entry")
        } label: {
            Label("More", systemImage: "ellipsis")
        }
        .accessibilityIdentifier("entry-more")
    }
}
