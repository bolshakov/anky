import AnkyDomain
import SwiftUI

struct RecentChipsRow: View {
    let recents: [RecentEntry]
    let onSelect: (RecentEntry) -> Void

    var body: some View {
        ChipFlowLayout {
            ForEach(Array(recents.enumerated()), id: \.offset) { index, recent in
                Button {
                    onSelect(recent)
                } label: {
                    Text(recent.chipText)
                }
                .buttonStyle(RecentChipButtonStyle())
                .accessibilityLabel(RecentEntryText.sameAsLastTime + ", " + recent.spokenText)
                .accessibilityIdentifier("recent-chip-\(index)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("recent-chips")
    }
}
