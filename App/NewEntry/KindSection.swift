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

    /// The real picker is laid over the drawn track at 0.01 opacity. Opacity 0 would drop it from the accessibility
    /// tree, and touches pass through it to the drawn segments.
    private var track: some View {
        segments
            .padding(4)
            .background(Color("CardBackground"), in: Capsule())
            .animation(motion, value: draft.kind)
            .sensoryFeedback(.selection, trigger: draft.kind)
            .overlay {
                Picker("Kind", selection: $draft.kind) {
                    ForEach(EntryKind.allCases, id: \.self) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .opacity(0.01)
                .allowsHitTesting(false)
                .accessibilityIdentifier("kind-picker")
            }
    }

    private var motion: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.35, bounce: 0.2)
    }

    private var segments: some View {
        HStack(spacing: 0) {
            ForEach(EntryKind.allCases, id: \.self) { kind in
                KindSegment(
                    title: kind.displayName,
                    isSelected: kind == draft.kind,
                    namespace: selection,
                    showsSlide: !reduceMotion
                ) {
                    draft.kind = kind
                }
            }
        }
        .accessibilityHidden(true)
    }
}

private struct KindSegment: View {
    let title: LocalizedStringResource
    let isSelected: Bool
    let namespace: Namespace.ID
    let showsSlide: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            Text(title)
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
    }
}
