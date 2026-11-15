// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

private struct Measured: Equatable {
    let width: Double
    let leadingInset: Double
    let trailingInset: Double

    var edges: ContentEdges {
        ContentColumn.edges(
            width: width,
            leadingInset: leadingInset,
            trailingInset: trailingInset,
            margin: Spacing.screenMargin,
            maximumWidth: Spacing.contentMaxWidth
        )
    }
}

private extension View {
    /// A view laid out inside the safe area reports a width without the insets, so they are added back to get the
    /// screen's width.
    func onColumnChange(_ update: @escaping (Measured) -> Void) -> some View {
        onGeometryChange(for: Measured.self) { proxy in
            Measured(
                width: proxy.size.width + proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing,
                leadingInset: proxy.safeAreaInsets.leading,
                trailingInset: proxy.safeAreaInsets.trailing
            )
        } action: { update($0) }
    }
}

private struct ScrollColumn: ViewModifier {
    @State private var edges = ContentEdges(leading: Spacing.screenMargin, trailing: Spacing.screenMargin)

    /// A ScrollView measures a content margin from the safe area's edge and a List or Form from the screen's edge.
    /// Extending the container under the horizontal safe area makes all three measure from the screen's edge.
    func body(content: Content) -> some View {
        content
            .contentMargins(.leading, edges.leading, for: .scrollContent)
            .contentMargins(.trailing, edges.trailing, for: .scrollContent)
            .ignoresSafeArea(.container, edges: .horizontal)
            .onColumnChange { edges = $0.edges }
    }
}

private struct BarColumn: ViewModifier {
    @State private var padding = ContentEdges(leading: Spacing.screenMargin, trailing: Spacing.screenMargin)

    /// A bar's content already starts inside the safe area, so the inset is taken off what the column asks for.
    func body(content: Content) -> some View {
        content
            .padding(.leading, padding.leading)
            .padding(.trailing, padding.trailing)
            .onColumnChange { measured in
                let edges = measured.edges
                padding = ContentEdges(
                    leading: max(0, edges.leading - measured.leadingInset),
                    trailing: max(0, edges.trailing - measured.trailingInset)
                )
            }
    }
}

extension View {
    func contentColumn() -> some View {
        modifier(ScrollColumn())
    }

    func insetBarColumn() -> some View {
        modifier(BarColumn())
    }
}
