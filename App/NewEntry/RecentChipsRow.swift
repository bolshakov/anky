import AnkyDomain
import SwiftUI

struct RecentChipsRow: View {
    let recents: [RecentEntry]
    let onSelect: (RecentEntry) -> Void
    @State private var taps = 0

    var body: some View {
        ChipFlowLayout {
            ForEach(Array(recents.enumerated()), id: \.offset) { index, recent in
                Button {
                    onSelect(recent)
                    taps += 1
                } label: {
                    Text(recent.chipText)
                }
                .buttonStyle(RecentChipButtonStyle())
                .accessibilityLabel(RecentEntryText.sameAsLastTime + ", " + recent.spokenText)
                .accessibilityIdentifier("recent-chip-\(index)")
            }
        }
        .sensoryFeedback(.selection, trigger: taps)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("recent-chips")
    }
}
