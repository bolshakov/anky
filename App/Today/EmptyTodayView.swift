// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct EmptyTodayView: View {
    var body: some View {
        VStack(spacing: Spacing.emptyStateGap) {
            Image("AnkyMark")
                .resizable()
                .scaledToFit()
                .frame(width: Spacing.emptyMarkWidth)
                .foregroundStyle(Color("AccentColor"))
                .accessibilityHidden(true)

            Text("Nothing logged today")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("empty-today")

            Text("Log how you feel, or a medication you took. Everything stays on this iPhone.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Spacing.emptyStateInset)
        .fixedSize(horizontal: false, vertical: true)
    }
}
