// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

extension View {
    /// The prominent style sets its label to white on the accent, so the label colour is set here with it.
    func primaryButton() -> some View {
        buttonStyle(.glassProminent)
            .foregroundStyle(Color.onTint)
    }
}

extension View {
    func bottomPrimaryButton(_ title: Text, id: String, action: @escaping () -> Void) -> some View {
        safeAreaInset(edge: .bottom) {
            Button(action: action) {
                title.frame(maxWidth: .infinity, minHeight: Spacing.primaryButtonLabelHeight)
            }
            .primaryButton()
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .padding(.horizontal, Spacing.screenMargin)
            .padding(.bottom, Spacing.bottomClearance)
            .accessibilityIdentifier(id)
        }
    }
}
