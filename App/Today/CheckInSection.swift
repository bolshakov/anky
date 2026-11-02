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
        Section {
            ForEach(doses) { dose in
                CheckInRow(
                    dose: dose,
                    name: DoseRowText.name(for: dose, in: medications),
                    readings: DoseReadings(dose, in: entries),
                    now: now
                ) {
                    onSelect(dose)
                }
            }
        } header: {
            Text("Check in")
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("check-in-heading")
        }
    }
}

struct CheckInRow: View {
    let dose: Dose
    let name: String
    let readings: DoseReadings
    let now: Date
    let onSelect: () -> Void

    private var kind: EntryKind {
        readings.before?.kind ?? .pain
    }

    private var subtitle: String {
        let time = ClockText.text(for: dose.takenAt, calendar: .current, locale: .current)
        return CheckInText.rowSubtitle(name: name, time: time, day: CheckInDay(dose.takenAt, now: now))
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
