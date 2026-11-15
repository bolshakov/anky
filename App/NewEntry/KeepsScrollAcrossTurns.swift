// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI
import UIKit

/// `ScrollPosition` neither follows nor drives a Form, so the position is set on the Form's own scroll view.
private final class ScrollViewHandle {
    weak var scrollView: UIScrollView?

    func scroll(toDistanceFromTop distance: CGFloat) {
        guard let scrollView else { return }
        scrollView.setContentOffset(
            CGPoint(x: scrollView.contentOffset.x, y: distance - scrollView.adjustedContentInset.top),
            animated: false
        )
    }
}

private struct ScrollViewFinder: UIViewRepresentable {
    let handle: ScrollViewHandle

    func makeUIView(context _: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: UIView, context _: Context) {
        DispatchQueue.main.async { handle.scrollView = Self.scrollView(near: view) }
    }

    private static func scrollView(near view: UIView) -> UIScrollView? {
        var ancestor = view.superview
        while let current = ancestor {
            if let found = firstScrollView(in: current) {
                return found
            }
            ancestor = current.superview
        }
        return nil
    }

    private static func firstScrollView(in view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView {
            return scrollView
        }
        return view.subviews.lazy.compactMap { firstScrollView(in: $0) }.first
    }
}

private struct KeepsScrollAcrossTurns: ViewModifier {
    @Binding var savedDistance: CGFloat
    @State private var handle = ScrollViewHandle()
    @State private var phase = ScrollPhase.idle

    func body(content: Content) -> some View {
        content
            .background(ScrollViewFinder(handle: handle))
            .onScrollPhaseChange { _, new, context in
                phase = new
                if new == .idle {
                    savedDistance = distanceFromTop(context.geometry)
                }
            }
            .onScrollGeometryChange(for: CGFloat.self, of: distanceFromTop) { _, distance in
                let target = ScrollRestore.target(offset: distance, saved: savedDistance, isIdle: phase == .idle)
                if let target {
                    handle.scroll(toDistanceFromTop: target)
                }
            }
    }

    private func distanceFromTop(_ geometry: ScrollGeometry) -> CGFloat {
        geometry.contentOffset.y + geometry.contentInsets.top
    }
}

extension View {
    func keepsScrollAcrossTurns(savedDistance: Binding<CGFloat>) -> some View {
        modifier(KeepsScrollAcrossTurns(savedDistance: savedDistance))
    }
}
