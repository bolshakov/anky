// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

private extension EnvironmentValues {
    @Entry var reportButtonIsInBar = false
}

private struct ContentStartKey: PreferenceKey {
    static let defaultValue: CGFloat? = nil

    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = nextValue() ?? value
    }
}

private struct ReportButtonAnchor: ViewModifier {
    func body(content: Content) -> some View {
        content.background {
            GeometryReader { proxy in
                Color.clear.preference(key: ContentStartKey.self, value: proxy.frame(in: .global).minY)
            }
        }
    }
}

/// A toolbar item declared on the list reaches the bar as a plain button. Declared from a row it is wrapped in a group
/// that repeats the button's identifier.
private struct ReportButtonInBar: ViewModifier {
    @Binding var isShowingReport: Bool
    @Environment(\.reportButtonIsInBar) private var isInBar

    func body(content: Content) -> some View {
        content.toolbar {
            if isInBar {
                ToolbarItem(placement: .topBarTrailing) {
                    ReportButton(onReport: { isShowingReport = true }, isInToolbar: true)
                }
            }
        }
    }
}

/// The navigation bar takes every touch in its large-title row, so a button inside the list cannot open there. The
/// button is drawn above the stack instead, level with the title, and keeps its distance from the list's first row so
/// it moves with the content.
private struct ReportButtonOnTitleLine: ViewModifier {
    @Binding var isShowingReport: Bool
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize = Spacing.largeTitleSize
    @State private var contentStart: CGFloat?
    @State private var safeAreaTop: CGFloat = 0

    private var top: CGFloat? {
        contentStart.map { $0 - Spacing.titleToContentStartPerTitlePoint * titleSize - Spacing.tapTarget / 2 }
    }

    /// Fully drawn while it is below the collapsed bar, gone once its centre is level with the bar's lower edge.
    private func visibility(top: CGFloat) -> CGFloat {
        let belowBar = top - (safeAreaTop + Spacing.navigationBarRow)
        let fadeDistance = Spacing.tapTarget / 2
        return isShowingReport ? 0 : min(1, max(0, 1 + belowBar / fadeDistance))
    }

    private var isInBar: Bool {
        guard let top else { return false }
        return !isShowingReport && visibility(top: top) == 0
    }

    private var button: ReportButton {
        ReportButton(onReport: { isShowingReport = true })
    }

    func body(content: Content) -> some View {
        content
            .environment(\.reportButtonIsInBar, isInBar)
            // The list drops the anchor row once it is far above the bar. The last position stays true: it was above.
            .onPreferenceChange(ContentStartKey.self) { start in
                if let start {
                    contentStart = start
                }
            }
            .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { safeAreaTop = $0 }
            .overlay(alignment: .topTrailing) {
                if let top, visibility(top: top) > 0 {
                    button
                        .padding(.top, top)
                        .padding(.trailing, Spacing.screenMargin)
                        .opacity(visibility(top: top))
                        .transition(.opacity)
                        .ignoresSafeArea()
                }
            }
            .animation(.default, value: isShowingReport)
    }
}

extension View {
    /// Marks the view whose top edge the report button keeps its distance from.
    func reportButtonAnchor() -> some View {
        modifier(ReportButtonAnchor())
    }

    /// Shows the button in the navigation bar once `reportButtonOnTitleLine` has faded its own copy out.
    func reportButtonInBar(isShowingReport: Binding<Bool>) -> some View {
        modifier(ReportButtonInBar(isShowingReport: isShowingReport))
    }

    func reportButtonOnTitleLine(isShowingReport: Binding<Bool>) -> some View {
        modifier(ReportButtonOnTitleLine(isShowingReport: isShowingReport))
    }
}
