// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

/// The one look of every tip. A screen passes the icon, title, message and dismiss action, and sets no colour, font,
/// size or padding. The card grows with its text and its padding never shrinks.
struct TipCard<Title: View, Message: View>: View {
    let icon: String?
    let title: Title
    let message: Message?
    let dismiss: () -> Void

    @ScaledMetric(relativeTo: .headline) private var iconSize = Spacing.tipIcon
    @ScaledMetric(relativeTo: .headline) private var dismissGlyphSize = Spacing.tipDismissGlyph

    init(icon: String? = nil, title: Title, message: Message?, dismiss: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.message = message
        self.dismiss = dismiss
    }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.tipGap) {
            if let icon {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                    .offset(y: Spacing.tipIconNudge)
                    .accessibilityHidden(true)
            }
            text
            dismissButton
        }
        .foregroundStyle(Color.onSoft)
        .padding(.top, Spacing.cardContentGap)
        .padding(.bottom, Spacing.cardContentGap)
        .padding(.leading, Spacing.cardInset)
        .padding(.trailing, Spacing.tipInset)
        .background(Color.soft, in: .card)
        .accessibilityElement(children: .contain)
    }

    private var text: some View {
        VStack(alignment: .leading, spacing: Spacing.textLinesGap) {
            title
                .font(.headline)
            message?
                .font(.subheadline)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }

    private var dismissButton: some View {
        Button(action: dismiss) {
            Image(systemName: "xmark")
                .resizable()
                .scaledToFit()
                .frame(width: dismissGlyphSize, height: dismissGlyphSize)
                .fontWeight(.semibold)
                .frame(width: Spacing.tapTarget, height: Spacing.tapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Dismiss tip")
    }
}

#Preview("With icon") {
    TipCard(
        icon: "pin.fill",
        title: Text("Pin a shortcut"),
        message: Text("Swipe a place right to pin it as a shortcut on New Entry."),
        dismiss: {}
    )
    .padding(.horizontal, Spacing.screenMargin)
}

#Preview("No icon, long text") {
    TipCard(
        title: Text("A title long enough that it has to wrap onto a second line"),
        message: Text("A body long enough that it wraps too, so the dismiss button stays level with the title."),
        dismiss: {}
    )
    .padding(.horizontal, Spacing.screenMargin)
}
