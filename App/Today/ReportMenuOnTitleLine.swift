// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

private struct ContentStartKey: PreferenceKey {
    static let defaultValue: CGFloat? = nil

    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = nextValue() ?? value
    }
}

/// The navigation bar takes every touch in its large-title row, so a button inside the list cannot open there. The
/// button is drawn above the stack instead, level with the title, and keeps its distance from the list's first row so
/// it moves with the content.
private struct ReportMenuOnTitleLine: ViewModifier {
    @Binding var isShowingReport: Bool
    @Binding var isShowingBasdai: Bool
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
        return isShowingReport || isShowingBasdai ? 0 : min(1, max(0, 1 + belowBar / fadeDistance))
    }

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(ContentStartKey.self) { contentStart = $0 }
            .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { safeAreaTop = $0 }
            .overlay(alignment: .topTrailing) {
                if let top, visibility(top: top) > 0 {
                    ReportMenu(onReport: { isShowingReport = true }, onBasdai: { isShowingBasdai = true })
                        .padding(.top, top)
                        .padding(.trailing, Spacing.screenMargin)
                        .opacity(visibility(top: top))
                        .transition(.opacity)
                        .ignoresSafeArea()
                }
            }
            .animation(.default, value: isShowingReport || isShowingBasdai)
    }
}

extension View {
    /// Marks the view whose top edge the report menu keeps its distance from.
    func reportMenuAnchor() -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(key: ContentStartKey.self, value: proxy.frame(in: .global).minY)
            }
        }
    }

    func reportMenuOnTitleLine(isShowingReport: Binding<Bool>, isShowingBasdai: Binding<Bool>) -> some View {
        modifier(ReportMenuOnTitleLine(isShowingReport: isShowingReport, isShowingBasdai: isShowingBasdai))
    }
}
