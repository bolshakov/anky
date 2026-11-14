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
    /// BASDAI results to the `report-short` log. `basdai-rows` writes one entry a minute back, two BASDAI results two
    /// and three minutes back scored 3.0 and 6.5, and one result three days back. `today-full` writes 14 entries dated
    /// today, each at or before now, so Today's list scrolls. A log that holds anything is left alone.
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
            case "today-full":
                plantTodayFull(entries: entries, now: now)
            case "reading-aging":
                try? entries.add(entry(minutesBefore: 118, now: now))
            case "basdai-rows":
                plantBasdaiRows(entries: entries, basdai: basdai, now: now)
            case "schedule-months":
                plantScheduleMonths(medications: medications, now: now)
            default:
                plantReport(entries: entries, medications: medications, basdai: basdai, now: now)
            }
        }

        private static func plantReport(
            entries: EntryLogModel, medications: MedicationsModel, basdai: BasdaiModel, now: Date
        ) {
            switch ProcessInfo.processInfo.environment["ANKY_SEED"] {
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

        private static func plantTodayFull(entries: EntryLogModel, now: Date) {
            let sinceMidnight = now.timeIntervalSince(Calendar.current.startOfDay(for: now))
            for index in 0 ..< 14 {
                let date = now.addingTimeInterval(-sinceMidnight * Double(index) / 14)
                try? entries.add(entry(index: index, at: date))
            }
        }

        private static func plantBasdaiRows(entries: EntryLogModel, basdai: BasdaiModel, now: Date) {
            try? entries.add(entry(minutesBefore: 1, now: now))
            addResult([3, 3, 3, 3, 3, 3], at: now.addingTimeInterval(-2 * 60), to: basdai)
            addResult([7, 7, 6, 6, 7, 6], at: now.addingTimeInterval(-3 * 60), to: basdai)
            addResult([5, 5, 5, 5, 5, 5], at: day(before: now, by: 3), to: basdai)
        }

        private static func addResult(_ answers: [Int], at date: Date, to basdai: BasdaiModel) {
            guard let result = BasdaiResult(id: UUID(), date: date, answers: answers) else { return }
            try? basdai.add(result)
        }

        private static func plantScheduleMonths(medications: MedicationsModel, now: Date) {
            guard medications.medications.isEmpty else { return }
            let monthly = [("Monthly five", ScheduleRepeat.months(5, onDay: 31)), ("Monthly two", .months(2, onDay: 3))]
            for (name, repetition) in monthly {
                guard let time = DoseTime(hour: 9, minute: 0),
                      let schedule = try? MedicationSchedule(
                          repeat: repetition,
                          times: [time],
                          start: ScheduleDay(now, in: Calendar.current.timeZone),
                          end: nil
                      ) else { continue }
                var medication = Medication(id: UUID(), name: name, takenAs: .scheduled, createdAt: now)
                medication.schedule = schedule
                try? medications.add(medication)
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
