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
            Slider(value: level, in: 0 ... 10, step: 1)
                .accessibilityIdentifier("severity-slider")
                .accessibilityLabel("Severity")
                .accessibilityValue(draft.severity.text)
            HStack {
                Text("0")
                Spacer()
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
