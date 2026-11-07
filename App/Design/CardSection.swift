// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

private struct SectionCaption: ViewModifier {
    let edge: Edge.Set
    let gap: CGFloat

    func body(content: Content) -> some View {
        content
            .textCase(nil)
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowInsets(.leading, .zero)
            .listRowInsets(edge, gap)
    }
}

struct CardSection<Content: View>: View {
    private let label: Text?
    private let footnote: Text?
    private let id: String
    private let content: Content

    init(_ label: Text? = nil, footnote: Text? = nil, id: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.footnote = footnote
        self.id = id
        self.content = content()
    }

    var body: some View {
        Section {
            content
                .listRowBackground(Color.card)
        } header: {
            if let label {
                label
                    .modifier(SectionCaption(edge: .bottom, gap: Spacing.labelGap))
                    .accessibilityIdentifier("\(id)-label")
            }
        } footer: {
            if let footnote {
                footnote
                    .modifier(SectionCaption(edge: .top, gap: Spacing.footnoteGap))
                    .accessibilityIdentifier("\(id)-footnote")
            }
        }
    }
}
