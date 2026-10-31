// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct EmptyTodayView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image("AnkyMark")
                .resizable()
                .scaledToFit()
                .frame(width: 120)
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
        .padding(.horizontal, 32)
    }
}
