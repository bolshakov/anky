// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
@testable import AnkyStore
import Foundation
import Testing

@MainActor
struct SwiftDataMedicationEraseTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private struct WriteRefused: Error {}

    private func withFolder<T>(_ body: (URL) throws -> T) throws -> T {
        let folder = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        return try body(folder)
    }

    private func medication(name: String) -> Medication {
        Medication(id: UUID(), name: name, takenAs: .asNeeded, createdAt: date)
    }

    private func dose(for medication: Medication, minutes: Double) -> Dose {
        Dose(id: UUID(), medicationID: medication.id, takenAt: date.addingTimeInterval(minutes * 60))
    }

    private func seed(_ store: SwiftDataMedicationStore) throws -> (medications: [Medication], doses: [Dose]) {
        let zorblex = medication(name: "Zorblex")
        let fennimax = medication(name: "Fennimax")
        let doses = [dose(for: zorblex, minutes: 1), dose(for: zorblex, minutes: 2), dose(for: fennimax, minutes: 3)]
        try store.add(zorblex)
        try store.add(fennimax)
        try doses.forEach { try store.logDose($0) }
        return ([zorblex, fennimax], doses)
    }

    @Test func removeAllDeletesEveryMedicationAndDose() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            let store = try SwiftDataMedicationStore(url: url)
            _ = try seed(store)

            try store.removeAll()

            let reopened = try SwiftDataMedicationStore(url: url)
            #expect(try reopened.all().isEmpty)
            #expect(try reopened.doses().isEmpty)
        }
    }

    @Test func removeAllDeletesInOneCommit() throws {
        try withFolder { folder in
            var commits = 0
            let store = try SwiftDataMedicationStore(url: folder.appending(path: "medications.store"), beforeSave: {
                commits += 1
            })
            _ = try seed(store)
            let before = commits

            try store.removeAll()

            #expect(commits == before + 1)
        }
    }

    @Test func aRefusedRemoveAllKeepsEveryMedicationAndDose() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            var writesRefused = false
            let store = try SwiftDataMedicationStore(url: url, beforeSave: {
                if writesRefused {
                    throw WriteRefused()
                }
            })
            let kept = try seed(store)

            writesRefused = true
            #expect(throws: MedicationStoreError.notSaved) { try store.removeAll() }

            #expect(try store.all() == kept.medications)
            #expect(try store.doses() == kept.doses)
            let reopened = try SwiftDataMedicationStore(url: url)
            #expect(try reopened.all() == kept.medications)
            #expect(try reopened.doses() == kept.doses)
        }
    }

    @Test func removeAllCanBeRetriedAfterARefusal() throws {
        try withFolder { folder in
            let url = folder.appending(path: "medications.store")
            var writesRefused = false
            let store = try SwiftDataMedicationStore(url: url, beforeSave: {
                if writesRefused {
                    throw WriteRefused()
                }
            })
            _ = try seed(store)
            writesRefused = true
            #expect(throws: MedicationStoreError.notSaved) { try store.removeAll() }
            writesRefused = false

            try store.removeAll()

            let reopened = try SwiftDataMedicationStore(url: url)
            #expect(try reopened.all().isEmpty)
            #expect(try reopened.doses().isEmpty)
        }
    }

    @Test func removeAllOnAnEmptyStoreSucceedsWithoutACommit() throws {
        try withFolder { folder in
            var commits = 0
            let store = try SwiftDataMedicationStore(url: folder.appending(path: "medications.store"), beforeSave: {
                commits += 1
            })

            try store.removeAll()

            #expect(commits == 0)
        }
    }
}
