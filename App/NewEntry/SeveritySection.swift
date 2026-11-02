// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

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
                Slider(value: level, in: 0 ... 10, step: 1) {
                    EmptyView()
                } minimumValueLabel: {
                    Text(0, format: .number)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("\(idPrefix)-low-label")
                        .accessibilityHidden(true)
                } maximumValueLabel: {
                    Text(10, format: .number)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("\(idPrefix)-high-label")
                        .accessibilityHidden(true)
                }
                .frame(minHeight: 44)
                .accessibilityLabel(spokenLabel)
                .accessibilityValue(severity.spokenValue)
                .accessibilityIdentifier("\(idPrefix)-slider")
                .sensoryFeedback(.selection, trigger: severity)
            }
            .padding()
            .background(Color("CardBackground"), in: .card)
        }
    }

    private var level: Binding<Double> {
        Binding(
            get: { Double(severity.value) },
            set: { severity = Severity(exactly: $0) ?? severity }
        )
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
