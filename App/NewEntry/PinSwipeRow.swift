// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct PinSwipeActions {
    let onCrossedCommitPoint: () -> Void
    let onAction: () -> Void
    let onCommit: () -> Void
}

private enum PinSwipeMetrics {
    static let dragStartDistance: CGFloat = 10
    static let slideDuration: Double = 0.2
    static let pillWidth: CGFloat = 60
    static let pillHeight: CGFloat = 28
    static let labelSpacing: CGFloat = 2
    static let pillLeadingInset: CGFloat = 10
}

struct PinSwipeRow<Content: View>: View {
    private enum Drag: Equatable {
        case idle
        case swiping(from: Double)
        case ignored
    }

    let place: PlaceID
    let isPinned: Bool
    let actions: PinSwipeActions
    let content: (Bool) -> Content

    @State private var offset: Double = 0
    @State private var isRevealed = false
    @State private var isCommitting = false
    @State private var isLifted = false
    @State private var drag = Drag.idle
    @State private var dragStart: CGPoint?
    @State private var rowWidth: Double = 0

    init(place: PlaceID, isPinned: Bool, actions: PinSwipeActions, @ViewBuilder content: @escaping (Bool) -> Content) {
        self.place = place
        self.isPinned = isPinned
        self.actions = actions
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .leading) {
            pinAction
            content(isLifted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SwipeShade.color.opacity(isLifted ? 1 : 0), in: Capsule())
                .overlay { closeCatcher }
                .offset(x: CGFloat(offset))
                .simultaneousGesture(swipe)
        }
        .background { widthReader }
        .listRowBackground(isLifted ? Color.clear : nil)
        .listRowSeparator(isLifted ? .hidden : .automatic)
    }

    private var isMoved: Bool {
        offset > 0
    }

    private var isActionExposed: Bool {
        isRevealed || isCommitting
    }

    private var actionTitle: LocalizedStringResource {
        isPinned ? "Unpin" : "Pin"
    }

    private var pinAction: some View {
        Button(action: performAction) {
            VStack(spacing: PinSwipeMetrics.labelSpacing) {
                Image(systemName: isPinned ? "pin.slash.fill" : "pin.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color("OnAccent"))
                    .frame(width: PinSwipeMetrics.pillWidth, height: PinSwipeMetrics.pillHeight)
                    .background(Color.accentColor, in: Capsule())
                    .accessibilityHidden(true)
                Text(actionTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, PinSwipeMetrics.pillLeadingInset)
            .frame(maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        .frame(width: CGFloat(PinSwipe.revealWidth), alignment: .leading)
        .frame(maxHeight: .infinity)
        .opacity(isMoved ? 1 : 0)
        .allowsHitTesting(isRevealed)
        .accessibilityHidden(!isActionExposed)
        .accessibilityIdentifier("pin-action-\(place.rawValue)")
    }

    private var closeCatcher: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture { settle(at: 0, revealed: false) }
            .accessibilityHidden(true)
            .opacity(isRevealed ? 1 : 0)
            .allowsHitTesting(isRevealed)
    }

    private var widthReader: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { rowWidth = Double(proxy.size.width) }
                .onChange(of: proxy.size.width) { _, width in rowWidth = Double(width) }
        }
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: PinSwipeMetrics.dragStartDistance, coordinateSpace: .global)
            .onChanged { dragChanged($0) }
            .onEnded { _ in dragEnded() }
    }

    private func dragChanged(_ value: DragGesture.Value) {
        if value.startLocation != dragStart {
            beginDrag(value)
        }
        guard case let .swiping(from) = drag else { return }
        isLifted = true
        let next = min(max(from + Double(value.translation.width), 0), rowWidth)
        if PinSwipe.crossedCommitPoint(from: offset, to: next, rowWidth: rowWidth) {
            actions.onCrossedCommitPoint()
        }
        offset = next
    }

    private func beginDrag(_ value: DragGesture.Value) {
        if case .swiping = drag {
            settle(at: isRevealed ? PinSwipe.revealWidth : 0, revealed: isRevealed)
        }
        dragStart = value.startLocation
        let isMostlyHorizontal = value.translation.width > 0
            && value.translation.width > abs(value.translation.height)
        drag = isMostlyHorizontal && rowWidth > 0 ? .swiping(from: offset) : .ignored
    }

    private func dragEnded() {
        if case .swiping = drag {
            release()
        }
        drag = .idle
        dragStart = nil
    }

    private func release() {
        switch PinSwipe.release(at: offset, rowWidth: rowWidth) {
        case .close:
            settle(at: 0, revealed: false)
        case .reveal:
            settle(at: PinSwipe.revealWidth, revealed: true)
        case .commit:
            commit()
        }
    }

    private func settle(at target: Double, revealed: Bool) {
        isRevealed = revealed
        guard offset != target else {
            endLiftIfClosed()
            return
        }
        withAnimation(.easeOut(duration: PinSwipeMetrics.slideDuration), completionCriteria: .logicallyComplete) {
            offset = target
        } completion: {
            endLiftIfClosed()
        }
    }

    private func commit() {
        isRevealed = false
        isCommitting = true
        withAnimation(.easeOut(duration: PinSwipeMetrics.slideDuration), completionCriteria: .logicallyComplete) {
            offset = 0
        } completion: {
            isCommitting = false
            actions.onCommit()
            endLiftIfClosed()
        }
    }

    private func endLiftIfClosed() {
        guard offset == 0 else { return }
        withAnimation(.easeOut(duration: PinSwipeMetrics.slideDuration)) {
            isLifted = false
        }
    }

    private func performAction() {
        actions.onAction()
        settle(at: 0, revealed: false)
    }
}
