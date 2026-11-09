// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct RecentChipsRow: View {
    let recents: [RecentEntry]
    let onSelect: (RecentEntry) -> Void
    @State private var taps = 0
    @ScaledMetric(relativeTo: .body) private var chipHeight = Spacing.recentRowHeight

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Spacing.inlineGap) {
                ForEach(Array(recents.enumerated()), id: \.offset) { index, recent in
                    chip(recent, index: index)
                }
            }
        }
        .scrollIndicators(.hidden)
        .sensoryFeedback(.selection, trigger: taps)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("recent-chips")
    }

    private func chip(_ recent: RecentEntry, index: Int) -> some View {
        Button {
            onSelect(recent)
            taps += 1
        } label: {
            Text(recent.chipText(namesKind: false))
                .font(.subheadline)
                .lineLimit(1)
                .fixedSize()
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .frame(height: chipHeight)
        .accessibilityLabel(RecentEntryText.sameAsLastTime + ", " + recent.spokenText(namesKind: false))
        .accessibilityIdentifier("recent-chip-\(index)")
    }
}
