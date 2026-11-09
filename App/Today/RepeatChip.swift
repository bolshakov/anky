// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct RepeatChip: View {
    let recent: RecentEntry
    let onTap: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var borderShape: ButtonBorderShape {
        dynamicTypeSize.isAccessibilitySize ? .roundedRectangle(radius: Corner.card) : .capsule
    }

    var body: some View {
        Button(action: onTap) {
            Text(RecentEntryText.sameAsLastTime + " · " + recent.chipText(namesKind: true))
                .font(.subheadline)
                .multilineTextAlignment(.leading)
                .frame(minHeight: Spacing.repeatChipLabelHeight)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(borderShape)
        .contentShape(borderShape)
        .accessibilityLabel(RecentEntryText.sameAsLastTime + ", " + recent.spokenText(namesKind: true))
        .accessibilityIdentifier("repeat-chip")
    }
}

struct RepeatLoggedCard: View {
    let recent: RecentEntry
    let onUndo: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.inlineGap))
            : AnyLayout(HStackLayout(spacing: Spacing.rowContentGap))
        layout {
            HStack(spacing: Spacing.rowContentGap) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color("AccentColor"))
                    .accessibilityHidden(true)
                Text(String(localized: "Logged") + " · " + recent.chipText(namesKind: true))
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityHidden(true)
                    .accessibilityIdentifier("repeat-logged")
            }
            Button(action: onUndo) {
                Text("Undo")
                    .frame(minHeight: Spacing.rowMinimumHeight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .foregroundStyle(Color("AccentColor"))
            .accessibilityIdentifier("repeat-undo")
        }
        .padding(.horizontal, Spacing.cardInset)
        .frame(minHeight: Spacing.rowMinimumHeight)
        .background(Color("CardBackground"), in: .card)
    }
}
