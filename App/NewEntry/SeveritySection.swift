import AnkyDomain
import SwiftUI

private let knobDiameter: CGFloat = 30
private let trackHeight: CGFloat = 4

struct SeveritySection: View {
    @Binding var draft: EntryDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Severity")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .accessibilityIdentifier("severity-caption")
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 12) {
                HStack {
                    Text("How strong")
                    Spacer()
                    SeverityValue(severity: draft.severity)
                }
                Divider()
                HStack(spacing: 8) {
                    Text("0")
                    // The knob hangs over each end of the control by its radius, so the padding keeps the labels clear.
                    SeverityControl(severity: $draft.severity)
                        .padding(.horizontal, knobDiameter / 2)
                    Text("10")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

private struct SeverityValue: View {
    let severity: Severity

    var body: some View {
        Text(severity.text)
    }
}

private struct SeverityControl: View {
    @Binding var severity: Severity
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let knobX = proxy.size.width * CGFloat(severity.value) / 10
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(uiColor: .systemGray4))
                    .frame(height: trackHeight)
                Capsule()
                    .fill(Color("AccentColor"))
                    .frame(width: knobX, height: trackHeight)
                SeverityKnob()
                    .position(x: knobX, y: proxy.size.height / 2)
            }
            .animation(reduceMotion ? nil : .snappy, value: severity)
            .accessibilityHidden(true)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { setLevel(atX: $0.location.x, width: proxy.size.width) }
            )
        }
        .frame(height: 44)
        .sensoryFeedback(.selection, trigger: severity)
        // The only slider in the accessibility tree. A laid-out Slider needs a non-zero opacity, since zero drops it
        // from the tree.
        .overlay {
            Slider(value: level, in: 0 ... 10, step: 1)
                .opacity(0.01)
                .allowsHitTesting(false)
                .accessibilityLabel("Severity")
                .accessibilityValue(severity.text)
                .accessibilityIdentifier("severity-slider")
        }
    }

    private var level: Binding<Double> {
        Binding(
            get: { Double(severity.value) },
            set: { severity = Severity(exactly: $0) ?? severity }
        )
    }

    private func setLevel(atX x: CGFloat, width: CGFloat) {
        let fraction = min(max(x / width, 0), 1)
        guard let next = Severity(Int((fraction * 10).rounded())), next != severity else { return }
        severity = next
    }
}

private struct SeverityKnob: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(uiColor: .systemBackground))
            Circle()
                .strokeBorder(Color("AccentColor"), lineWidth: 1)
            Circle()
                .fill(Color("AccentColor"))
                .padding(5)
        }
        .frame(width: knobDiameter, height: knobDiameter)
    }
}
