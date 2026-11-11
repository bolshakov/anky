// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

private struct SectionFooter: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textCase(nil)
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowInsets(.top, Spacing.footnoteGap)
    }
}

private struct SectionLabel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textCase(nil)
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowInsets(.top, .zero)
            .listRowInsets(.bottom, Spacing.labelGap)
    }
}

struct CardSection<Content: View>: View {
    private let label: Text?
    private let footnote: Text?
    private let id: String
    private let footnoteID: String
    private let content: Content

    init(
        _ label: Text? = nil,
        footnote: Text? = nil,
        id: String,
        footnoteID: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        // #lizard forgives
        self.label = label
        self.footnote = footnote
        self.id = id
        self.footnoteID = footnoteID ?? "\(id)-footnote"
        self.content = content()
    }

    var body: some View {
        Section {
            content
                .listRowBackground(Color.card)
        } header: {
            if let label {
                label
                    .modifier(SectionLabel())
                    .accessibilityIdentifier("\(id)-label")
            }
        } footer: {
            if let footnote {
                footnote
                    .modifier(SectionFooter())
                    .accessibilityIdentifier(footnoteID)
            }
        }
    }
}
