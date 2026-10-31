// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct RecentChipButtonStyle: ButtonStyle {
    var fillsWidth = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color("OnSoftAccent"))
            .multilineTextAlignment(.leading)
            .padding(.horizontal, fillsWidth ? 16 : 14)
            .padding(.vertical, 10)
            .frame(minHeight: 44)
            .frame(maxWidth: fillsWidth ? .infinity : nil, alignment: .leading)
            .background(Color("SoftAccent"), in: Capsule())
            .contentShape(Capsule())
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.95 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}
