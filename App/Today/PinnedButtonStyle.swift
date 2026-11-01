// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct PinnedButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color("OnAccent"))
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Color("AccentColor"), in: Capsule())
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(isEnabled ? (configuration.isPressed && reduceMotion ? 0.6 : 1) : 0.35)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
