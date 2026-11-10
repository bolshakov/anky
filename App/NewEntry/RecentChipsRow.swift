// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct RecentChipsRow: View {
    let recents: [RecentEntry]
    let onSelect: (RecentEntry) -> Void
    @State private var taps = 0
    @State private var rowWidth = CGFloat.infinity
    @ScaledMetric(relativeTo: .body) private var chipHeight = Spacing.recentRowHeight

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Spacing.inlineGap) {
                ForEach(Array(recents.enumerated()), id: \.offset) { index, recent in
                    chip(recent, index: index)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .scrollIndicators(.hidden)
        .onGeometryChange(for: CGFloat.self, of: { $0.size.width }, action: { rowWidth = $0 })
        .sensoryFeedback(.selection, trigger: taps)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("recent-chips")
    }

    private func chip(_ recent: RecentEntry, index: Int) -> some View {
        WidthCap(limit: rowWidth) {
            Button {
                onSelect(recent)
                taps += 1
            } label: {
                Text(recent.chipText(namesKind: false))
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
        }
        .frame(minHeight: chipHeight)
        .minimumTapTarget()
        .accessibilityLabel(RecentEntryText.sameAsLastTime + ", " + recent.spokenText(namesKind: false))
        .accessibilityIdentifier("recent-chip-\(index)")
    }
}

private struct WidthCap: Layout {
    let limit: CGFloat

    func sizeThatFits(proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let ideal = subviews[0].sizeThatFits(.unspecified)
        guard ideal.width > limit else { return ideal }
        return subviews[0].sizeThatFits(ProposedViewSize(width: limit, height: nil))
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        subviews[0].place(at: bounds.origin, proposal: ProposedViewSize(bounds.size))
    }
}
