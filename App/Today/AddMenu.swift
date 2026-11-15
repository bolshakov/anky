// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct AddMenu: View {
    let actions: [AddAction]
    let onSelect: (AddDestination) -> Void

    var body: some View {
        Menu {
            ForEach(actions) { action in
                Button { onSelect(action.destination) } label: {
                    Label(action.title, systemImage: action.symbol)
                }
                .accessibilityIdentifier(action.id)
            }
        } label: {
            Label("Add", systemImage: "plus")
                .labelStyle(.iconOnly)
                .dynamicTypeSize(.large)
                .frame(width: Spacing.addButtonLabelSide, height: Spacing.addButtonLabelSide)
        }
        .menuOrder(.fixed)
        .primaryButton()
        .buttonBorderShape(.circle)
        .accessibilityIdentifier("add-menu")
    }
}
