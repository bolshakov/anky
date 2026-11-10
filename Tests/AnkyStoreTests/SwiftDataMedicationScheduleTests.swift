// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
@testable import AnkyStore
import Foundation
import SwiftData
import Testing

/// The medication model as it was before schedules, so the file it writes has no schedule column.
enum LegacyMedicationSchema {
    @Model final class MedicationRecord {
        var id: UUID
        var name: String
        var strength: String?
        var takenAs: String
        var checkInAfterMinutes: Int?
        var createdAt: Date
        var updatedAt: Date
        var archivedAt: Date?

        init(id: UUID, name: String, strength: String?, takenAs: String, checkInAfterMinutes: Int?, createdAt: Date) {
            self.id = id
            self.name = name
            self.strength = strength
            self.takenAs = takenAs
            self.checkInAfterMinutes = checkInAfterMinutes
            self.createdAt = createdAt
            updatedAt = createdAt
        }
    }
}

@MainActor
struct SwiftDataMedicationScheduleTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func withFolder<T>(_ body: (URL) throws -> T) throws -> T {
        let folder = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        return try body(folder)
    }

    private func day(_ year: Int, _ month: Int, _ day: Int) throws -> ScheduleDay {
        try #require(ScheduleDay(year: year, month: month, day: day))
    }

    private func time(_ hour: Int, _ minute: Int) throws -> DoseTime {
        try #require(DoseTime(hour: hour, minute: minute))
    }

    private func schedules() throws -> [MedicationSchedule] {
        let daily = try MedicationSchedule(
            repeat: .days(3), times: [time(21, 30), time(8, 0)], start: day(2026, 11, 1), end: nil
        )
        let weekly = try MedicationSchedule(
            repeat: .weeks(2, on: [.monday, .thursday, .sunday]), times: [time(9, 15)],
            start: day(2026, 11, 2), end: day(2027, 3, 1)
        )
        let monthly = try MedicationSchedule(
            repeat: .months(1, onDay: 31), times: [time(7, 45)], start: day(2026, 12, 31), end: nil
        )
        return [daily, weekly, monthly]
    }

    private func scheduledMedication(_ schedule: MedicationSchedule) -> Medication {
        var medication = Medication(id: UUID(), name: "Zorblex", takenAs: .scheduled, createdAt: date)
        medication.schedule = schedule
        return medication
    }

    @Test func aScheduleSurvivesAddAndLoad() throws {
        for schedule in try schedules() {
            let store = try SwiftDataMedicationStore.inMemory()
            let medication = scheduledMedication(schedule)
            try store.add(medication)
            #expect(try store.all() == [medication])
        }
    }

    @Test func aScheduleSurvivesAFileReopen() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            let medications = try schedules().map(scheduledMedication)
            let store = try SwiftDataMedicationStore(url: url)
            for medication in medications {
                try store.add(medication)
            }
            #expect(try SwiftDataMedicationStore(url: url).all() == medications)
        }
    }

    @Test func aTimeListLoadsSortedWhateverOrderItWasSavedIn() throws {
        let store = try SwiftDataMedicationStore.inMemory()
        let medication = try scheduledMedication(schedules()[0])
        try store.add(medication)
        #expect(try store.all().first?.schedule?.times == [time(8, 0), time(21, 30)])
    }

    @Test func updateWritesAChangedScheduleAndRemovesOne() throws {
        let store = try SwiftDataMedicationStore.inMemory()
        let all = try schedules()
        var medication = scheduledMedication(all[0])
        try store.add(medication)
        medication.schedule = all[1]
        try store.update(medication)
        #expect(try store.all() == [medication])
        medication.schedule = nil
        try store.update(medication)
        #expect(try store.all() == [medication])
    }

    @Test func aScheduledMedicationWithNoScheduleSavesAndLoads() throws {
        let store = try SwiftDataMedicationStore.inMemory()
        var draft = MedicationDraft()
        draft.name = "Zorblex"
        draft.takenAs = .scheduled
        let medication = draft.medication(id: UUID(), at: date)
        try store.add(medication)
        let loaded = try #require(store.all().first)
        #expect(loaded == medication)
        #expect(loaded.takenAs == .scheduled)
        #expect(loaded.schedule == nil)
    }

    @Test func savingAScheduledMedicationAsNeededRemovesItsSchedule() throws {
        let store = try SwiftDataMedicationStore.inMemory()
        let original = try scheduledMedication(schedules()[1])
        try store.add(original)

        var draft = MedicationDraft(original)
        draft.takenAs = .asNeeded
        try store.update(draft.applied(to: original, at: date.addingTimeInterval(60)))

        let loaded = try #require(store.all().first)
        #expect(loaded.takenAs == .asNeeded)
        #expect(loaded.schedule == nil)
    }

    @Test func savingAScheduledMedicationAgainKeepsItsSchedule() throws {
        let store = try SwiftDataMedicationStore.inMemory()
        let original = try scheduledMedication(schedules()[2])
        try store.add(original)

        var draft = MedicationDraft(original)
        draft.name = "Quibbanol"
        try store.update(draft.applied(to: original, at: date.addingTimeInterval(60)))

        let loaded = try #require(store.all().first)
        #expect(loaded.name == "Quibbanol")
        #expect(loaded.schedule == original.schedule)
    }

    @Test func aStoreFromBeforeSchedulesOpensUnchangedWithNoSchedule() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            let legacy = LegacyMedicationSchema.MedicationRecord(
                id: UUID(), name: "Zorblex", strength: "250 mg", takenAs: "scheduled",
                checkInAfterMinutes: 120, createdAt: date
            )
            legacy.updatedAt = date.addingTimeInterval(60)
            legacy.archivedAt = date.addingTimeInterval(120)
            do {
                let container = try ModelContainer(
                    for: LegacyMedicationSchema.MedicationRecord.self, DoseRecord.self,
                    configurations: ModelConfiguration(url: url)
                )
                let context = ModelContext(container)
                context.insert(legacy)
                try context.save()
            }

            var expected = Medication(id: legacy.id, name: "Zorblex", takenAs: .scheduled, createdAt: date)
            expected.strength = "250 mg"
            expected.checkInAfter = .twoHours
            expected.updatedAt = date.addingTimeInterval(60)
            expected.archivedAt = date.addingTimeInterval(120)
            #expect(try SwiftDataMedicationStore(url: url).all() == [expected])
        }
    }

    private func storeHolding(_ stored: Data, at url: URL) throws -> SwiftDataMedicationStore {
        do {
            let container = try ModelContainer(
                for: MedicationRecord.self, DoseRecord.self, configurations: ModelConfiguration(url: url)
            )
            let context = ModelContext(container)
            let record = try MedicationRecord(Medication(
                id: UUID(),
                name: "Zorblex",
                takenAs: .scheduled,
                createdAt: date
            ))
            record.schedule = stored
            context.insert(record)
            try context.save()
        }
        return try SwiftDataMedicationStore(url: url)
    }

    private let readable = StoredSchedule(
        unit: "days", interval: 2, weekdays: [], dayOfMonth: nil, times: [.init(hour: 8, minute: 0)],
        start: .init(year: 2026, month: 11, day: 1), end: nil
    )

    @Test func aReadableStoredScheduleLoads() throws {
        try withFolder { folder in
            let store = try storeHolding(
                JSONEncoder().encode(readable),
                at: folder.appending(path: "medications.store")
            )
            #expect(try store.all().first?.schedule != nil)
        }
    }

    @Test func storedBytesThatAreNotAScheduleReadAsUnreadable() throws {
        try withFolder { folder in
            let store = try storeHolding(Data("not json".utf8), at: folder.appending(path: "medications.store"))
            #expect(throws: MedicationStoreError.unreadable) { try store.all() }
        }
    }

    private func refusedSchedules() -> [(reason: String, stored: StoredSchedule)] {
        var refused: [(reason: String, stored: StoredSchedule)] = []
        func refuse(_ reason: String, _ change: (inout StoredSchedule) -> Void) {
            var copy = readable
            change(&copy)
            refused.append((reason, copy))
        }
        refuse("zero interval") { $0.interval = 0 }
        refuse("unknown unit") { $0.unit = "years" }
        refuse("weeks without weekdays") { $0.unit = "weeks" }
        refuse("unknown weekday") { $0.unit = "weeks"; $0.weekdays = [8] }
        refuse("months without a day") { $0.unit = "months" }
        refuse("day of month 32") { $0.unit = "months"; $0.dayOfMonth = 32 }
        refuse("no times") { $0.times = [] }
        refuse("time 24:00") { $0.times = [.init(hour: 24, minute: 0)] }
        refuse("start 30 February") { $0.start = .init(year: 2026, month: 2, day: 30) }
        refuse("end 30 February") { $0.end = .init(year: 2027, month: 2, day: 30) }
        return refused
    }

    @Test func aStoredScheduleTheDomainRefusesReadsAsUnreadable() throws {
        for (reason, refused) in refusedSchedules() {
            try withFolder { folder in
                let store = try storeHolding(
                    JSONEncoder().encode(refused),
                    at: folder.appending(path: "medications.store")
                )
                #expect(throws: MedicationStoreError.unreadable, "\(reason)") { try store.all() }
            }
        }
    }
}
