// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct DoseRow: View {
    let dose: Dose
    let readings: DoseReadings
    let title: String
    let onSelect: () -> Void

    private var time: String {
        ClockText.text(for: dose.takenAt, calendar: .current, locale: .current)
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Text(time)
                    .font(.footnote)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .fixedSize()
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(.primary)
                    Text(DoseRowText.subtitle(for: readings, words: .app))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .frame(minHeight: 60)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // The visible texts stay out of the accessibility tree, so the row is one element.
        .accessibilityRepresentation {
            Button(action: onSelect) { Color.clear }
                .accessibilityLabel(DoseRowText.spokenLabel(time: time, title: title, readings: readings, words: .app))
                .accessibilityIdentifier("dose-row")
        }
    }
}
