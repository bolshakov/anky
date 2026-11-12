// SPDX-License-Identifier: GPL-3.0-or-later
#if DEBUG
    import AnkyDomain
    import AnkyMedicationModel
    import Foundation

    /// Debug builds only, for the report walks: synthetic logs with known place counts and medication figures. Every
    /// record is dated within the last 80 days of `now`, so three and six months show the same data. A reading is a
    /// pain entry with no place, linked to its dose by id. `plantBasdai` adds three BASDAI results to the short log.
    @MainActor enum DebugReportSeed {
        static func plantShort(entries: EntryLogModel, medications: MedicationsModel, now: Date) {
            let seeder = Seeder(entries: entries, medications: medications, now: now)
            seeder.addEntries(shortRows)
            seeder.addMedications([zorblex, marvex, oldpill, quillen])
        }

        static func plantLong(entries: EntryLogModel, medications: MedicationsModel, now: Date) {
            let seeder = Seeder(entries: entries, medications: medications, now: now)
            seeder.addEntries(longRows)
            seeder.addMedications([zorblex, marvex, oldpill, quillen] + fillers)
        }

        static func plantBasdai(
            entries: EntryLogModel, medications: MedicationsModel, basdai: BasdaiModel, now: Date
        ) {
            plantShort(entries: entries, medications: medications, now: now)
            let results = [(2, [4, 6, 5, 3, 7, 2]), (20, [8, 7, 9, 6, 5, 10]), (50, [1, 2, 0, 3, 4, 5])]
            for (daysBefore, answers) in results {
                let date = Calendar.current.date(byAdding: .day, value: -daysBefore, to: now) ?? now
                guard let result = BasdaiResult(id: UUID(), date: date, answers: answers) else { continue }
                try? basdai.add(result)
            }
        }

        static func plantPlacesSeven(entries: EntryLogModel, medications: MedicationsModel, now: Date) {
            let dropped: Set = [place(.jaw), place(.knee, .left)]
            let seeder = Seeder(entries: entries, medications: medications, now: now)
            seeder
                .addEntries(longRows
                    .map { EntryRow(kind: $0.kind, places: $0.places.filter { !dropped.contains($0) }) })
            seeder.addMedications([zorblex, quillen])
        }

        static func plantSparse(entries: EntryLogModel, medications: MedicationsModel, now: Date) {
            let seeder = Seeder(entries: entries, medications: medications, now: now)
            seeder.addEntries([EntryRow(kind: .pain, places: []), EntryRow(kind: .fatigue, places: [])])
        }

        // MARK: - Entries

        private struct EntryRow {
            let kind: EntryKind
            let places: [PlaceID]
        }

        /// 24 entries, 16 of them placed: Lower back, Neck, Upper back and Left SI joint 4 each.
        private static var shortRows: [EntryRow] {
            let fourPlaces = [place(.lowerBack), place(.neck), place(.upperBack), place(.siJoint, .left)]
            var placed = 0
            return (0 ..< 24).map { index in
                let kind = EntryKind.allCases[index % EntryKind.allCases.count]
                guard kind.asksWhere else { return EntryRow(kind: kind, places: []) }
                defer { placed += 1 }
                return EntryRow(kind: kind, places: [fourPlaces[placed % fourPlaces.count]])
            }
        }

        /// 26 placed entries and 4 fatigue entries. Place mentions: Lower back 9, Neck 7, Left SI joint 6,
        /// Right SI joint 6, Upper back 4, Left hip 3, Ribs 2, Jaw 1, Left knee 1.
        private static var longRows: [EntryRow] {
            let lower = place(.lowerBack), neck = place(.neck), upper = place(.upperBack)
            let siLeft = place(.siJoint, .left), siRight = place(.siJoint, .right), hipLeft = place(.hip, .left)
            let ribs = place(.ribs), jaw = place(.jaw), kneeLeft = place(.knee, .left)
            let pairs: [[PlaceID]] = [[lower, siLeft], [lower, siRight], [lower, siLeft], [lower, siRight]]
                + [[neck, upper], [neck, upper], [siLeft, siRight], [siLeft, siRight], [lower, hipLeft]]
                + [[neck, ribs], [lower, ribs], [neck, jaw], [hipLeft, kneeLeft]]
            let singles: [[PlaceID]] = [[lower], [lower], [lower], [neck], [neck], [neck], [siLeft], [siLeft]]
                + [[siRight], [siRight], [upper], [upper], [hipLeft]]
            let placed = (pairs + singles).enumerated().map { index, places in
                EntryRow(kind: index.isMultiple(of: 2) ? .pain : .stiffness, places: places)
            }
            return placed + Array(repeating: EntryRow(kind: .fatigue, places: []), count: 4)
        }

        private static func place(_ joint: Joint, _ side: Side? = nil) -> PlaceID {
            side.flatMap(joint.place) ?? joint.places[0]
        }

        // MARK: - Medications

        private struct SeedDose {
            let daysBefore: Int
            var before: Int?
            var after: Int?
            var afterMinutes = 0
        }

        private struct SeedMedication {
            let name: String
            let strength: String
            var takenAs = TakenAs.asNeeded
            var isArchived = false
            let doses: [SeedDose]
        }

        private static let zorblex = SeedMedication(
            name: "Zorblex", strength: "50 mg",
            doses: [(3, 6, 3, 90), (18, 7, 4, 120), (33, 5, 2, 110), (48, 8, 5, 120)]
                .map { SeedDose(daysBefore: $0, before: $1, after: $2, afterMinutes: $3) }
                + [SeedDose(daysBefore: 63, before: 9)]
        )

        private static let marvex = SeedMedication(
            name: "Marvex", strength: "10 mg", takenAs: .scheduled,
            doses: [6, 26, 46, 66].map { SeedDose(daysBefore: $0) }
        )

        private static let oldpill = SeedMedication(
            name: "Oldpill", strength: "5 mg", isArchived: true,
            doses: [40, 55, 70].map { SeedDose(daysBefore: $0) }
        )

        private static let quillen = SeedMedication(
            name: "Quillen", strength: "20 mg",
            doses: [SeedDose(daysBefore: 10, before: 6, after: 3, afterMinutes: 45)]
                + [SeedDose(daysBefore: 50, before: 1)]
        )

        /// Every name sorts after "Quillen", so a filler with two doses never moves above it on a tie.
        private static var fillers: [SeedMedication] {
            let long = "Tarnevil slow release morning tablet with a long made up name to wrap"
            let names = ["Ravolin", "Restiva", "Sarpex", "Solvane", "Tembrid", long, "Torvala", "Ulvaxa"]
                + ["Vessiril", "Wendolan", "Xyrabel", "Yarvex"]
            return names.enumerated().map { index, name in
                let days = index.isMultiple(of: 2) ? [8 + 5 * index, 20 + 5 * index] : [12 + 5 * index]
                return SeedMedication(
                    name: name,
                    strength: "\(index + 1) mg",
                    doses: days.map { SeedDose(daysBefore: $0) }
                )
            }
        }

        // MARK: - Writing

        @MainActor private struct Seeder {
            let entries: EntryLogModel
            let medications: MedicationsModel
            let now: Date

            func addEntries(_ rows: [EntryRow]) {
                for (index, row) in rows.enumerated() {
                    add(kind: row.kind, severity: 2 + index % 7, at: day(2 + 2 * index), places: row.places)
                }
            }

            func addMedications(_ seeds: [SeedMedication]) {
                for seed in seeds {
                    var medication = Medication(id: UUID(), name: seed.name, takenAs: seed.takenAs, createdAt: day(80))
                    medication.strength = seed.strength
                    medication.archivedAt = seed.isArchived ? day(1) : nil
                    try? medications.add(medication)
                    for dose in seed.doses {
                        addDose(dose, of: medication.id)
                    }
                }
            }

            private func addDose(_ seed: SeedDose, of medicationID: UUID) {
                let takenAt = day(seed.daysBefore)
                var dose = Dose(id: UUID(), medicationID: medicationID, takenAt: takenAt)
                dose.beforeReadingID = seed.before.flatMap { reading($0, at: takenAt.addingTimeInterval(-10 * 60)) }
                dose.afterReadingID = seed.after.flatMap {
                    reading($0, at: takenAt.addingTimeInterval(TimeInterval(seed.afterMinutes * 60)))
                }
                try? medications.logDose(dose)
            }

            private func reading(_ severity: Int, at date: Date) -> UUID? {
                add(kind: .pain, severity: severity, at: date, places: [])
            }

            @discardableResult
            private func add(kind: EntryKind, severity: Int, at date: Date, places: [PlaceID]) -> UUID? {
                guard let severity = Severity(severity) else { return nil }
                let entry = Entry(id: UUID(), kind: kind, severity: severity, date: date, note: nil, places: places)
                return (try? entries.add(entry)).map { entry.id }
            }

            private func day(_ days: Int) -> Date {
                Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
            }
        }
    }
#endif
