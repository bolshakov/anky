// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

/// A section of a grouped list whose footnote keeps the system footer inset and tint, unlike `CardSection`'s.
struct FootnotedSection<Content: View>: View {
    private let label: Text?
    private let footnote: Text?
    private let footnoteID: String?
    private let content: Content

    init(
        _ label: Text? = nil,
        footnote: Text?,
        footnoteID: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self.footnote = footnote
        self.footnoteID = footnoteID
        self.content = content()
    }

    var body: some View {
        Section {
            content
        } header: {
            if let label {
                label.modifier(SectionLabel())
            }
        } footer: {
            if let footnote {
                identified(footnote.font(.footnote).foregroundStyle(.secondary))
            }
        }
    }

    @ViewBuilder
    private func identified(_ view: some View) -> some View {
        if let footnoteID {
            view.accessibilityIdentifier(footnoteID)
        } else {
            view
        }
    }
}
