// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct DoseMoreMenu: View {
    let onDelete: () -> Void

    var body: some View {
        Menu {
            Button("Delete dose", systemImage: "trash", role: .destructive, action: onDelete)
                .accessibilityIdentifier("delete-dose")
        } label: {
            Label("More actions", systemImage: "ellipsis")
        }
        .accessibilityIdentifier("dose-more")
    }
}
