// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct MedicationsEmptyBlock: View {
    var body: some View {
        VStack(spacing: Spacing.emptyStateIconGap) {
            Image(systemName: "pills")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            VStack(spacing: Spacing.emptyStateTextGap) {
                Text("No medications yet")
                    .font(.title2.weight(.semibold))
                Text("Add what you take, then log a dose in two taps. Everything stays on this iPhone.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.emptyStateInset)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("medications-empty")
    }
}
