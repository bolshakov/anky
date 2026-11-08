// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

/// A section of a grouped list whose footnote keeps the system footer inset and tint, unlike `CardSection`'s.
struct FootnotedSection<Content: View>: View {
    private let footnote: Text
    private let content: Content

    init(footnote: Text, @ViewBuilder content: () -> Content) {
        self.footnote = footnote
        self.content = content()
    }

    var body: some View {
        Section {
            content
        } footer: {
            footnote
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
