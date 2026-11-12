// SPDX-License-Identifier: GPL-3.0-or-later
#if DEBUG
    import AnkyDomain
    import AnkyMedicationModel
    import Foundation

    /// Debug builds only, for the walks: while the launch environment holds `ANKY_SEED`, an empty log is filled with
    /// synthetic records. `spread` writes 60 entries over the six months before now and 8 doses of one made-up
    /// medication, `single` writes one entry ten days back, and `reading-aging` writes one 118 minutes back, which
    /// leaves the two-hour reading window within about two minutes. `report-short`, `report-long`, `report-sparse` and
    /// `report-places-7` write the report walks' logs, as `DebugReportSeed` describes, and `report-basdai` adds three
    /// BASDAI results to the `report-short` log. A log that holds anything is left alone.
    @MainActor enum DebugSeed {
        static func plant(
            entries: EntryLogModel, medications: MedicationsModel, basdai: BasdaiModel, now: Date = .now
        ) {
            guard entries.entries.isEmpty, medications.doses.isEmpty, basdai.results.isEmpty else { return }
            switch ProcessInfo.processInfo.environment["ANKY_SEED"] {
            case "spread":
                plantSpread(entries: entries, medications: medications, now: now)
            case "single":
                try? entries.add(entry(daysBefore: 10, index: 0, now: now))
            case "reading-aging":
                try? entries.add(entry(minutesBefore: 118, now: now))
            case "report-short":
                DebugReportSeed.plantShort(entries: entries, medications: medications, now: now)
            case "report-long":
                DebugReportSeed.plantLong(entries: entries, medications: medications, now: now)
            case "report-sparse":
                DebugReportSeed.plantSparse(entries: entries, medications: medications, now: now)
            case "report-places-7":
                DebugReportSeed.plantPlacesSeven(entries: entries, medications: medications, now: now)
            case "report-basdai":
                DebugReportSeed.plantBasdai(entries: entries, medications: medications, basdai: basdai, now: now)
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
            entry(index: index, at: day(before: now, by: days))
        }

        private static func entry(minutesBefore minutes: Int, now: Date) -> Entry {
            entry(index: 0, at: now.addingTimeInterval(-TimeInterval(minutes) * 60))
        }

        private static func entry(index: Int, at date: Date) -> Entry {
            let kind = EntryKind.allCases[index % EntryKind.allCases.count]
            return Entry(
                id: UUID(),
                kind: kind,
                severity: Severity(index % 11) ?? Severity(nearestToFraction: 0),
                date: date,
                note: nil,
                places: []
            )
        }

        private static func day(before now: Date, by days: Int) -> Date {
            Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
        }
    }
#endif
