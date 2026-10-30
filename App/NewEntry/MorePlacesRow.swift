import AnkyDomain
import SwiftUI

struct MorePlacesRow: View {
    let value: MorePlacesValue
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: action) {
            content
                .font(.body)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 52)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("More places")
        .accessibilityValue(value.listText)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("more-places")
    }

    @ViewBuilder
    private var content: some View {
        if dynamicTypeSize.isAccessibilitySize {
            stacked
        } else {
            ViewThatFits(in: .horizontal) {
                inline(value.namesText)
                inline(value.countText)
                stacked
            }
        }
    }

    private func inline(_ text: String) -> some View {
        HStack(spacing: 6) {
            label.fixedSize(horizontal: true, vertical: false)
            Spacer(minLength: 2)
            Text(text)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            chevron
        }
    }

    private var stacked: some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 4) {
                label
                Text(value.listText)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 2)
            chevron
        }
    }

    private var label: some View {
        Text("More places")
            .foregroundStyle(.primary)
    }

    private var chevron: some View {
        Image(systemName: "chevron.forward")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(width: 8, height: 14)
    }
}
