// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

/// A card section whose footer is a centred block of any views, which the system places under the group and scrolls
/// with the list. `CardSection` has only a left-aligned footnote.
struct FooterBlockSection<Content: View, Footer: View>: View {
    private let label: Text
    private let content: Content
    private let footer: Footer

    init(_ label: Text, footer: Footer, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
        self.footer = footer
    }

    var body: some View {
        Section {
            content
                .listRowBackground(Color.card)
        } header: {
            label
                .textCase(nil)
                .frame(maxWidth: .infinity, alignment: .leading)
                .listRowInsets(.top, .zero)
                .listRowInsets(.bottom, Spacing.labelGap)
        } footer: {
            footer
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .listRowInsets(.top, Spacing.blockGap)
        }
    }
}
