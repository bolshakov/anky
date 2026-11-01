// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
@testable import AnkyStore
import Foundation
import SwiftData
import Testing

@MainActor
struct SwiftDataDoseTests {
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
            painBefore: Severity(6)!,
            checkInAfter: .oneHour
        )
        dose.painAfter = Severity(3)!
        dose.checkedInAt = date.addingTimeInterval(3720)
        return dose
    }

    @Test func reopenedStoreReadsBackEveryDoseField() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            let zorblex = medication()
            let dose = fullDose(for: zorblex)
            let store = try SwiftDataMedicationStore(url: url)
            try store.add(zorblex)
            try store.logDose(dose)

            let reopened = try SwiftDataMedicationStore(url: url)
            #expect(try reopened.doses() == [dose])
        }
    }

    @Test func logDoseSetsTheSavedDelayAndLeavesTheUpdatedTime() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            let zorblex = medication()
            let dose = fullDose(for: zorblex)
            let store = try SwiftDataMedicationStore(url: url)
            try store.add(zorblex)
            try store.logDose(dose)

            var expected = zorblex
            expected.checkInAfter = .oneHour
            #expect(try SwiftDataMedicationStore(url: url).all() == [expected])
        }
    }

    @Test func failedDoseWriteLeavesDosesAndSavedDelayAsTheyWere() throws {
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

            writesRefused = true
            #expect(throws: MedicationStoreError.notSaved) { try store.logDose(fullDose(for: zorblex)) }
            #expect(try store.doses().isEmpty)
            #expect(try store.all() == [zorblex])
            #expect(try SwiftDataMedicationStore(url: url).doses().isEmpty)
            #expect(try SwiftDataMedicationStore(url: url).all() == [zorblex])
        }
    }

    @Test func doseForAnUnknownMedicationThrowsAndLeavesNoPendingRow() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            let store = try SwiftDataMedicationStore(url: url)
            let zorblex = medication()
            try store.add(zorblex)

            let orphan = fullDose(for: medication(name: "Quibbanol"))
            #expect(throws: MedicationStoreError.notSaved) { try store.logDose(orphan) }
            #expect(try store.doses().isEmpty)

            try store.add(medication(name: "Fennimax"))
            #expect(try SwiftDataMedicationStore(url: url).doses().isEmpty)
        }
    }

    @Test func storeFileWrittenWithOnlyMedicationsOpensWithThemAndNoDoses() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            let zorblex = medication()
            do {
                let container = try ModelContainer(
                    for: MedicationRecord.self,
                    configurations: ModelConfiguration(url: url)
                )
                let context = ModelContext(container)
                context.insert(MedicationRecord(zorblex))
                try context.save()
            }

            let store = try SwiftDataMedicationStore(url: url)
            #expect(try store.all() == [zorblex])
            #expect(try store.doses().isEmpty)
        }
    }
}
