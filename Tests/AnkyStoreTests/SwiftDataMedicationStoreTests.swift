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
}
