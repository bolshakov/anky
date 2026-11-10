// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct SystemSeveritySection: View {
    let caption: LocalizedStringKey
    let spokenLabel: LocalizedStringKey
    let idPrefix: String
    @Binding var severity: Severity
    var footer: Text?
    var footerID = ""

    var body: some View {
        CardSection(Text(caption), footnote: footer, id: idPrefix) {
            // In double-length text the value is clipped beside the label, so it stacks under it instead.
            ViewThatFits(in: .horizontal) {
                HStack {
                    Text("How strong")
                    Spacer()
                    SeverityValue(severity: severity, idPrefix: idPrefix)
                }
                VStack(alignment: .leading, spacing: Spacing.tightGap) {
                    Text("How strong")
                    SeverityValue(severity: severity, idPrefix: idPrefix)
                }
            }
            .rowHeight()
            .accessibilityHidden(true)
            Slider(value: level, in: 0 ... 10, step: 1) {
                EmptyView()
            } minimumValueLabel: {
                Text(0, format: .number)
                    .font(.footnote)
                    .foregroundStyle(Color.ink2)
                    .accessibilityIdentifier("\(idPrefix)-low-label")
                    .accessibilityHidden(true)
            } maximumValueLabel: {
                Text(10, format: .number)
                    .font(.footnote)
                    .foregroundStyle(Color.ink2)
                    .accessibilityIdentifier("\(idPrefix)-high-label")
                    .accessibilityHidden(true)
            }
            .minimumTapTarget()
            .accessibilityLabel(spokenLabel)
            .accessibilityValue(severity.spokenValue)
            .accessibilityIdentifier("\(idPrefix)-slider")
            .sensoryFeedback(.selection, trigger: severity)
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
        Text("\(Text(severity.value, format: .number)) of \(10)")
            .accessibilityIdentifier("\(idPrefix)-value")
    }
}
