// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyStore
import Foundation
import Testing

@MainActor
struct SwiftDataReadingMemoryTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private struct WriteRefused: Error {}

    private func withFolder<T>(_ body: (URL) throws -> T) throws -> T {
        let folder = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        return try body(folder)
    }

    private func medication(remembering memory: ReadingMemory? = nil) -> Medication {
        var medication = Medication(id: UUID(), name: "Zorblex", takenAs: .asNeeded, createdAt: date)
        medication.readingMemory = memory
        return medication
    }

    private func dose(for medication: Medication) -> Dose {
        Dose(id: UUID(), medicationID: medication.id, takenAt: date.addingTimeInterval(120))
    }

    @Test(arguments: [ReadingMemory.none, .entry])
    func aRememberedChoiceReadsBackAfterReopening(memory: ReadingMemory) throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            let zorblex = medication()
            let store = try SwiftDataMedicationStore(url: url)
            try store.add(zorblex)
            try store.logDose(dose(for: zorblex), remembering: memory)

            var expected = zorblex
            expected.readingMemory = memory
            #expect(try store.all() == [expected])
            #expect(try SwiftDataMedicationStore(url: url).all() == [expected])
        }
    }

    @Test func aMedicationAddedWithAChoiceKeepsItOnReopening() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            let zorblex = medication(remembering: .entry)
            try SwiftDataMedicationStore(url: url).add(zorblex)
            #expect(try SwiftDataMedicationStore(url: url).all() == [zorblex])
        }
    }

    @Test(arguments: [ReadingMemory?.none, .some(.none), .entry])
    func loggingWithNoChoiceLeavesTheStoredChoiceAsItWas(stored: ReadingMemory?) throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            let zorblex = medication(remembering: stored)
            let store = try SwiftDataMedicationStore(url: url)
            try store.add(zorblex)
            try store.logDose(dose(for: zorblex), remembering: nil)
            try store.logDose(dose(for: zorblex))

            #expect(try SwiftDataMedicationStore(url: url).all() == [zorblex])
            #expect(try SwiftDataMedicationStore(url: url).doses().count == 2)
        }
    }

    @Test func aNewChoiceReplacesTheStoredOne() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            let zorblex = medication(remembering: ReadingMemory.none)
            let store = try SwiftDataMedicationStore(url: url)
            try store.add(zorblex)
            try store.logDose(dose(for: zorblex), remembering: .entry)

            var expected = zorblex
            expected.readingMemory = .entry
            #expect(try SwiftDataMedicationStore(url: url).all() == [expected])
        }
    }

    @Test func aFailedSaveLeavesNoChoiceAndARetryWritesIt() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            var writesRefused = false
            let store = try SwiftDataMedicationStore(url: url, beforeSave: {
                if writesRefused {
                    throw WriteRefused()
                }
            })
            let zorblex = medication()
            try store.add(zorblex)
            let taken = dose(for: zorblex)

            writesRefused = true
            #expect(throws: MedicationStoreError.notSaved) { try store.logDose(taken, remembering: ReadingMemory.none) }
            #expect(try store.all() == [zorblex])
            #expect(try SwiftDataMedicationStore(url: url).all() == [zorblex])
            #expect(try store.doses().isEmpty)

            writesRefused = false
            try store.logDose(taken, remembering: ReadingMemory.none)
            var expected = zorblex
            expected.readingMemory = ReadingMemory.none
            #expect(try SwiftDataMedicationStore(url: url).all() == [expected])
            #expect(try SwiftDataMedicationStore(url: url).doses() == [taken])
        }
    }

    @Test func aDoseForAnUnknownMedicationRemembersNothing() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            let store = try SwiftDataMedicationStore(url: url)
            let zorblex = medication()
            try store.add(zorblex)

            #expect(throws: MedicationStoreError.notSaved) {
                try store.logDose(dose(for: medication()), remembering: .entry)
            }
            #expect(try SwiftDataMedicationStore(url: url).all() == [zorblex])
        }
    }

    @Test func replacingADoseLeavesTheStoredChoiceAlone() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            let zorblex = medication()
            let store = try SwiftDataMedicationStore(url: url)
            try store.add(zorblex)
            let taken = dose(for: zorblex)
            try store.logDose(taken, remembering: ReadingMemory.none)

            var edited = taken
            edited.beforeReadingID = UUID()
            try store.replaceDose(edited)

            var expected = zorblex
            expected.readingMemory = ReadingMemory.none
            #expect(try SwiftDataMedicationStore(url: url).all() == [expected])
            #expect(try SwiftDataMedicationStore(url: url).doses() == [edited])
        }
    }

    @Test func editingTheMedicationFromTheManageDraftKeepsTheChoice() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            let zorblex = medication()
            let store = try SwiftDataMedicationStore(url: url)
            try store.add(zorblex)
            try store.logDose(dose(for: zorblex), remembering: .entry)
            let stored = try #require(try store.all().first)

            var draft = MedicationDraft(stored)
            draft.name = "Quibbanol"
            draft.takenAs = .scheduled
            draft.schedule = try MedicationSchedule(
                repeat: .days(1), times: [#require(DoseTime(hour: 9, minute: 0))],
                start: #require(ScheduleDay(year: 2026, month: 11, day: 11)), end: nil
            )
            let edited = draft.applied(to: stored, at: date.addingTimeInterval(500))
            try store.update(edited)

            let reopened = try #require(try SwiftDataMedicationStore(url: url).all().first)
            #expect(reopened.name == "Quibbanol")
            #expect(reopened.readingMemory == .entry)
        }
    }

    @Test func updateWritesTheChoiceTheMedicationCarries() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            let zorblex = medication(remembering: .entry)
            let store = try SwiftDataMedicationStore(url: url)
            try store.add(zorblex)

            var cleared = zorblex
            cleared.readingMemory = nil
            try store.update(cleared)
            #expect(try SwiftDataMedicationStore(url: url).all() == [cleared])

            var remembered = zorblex
            remembered.readingMemory = ReadingMemory.none
            try store.update(remembered)
            #expect(try SwiftDataMedicationStore(url: url).all() == [remembered])
        }
    }

    @Test func anArchivedMedicationKeepsItsChoice() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            let zorblex = medication(remembering: ReadingMemory.none)
            let store = try SwiftDataMedicationStore(url: url)
            try store.add(zorblex)
            try store.archive(id: zorblex.id, at: date.addingTimeInterval(60))
            #expect(try SwiftDataMedicationStore(url: url).all().first?.readingMemory == ReadingMemory.none)
            try store.restore(id: zorblex.id)
            #expect(try SwiftDataMedicationStore(url: url).all().first?.readingMemory == ReadingMemory.none)
        }
    }

    @Test func aDeletedMedicationTakesItsChoiceWithIt() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            let zorblex = medication(remembering: .entry)
            let store = try SwiftDataMedicationStore(url: url)
            try store.add(zorblex)
            try store.removeAll()

            let replacement = Medication(id: zorblex.id, name: "Zorblex", takenAs: .asNeeded, createdAt: date)
            try store.add(replacement)
            #expect(try SwiftDataMedicationStore(url: url).all() == [replacement])
        }
    }
}
