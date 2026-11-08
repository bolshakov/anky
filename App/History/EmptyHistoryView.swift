// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct EmptyHistoryView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.emptyStateGap) {
                Image(systemName: "clock")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                Text("No entries yet")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("empty-history")

                Text("Entries you add appear here, newest first.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.emptyStateInset)
            .frame(maxWidth: .infinity)
            .padding(.top, Spacing.emptyBlockGap)
        }
    }
}
