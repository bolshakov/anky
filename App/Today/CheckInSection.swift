// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct CheckInSection: View {
    let doses: [Dose]
    let medications: [Medication]
    let entries: [Entry]
    let now: Date
    let onSelect: (Dose) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Check in")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .cardCaption()
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("check-in-heading")

            VStack(spacing: 0) {
                ForEach(doses) { dose in
                    CheckInRow(
                        dose: dose,
                        title: DoseRowText.title(for: dose, in: medications),
                        readings: DoseReadings(dose, in: entries),
                        now: now
                    ) {
                        onSelect(dose)
                    }
                    if dose.id != doses.last?.id {
                        Divider()
                    }
                }
            }
            .background(Color("CardBackground"), in: .card)
        }
    }
}

struct CheckInRow: View {
    let dose: Dose
    let title: String
    let readings: DoseReadings
    let now: Date
    let onSelect: () -> Void

    private var kind: EntryKind {
        readings.before?.kind ?? .pain
    }

    private var subtitle: String {
        let time = ClockText.text(for: dose.takenAt, calendar: .current, locale: .current)
        return CheckInText.rowSubtitle(name: title, time: time, day: CheckInDay(dose.takenAt, now: now))
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(CheckInText.question(for: kind))
                        .font(.body)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(CheckInText.logAction(for: kind))
                    .foregroundStyle(.tint)
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .frame(minHeight: 60)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Button(action: onSelect) { Color.clear }
                .accessibilityLabel("\(CheckInText.question(for: kind)) \(subtitle)")
                .accessibilityHint(String(localized: "Opens Check In"))
                .accessibilityIdentifier("check-in-row")
        }
    }
}
