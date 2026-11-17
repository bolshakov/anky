// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

extension View {
    /// The prominent style sets its label to white on the accent, so the label colour is set here with it.
    func primaryButton() -> some View {
        buttonStyle(.glassProminent)
            .modifier(EnabledLabelColor())
    }
}

private struct EnabledLabelColor: ViewModifier {
    @Environment(\.isEnabled) private var isEnabled

    /// The system's own disabled label measured under 2:1 against the dimmed capsule, so a disabled label is `ink`.
    func body(content: Content) -> some View {
        content.foregroundStyle(isEnabled ? Color.onTint : Color.ink)
    }
}
