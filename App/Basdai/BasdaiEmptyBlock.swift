// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct BasdaiEmptyBlock: View {
    var body: some View {
        VStack(spacing: Spacing.emptyStateIconGap) {
            Image(systemName: "chart.bar")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            VStack(spacing: Spacing.emptyStateTextGap) {
                Text("No BASDAI results yet")
                    .font(.title2.weight(.semibold))
                Text("""
                BASDAI is six questions about the last week, each answered from 0 to 10. It takes about a minute. \
                Saved results are listed here with their date.
                """)
                .font(.callout)
                .foregroundStyle(.secondary)
                Text("Bath Ankylosing Spondylitis Disease Activity Index (Garrett et al., J Rheumatol 1994).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.emptyStateInset)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("basdai-empty")
    }
}
