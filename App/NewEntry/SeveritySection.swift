// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

private let knobDiameter: CGFloat = 30
private let trackHeight: CGFloat = 4

struct SeveritySection: View {
    let caption: LocalizedStringKey
    let spokenLabel: LocalizedStringKey
    let idPrefix: String
    @Binding var severity: Severity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(caption)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .cardCaption()
                .accessibilityIdentifier("\(idPrefix)-caption")
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 12) {
                // In double-length text the value is clipped beside the label, so it stacks under it instead.
                ViewThatFits(in: .horizontal) {
                    HStack {
                        Text("How strong")
                        Spacer()
                        SeverityValue(severity: severity, idPrefix: idPrefix)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("How strong")
                        SeverityValue(severity: severity, idPrefix: idPrefix)
                    }
                }
                .accessibilityHidden(true)
                Divider()
                HStack(spacing: 8) {
                    Text(0, format: .number)
                        .accessibilityIdentifier("\(idPrefix)-low-label")
                        .accessibilityHidden(true)
                    // The knob hangs over each end of the control by its radius, so the padding keeps the labels clear.
                    SeverityControl(severity: $severity, spokenLabel: spokenLabel, idPrefix: idPrefix)
                        .padding(.horizontal, knobDiameter / 2)
                    Text(10, format: .number)
                        .accessibilityIdentifier("\(idPrefix)-high-label")
                        .accessibilityHidden(true)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color("CardBackground"), in: .card)
        }
    }
}

private struct SeverityValue: View {
    let severity: Severity
    let idPrefix: String

    var body: some View {
        Text("\(Text(severity.value, format: .number).bold()) of \(10)")
            .accessibilityIdentifier("\(idPrefix)-value")
    }
}

private struct SeverityControl: View {
    @Binding var severity: Severity
    let spokenLabel: LocalizedStringKey
    let idPrefix: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.layoutDirection) private var layoutDirection

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let fillWidth = width * CGFloat(severity.value) / 10
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(uiColor: .systemGray4))
                    .frame(height: trackHeight)
                Capsule()
                    .fill(Color("AccentColor"))
                    .frame(width: fillWidth, height: trackHeight)
                SeverityKnob()
                    .position(x: fillWidth, y: proxy.size.height / 2)
            }
            .animation(reduceMotion ? nil : .snappy, value: severity)
            .accessibilityHidden(true)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { setLevel(atX: $0.location.x, width: width) }
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
                .accessibilityLabel(spokenLabel)
                .accessibilityValue(severity.spokenValue)
                .accessibilityIdentifier("\(idPrefix)-slider")
        }
    }

    private var level: Binding<Double> {
        Binding(
            get: { Double(severity.value) },
            set: { severity = Severity(exactly: $0) ?? severity }
        )
    }

    private func setLevel(atX x: CGFloat, width: CGFloat) {
        // Touch locations are not mirrored by the layout, unlike .position and the leading-aligned fill.
        let fromStart = layoutDirection == .rightToLeft ? width - x : x
        let next = Severity(nearestToFraction: Double(fromStart / width))
        guard next != severity else { return }
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
