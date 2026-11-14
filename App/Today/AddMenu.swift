// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct AddMenu: View {
    let onLogEntry: () -> Void
    let onLogDose: () -> Void
    let onBasdai: () -> Void

    var body: some View {
        Menu {
            Button(action: onLogEntry) {
                Label("Log how you feel", systemImage: "square.and.pencil")
            }
            .accessibilityIdentifier("log-entry")
            Button(action: onLogDose) {
                Label("Log dose", systemImage: RowSymbol.dose)
            }
            .accessibilityIdentifier("log-medication")
            Button(action: onBasdai) {
                Label("BASDAI", systemImage: RowSymbol.basdai)
            }
            .accessibilityIdentifier("add-basdai")
        } label: {
            Label("Add", systemImage: "plus")
                .labelStyle(.iconOnly)
                .dynamicTypeSize(.large)
                .frame(width: Spacing.addButtonLabelSide, height: Spacing.addButtonLabelSide)
        }
        .primaryButton()
        .buttonBorderShape(.circle)
        .accessibilityIdentifier("add-menu")
    }
}
