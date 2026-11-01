// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyStore
import Foundation
import Testing

@MainActor
struct SwiftDataMedicationEditTests {
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

    @Test func updateWritesEveryEditableFieldAndKeepsTheIdAndCreatedTime() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            let original = fullMedication(name: "Zorblex")
            var edited = original
            edited.name = "Quibbanol"
            edited.strength = nil
            edited.takenAs = .asNeeded
            edited.checkInAfter = .fourHours
            edited.updatedAt = date.addingTimeInterval(500)
            edited.archivedAt = nil

            let store = try SwiftDataMedicationStore(url: url)
            try store.add(original)
            try store.update(edited)
            #expect(try store.all() == [edited])
            #expect(try SwiftDataMedicationStore(url: url).all() == [edited])
        }
    }

    @Test func updateOfAnUnknownIdThrowsAndChangesNothing() throws {
        try withFolder { folder in
            let store = try SwiftDataMedicationStore(url: folder.appending(path: "medications.store"))
            let zorblex = fullMedication(name: "Zorblex")
            try store.add(zorblex)
            #expect(throws: MedicationStoreError.notSaved) {
                try store.update(fullMedication(name: "Quibbanol"))
            }
            #expect(try store.all() == [zorblex])
        }
    }

    @Test func failedUpdateLeavesTheMedicationAsItWasAndRetrySavesOneChange() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            var writesRefused = false
            let store = try SwiftDataMedicationStore(url: url, beforeSave: {
                if writesRefused {
                    throw WriteRefused()
                }
            })
            let original = fullMedication(name: "Zorblex")
            try store.add(original)

            var edited = original
            edited.strength = "50 mg"
            writesRefused = true
            #expect(throws: MedicationStoreError.notSaved) { try store.update(edited) }
            #expect(try store.all() == [original])
            #expect(try SwiftDataMedicationStore(url: url).all() == [original])

            writesRefused = false
            try store.update(edited)
            #expect(try store.all() == [edited])
            #expect(try SwiftDataMedicationStore(url: url).all() == [edited])
        }
    }

    @Test func restoreClearsTheArchivedTimeAndKeepsEveryOtherField() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            let archived = fullMedication(name: "Zorblex")
            var restored = archived
            restored.archivedAt = nil

            let store = try SwiftDataMedicationStore(url: url)
            try store.add(archived)
            try store.restore(id: archived.id)
            #expect(try store.all() == [restored])
            #expect(try SwiftDataMedicationStore(url: url).all() == [restored])
        }
    }

    @Test func restoreOfAnUnknownIdThrowsAndChangesNothing() throws {
        try withFolder { folder in
            let store = try SwiftDataMedicationStore(url: folder.appending(path: "medications.store"))
            let zorblex = fullMedication(name: "Zorblex")
            try store.add(zorblex)
            #expect(throws: MedicationStoreError.notSaved) { try store.restore(id: UUID()) }
            #expect(try store.all() == [zorblex])
        }
    }

    @Test func failedRestoreLeavesTheMedicationArchivedAndRetryRestoresIt() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            var writesRefused = false
            let store = try SwiftDataMedicationStore(url: url, beforeSave: {
                if writesRefused {
                    throw WriteRefused()
                }
            })
            let archived = fullMedication(name: "Zorblex")
            try store.add(archived)

            writesRefused = true
            #expect(throws: MedicationStoreError.notSaved) { try store.restore(id: archived.id) }
            #expect(try store.all() == [archived])
            #expect(try SwiftDataMedicationStore(url: url).all() == [archived])

            writesRefused = false
            try store.restore(id: archived.id)
            var restored = archived
            restored.archivedAt = nil
            #expect(try store.all() == [restored])
        }
    }
}
