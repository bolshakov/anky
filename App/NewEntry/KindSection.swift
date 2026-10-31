// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct KindSection: View {
    @Binding var draft: EntryDraft
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var selection

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            KindButtons(kind: $draft.kind)
        } else {
            track
        }
    }

    private var track: some View {
        segments
            .padding(4)
            .background(Color("CardBackground"), in: Capsule())
            .animation(motion, value: draft.kind)
            .sensoryFeedback(.selection, trigger: draft.kind)
    }

    private var motion: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.35, bounce: 0.2)
    }

    private var segments: some View {
        HStack(spacing: 0) {
            ForEach(EntryKind.allCases, id: \.self) { kind in
                KindSegment(
                    kind: kind,
                    isSelected: kind == draft.kind,
                    namespace: selection,
                    showsSlide: !reduceMotion
                ) {
                    draft.kind = kind
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("What are you logging")
        .accessibilityIdentifier("kind-picker")
    }
}

private struct KindSegment: View {
    let kind: EntryKind
    let isSelected: Bool
    let namespace: Namespace.ID
    let showsSlide: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            Text(kind.displayName)
                .font(.body.weight(isSelected ? .bold : .regular))
                .foregroundStyle(isSelected ? Color("AccentColor") : .primary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
                .background {
                    if isSelected {
                        Capsule()
                            .fill(Color("AccentColor").opacity(0.15))
                            .matchedGeometryEffect(id: "selection", in: namespace, isSource: showsSlide)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("kind-\(kind.rawValue)")
    }
}
