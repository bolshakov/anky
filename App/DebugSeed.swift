// SPDX-License-Identifier: GPL-3.0-or-later
#if DEBUG
    import AnkyDomain
    import AnkyMedicationModel
    import Foundation

    /// Debug builds only, for the walks: while the launch environment holds `ANKY_SEED`, an empty log is filled with
    /// synthetic records. `spread` writes 60 entries over the six months before now and 8 doses of one made-up
    /// medication, `single` writes one entry ten days back. A log that holds anything is left alone.
    @MainActor enum DebugSeed {
        static func plant(entries: EntryLogModel, medications: MedicationsModel, now: Date = .now) {
            guard entries.entries.isEmpty, medications.doses.isEmpty else { return }
            switch ProcessInfo.processInfo.environment["ANKY_SEED"] {
            case "spread":
                plantSpread(entries: entries, medications: medications, now: now)
            case "single":
                try? entries.add(entry(daysBefore: 10, index: 0, now: now))
            default:
                break
            }
        }

        private static func plantSpread(entries: EntryLogModel, medications: MedicationsModel, now: Date) {
            for index in 0 ..< 60 {
                try? entries.add(entry(daysBefore: 2 + 3 * index, index: index, now: now))
            }
            let medication = Medication(
                id: UUID(), name: "Zorblex", takenAs: .asNeeded, createdAt: day(before: now, by: 182)
            )
            try? medications.add(medication)
            for index in 0 ..< 8 {
                let dose = Dose(id: UUID(), medicationID: medication.id, takenAt: day(before: now, by: 1 + 20 * index))
                try? medications.logDose(dose)
            }
        }

        private static func entry(daysBefore days: Int, index: Int, now: Date) -> Entry {
            let kind = EntryKind.allCases[index % EntryKind.allCases.count]
            return Entry(
                id: UUID(),
                kind: kind,
                severity: Severity(index % 11) ?? Severity(nearestToFraction: 0),
                date: day(before: now, by: days),
                note: nil,
                places: []
            )
        }

        private static func day(before now: Date, by days: Int) -> Date {
            Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
        }
    }
#endif
