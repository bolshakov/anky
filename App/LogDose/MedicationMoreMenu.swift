// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct MedicationMoreMenu: View {
    let isArchived: Bool
    let onArchive: () -> Void
    let onRestore: () -> Void

    var body: some View {
        Menu {
            if isArchived {
                Button("Restore medication", systemImage: "arrow.counterclockwise", action: onRestore)
                    .accessibilityIdentifier("medication-restore")
            } else {
                Button("Archive medication", systemImage: "archivebox", action: onArchive)
                    .accessibilityIdentifier("medication-archive")
            }
        } label: {
            Label("More actions", systemImage: "ellipsis")
        }
        .accessibilityIdentifier("medication-more")
    }
}
