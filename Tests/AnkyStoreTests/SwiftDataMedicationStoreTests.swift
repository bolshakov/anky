// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyStore
import Foundation
import Testing

@MainActor
struct SwiftDataMedicationStoreTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private struct WriteRefused: Error {}

    private func withFolder<T>(_ body: (URL) throws -> T) throws -> T {
        let folder = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        return try body(folder)
    }

    private func fullMedication(name: String = "Zorblex") -> Medication {
        var medication = Medication(id: UUID(), name: name, takenAs: .scheduled, createdAt: date)
        medication.strength = "250 mg"
        medication.checkInAfter = .twoHours
        medication.updatedAt = date.addingTimeInterval(60)
        medication.archivedAt = date.addingTimeInterval(120)
        return medication
    }

    @Test func reopenedStoreReadsBackEveryField() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            let full = fullMedication()
            let bare = Medication(
                id: UUID(),
                name: "Quibbanol",
                takenAs: .asNeeded,
                createdAt: date.addingTimeInterval(1)
            )
            let store = try SwiftDataMedicationStore(url: url)
            try store.add(full)
            try store.add(bare)
            let reopened = try SwiftDataMedicationStore(url: url)
            #expect(try reopened.all() == [full, bare])
        }
    }

    @Test func everyCheckInDelayReadsBackAfterReopen() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            let medications = CheckInDelay.allCases.enumerated().map { index, delay in
                var medication = Medication(
                    id: UUID(),
                    name: "Zorblex",
                    takenAs: .asNeeded,
                    createdAt: date.addingTimeInterval(TimeInterval(index))
                )
                medication.checkInAfter = delay
                return medication
            }
            let store = try SwiftDataMedicationStore(url: url)
            for medication in medications {
                try store.add(medication)
            }
            let reopened = try SwiftDataMedicationStore(url: url)
            #expect(try reopened.all() == medications)
        }
    }

    @Test func storeHoldsNoMedicationBeforeTheFirstAdd() throws {
        try withFolder { folder in
            let store = try SwiftDataMedicationStore(url: folder.appending(path: "medications.store"))
            #expect(try store.all().isEmpty)
        }
    }

    @Test func failedWriteLeavesStoreAsItWasAndRetrySavesOneRecord() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            var writesRefused = false
            let store = try SwiftDataMedicationStore(url: url, beforeSave: {
                if writesRefused {
                    throw WriteRefused()
                }
            })
            let existing = fullMedication(name: "Zorblex")
            try store.add(existing)

            let pending = fullMedication(name: "Quibbanol")
            writesRefused = true
            #expect(throws: MedicationStoreError.notSaved) { try store.add(pending) }
            #expect(try store.all() == [existing])
            #expect(try SwiftDataMedicationStore(url: url).all() == [existing])

            writesRefused = false
            try store.add(pending)
            #expect(try store.all() == [existing, pending])
            #expect(try SwiftDataMedicationStore(url: url).all() == [existing, pending])
        }
    }

    @Test func failedWriteOfTheSameIdSavesOneRecord() throws {
        try withFolder { folder in
            var writesRefused = true
            let store = try SwiftDataMedicationStore(url: folder.appending(path: "medications.store"), beforeSave: {
                if writesRefused {
                    throw WriteRefused()
                }
            })
            let medication = fullMedication()
            #expect(throws: MedicationStoreError.notSaved) { try store.add(medication) }
            writesRefused = false
            try store.add(medication)
            #expect(try store.all() == [medication])
        }
    }

    @Test func archiveSetsTheArchivedTimeAndChangesNoOtherField() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            let original = fullMedication(name: "Zorblex")
            var unarchived = original
            unarchived.archivedAt = nil
            let archivedAt = date.addingTimeInterval(300)
            var expected = unarchived
            expected.archivedAt = archivedAt

            let store = try SwiftDataMedicationStore(url: url)
            try store.add(unarchived)
            try store.archive(id: unarchived.id, at: archivedAt)
            #expect(try store.all() == [expected])
            #expect(try SwiftDataMedicationStore(url: url).all() == [expected])
        }
    }

    @Test func archiveOfAnUnknownIdThrowsAndChangesNothing() throws {
        try withFolder { folder in
            let store = try SwiftDataMedicationStore(url: folder.appending(path: "medications.store"))
            let zorblex = fullMedication(name: "Zorblex")
            try store.add(zorblex)
            #expect(throws: MedicationStoreError.notSaved) {
                try store.archive(id: UUID(), at: date)
            }
            #expect(try store.all() == [zorblex])
        }
    }

    @Test func failedArchiveLeavesTheMedicationActiveAndRetryArchivesIt() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            var writesRefused = false
            let store = try SwiftDataMedicationStore(url: url, beforeSave: {
                if writesRefused {
                    throw WriteRefused()
                }
            })
            var active = Medication(id: UUID(), name: "Zorblex", takenAs: .asNeeded, createdAt: date)
            active.updatedAt = date
            try store.add(active)

            writesRefused = true
            #expect(throws: MedicationStoreError.notSaved) {
                try store.archive(id: active.id, at: date.addingTimeInterval(60))
            }
            #expect(try store.all() == [active])
            #expect(try SwiftDataMedicationStore(url: url).all() == [active])

            writesRefused = false
            try store.archive(id: active.id, at: date.addingTimeInterval(60))
            var archived = active
            archived.archivedAt = date.addingTimeInterval(60)
            #expect(try store.all() == [archived])
        }
    }

    @Test func aFailedWriteThrowsAnErrorThatNamesNoMedication() throws {
        let store = try SwiftDataMedicationStore.inMemory(beforeSave: { throw WriteRefused() })
        let medication = fullMedication(name: "Zorblex")
        do {
            try store.add(medication)
            Issue.record("the write should have failed")
        } catch {
            let text = "\(error) \(error.localizedDescription) \((error as NSError).userInfo)"
            #expect(!text.contains("Zorblex"))
            #expect(!text.contains("250 mg"))
            #expect((error as NSError).userInfo.isEmpty)
        }
    }

    @Test func aDamagedStoreFileFailsToOpenAndIsLeftAsItWas() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            let damaged = Data("not a store".utf8)
            try damaged.write(to: url)
            #expect(throws: (any Error).self) {
                try SwiftDataMedicationStore(url: url)
            }
            #expect(try Data(contentsOf: url) == damaged)
        }
    }
}
