// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
@testable import AnkyStore
import Foundation
import Testing

@MainActor
struct SwiftDataDoseRemovalTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private struct WriteRefused: Error {}

    private func withFolder<T>(_ body: (URL) throws -> T) throws -> T {
        let folder = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        return try body(folder)
    }

    private func medication(name: String = "Zorblex") -> Medication {
        var medication = Medication(id: UUID(), name: name, takenAs: .asNeeded, createdAt: date)
        medication.updatedAt = date.addingTimeInterval(60)
        return medication
    }

    private func fullDose(for medication: Medication) -> Dose {
        var dose = Dose(
            id: UUID(),
            medicationID: medication.id,
            takenAt: date.addingTimeInterval(120),
            beforeReadingID: UUID()
        )
        dose.checkInAfter = .oneHour
        dose.afterReadingID = UUID()
        return dose
    }

    @Test func removeDoseDeletesOnlyThatDoseAndKeepsEveryMedication() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            let zorblex = medication()
            let fennimax = medication(name: "Fennimax")
            let removed = fullDose(for: zorblex)
            let kept = Dose(id: UUID(), medicationID: fennimax.id, takenAt: date.addingTimeInterval(900))
            let store = try SwiftDataMedicationStore(url: url)
            try store.add(zorblex)
            try store.add(fennimax)
            try store.logDose(removed)
            try store.logDose(kept)
            let medicationsBefore = try store.all()

            try store.removeDose(id: removed.id)

            let reopened = try SwiftDataMedicationStore(url: url)
            #expect(try reopened.doses() == [kept])
            #expect(try reopened.all() == medicationsBefore)
        }
    }

    @Test func failedRemoveLeavesTheStoredDoseAsItWas() throws {
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
            let original = fullDose(for: zorblex)
            try store.logDose(original)

            writesRefused = true
            #expect(throws: MedicationStoreError.notSaved) { try store.removeDose(id: original.id) }
            #expect(try store.doses() == [original])
            #expect(try SwiftDataMedicationStore(url: url).doses() == [original])
        }
    }

    @Test func removingAnUnknownDoseThrowsAndDeletesNothing() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            let store = try SwiftDataMedicationStore(url: url)
            let zorblex = medication()
            try store.add(zorblex)
            let stored = fullDose(for: zorblex)
            try store.logDose(stored)

            #expect(throws: MedicationStoreError.notSaved) { try store.removeDose(id: UUID()) }
            #expect(try SwiftDataMedicationStore(url: url).doses() == [stored])
        }
    }
}
