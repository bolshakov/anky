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

    @ViewBuilder
    func body(content: Content) -> some View {
        if isEnabled {
            content.foregroundStyle(Color.onTint)
        } else {
            content
        }
    }
}

extension View {
    /// `isEnabled` dims the button alone, since `.disabled` on this modifier would disable the screen it sits on.
    func bottomPrimaryButton(
        _ title: Text,
        id: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        safeAreaInset(edge: .bottom) {
            Button(action: action) {
                title.frame(maxWidth: .infinity, minHeight: Spacing.primaryButtonLabelHeight)
            }
            .primaryButton()
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .disabled(!isEnabled)
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.bottom, Spacing.bottomClearance)
            .accessibilityIdentifier(id)
        }
    }
}
