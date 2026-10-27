import AnkyDomain
import SwiftUI

struct SeveritySection: View {
    @Binding var draft: EntryDraft

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("How strong")
                Spacer()
                Text(draft.severity.text)
            }
            Divider()
            HStack(spacing: 12) {
                Text("0")
                Slider(value: level, in: 0 ... 10, step: 1)
                    .tint(Color("AccentColor"))
                    .accessibilityIdentifier("severity-slider")
                    .accessibilityLabel("Severity")
                    .accessibilityValue(draft.severity.text)
                    .sensoryFeedback(.selection, trigger: draft.severity)
                    .overlay(alignment: .bottom) { SeverityTicks() }
                Text("10")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var level: Binding<Double> {
        Binding(
            get: { Double(draft.severity.value) },
            set: { draft.severity = Severity(exactly: $0) ?? draft.severity }
        )
    }
}

private struct SeverityTicks: View {
    /// The thumb's centre stops this far in from each end, so the first and last tick line up with the thumb.
    private let inset: CGFloat = 18

    var body: some View {
        GeometryReader { proxy in
            let span = proxy.size.width - 2 * inset
            ForEach(0 ... 10, id: \.self) { step in
                Capsule()
                    .fill(.secondary)
                    .frame(width: 2, height: 6)
                    .position(x: inset + span * CGFloat(step) / 10, y: proxy.size.height / 2)
            }
        }
        .frame(height: 6)
        .accessibilityHidden(true)
    }
}
