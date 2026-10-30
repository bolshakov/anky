import AnkyDomain
import SwiftUI

struct RepeatChip: View {
    let recent: RecentEntry
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(RecentEntryText.sameAsLastTime + " · " + recent.chipText)
        }
        .buttonStyle(RecentChipButtonStyle(fillsWidth: true))
        .accessibilityLabel(RecentEntryText.sameAsLastTime + ", " + recent.spokenText)
        .accessibilityIdentifier("repeat-chip")
    }
}

struct RepeatLoggedCard: View {
    let recent: RecentEntry
    let onUndo: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 12))
        layout {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color("AccentColor"))
                    .accessibilityHidden(true)
                Text(String(localized: "Logged") + " · " + recent.chipText)
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel(String(localized: "Logged") + ", " + recent.spokenText)
                    .accessibilityIdentifier("repeat-logged")
            }
            Button(action: onUndo) {
                Text("Undo")
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .foregroundStyle(Color("AccentColor"))
            .accessibilityIdentifier("repeat-undo")
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 44)
        .background(Color("CardBackground"), in: .card)
    }
}
