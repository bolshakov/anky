// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
@testable import AnkyStore
import Foundation
import SwiftData
import Testing

@MainActor
struct SwiftDataBasdaiStoreTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private struct WriteRefused: Error {}

    private func withFolder<T>(_ body: (URL) throws -> T) throws -> T {
        let folder = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        return try body(folder)
    }

    /// Synthetic answers, never a real person's.
    private func result(days: Double = 0, createdAfter seconds: Double = 0) throws -> BasdaiResult {
        let day = date.addingTimeInterval(days * 86400)
        var result = try #require(BasdaiResult(id: UUID(), date: day, answers: [4, 5, 6, 7, 3, 8]))
        result.createdAt = day.addingTimeInterval(seconds)
        result.updatedAt = result.createdAt
        return result
    }

    private func refusingStore(url: URL, refused: @escaping @MainActor () -> Bool) throws -> SwiftDataBasdaiStore {
        try SwiftDataBasdaiStore(url: url, beforeSave: {
            if refused() {
                throw WriteRefused()
            }
        })
    }

    @Test func reopenedStoreReadsBackEveryField() throws {
        try withFolder { folder in
            let url = folder.appending(path: "basdai.store")
            var full = try #require(BasdaiResult(id: UUID(), date: date, answers: [0, 10, 1, 9, 2, 8]))
            full.createdAt = date.addingTimeInterval(60)
            full.updatedAt = date.addingTimeInterval(120)
            try SwiftDataBasdaiStore(url: url).add(full)

            #expect(try SwiftDataBasdaiStore(url: url).all() == [full])
        }
    }

    @Test func storeHoldsNoResultBeforeTheFirstAdd() throws {
        try withFolder { folder in
            let store = try SwiftDataBasdaiStore(url: folder.appending(path: "basdai.store"))
            #expect(try store.all().isEmpty)
        }
    }

    @Test func allSortsByDateThenCreatedTime() throws {
        let store = try SwiftDataBasdaiStore.inMemory()
        let newest = try result(days: 2)
        let laterSameDay = try result(days: 1, createdAfter: 30)
        let earlierSameDay = try result(days: 1, createdAfter: 10)
        let backdated = try result(days: 0, createdAfter: 3 * 86400)
        for added in [laterSameDay, newest, backdated, earlierSameDay] {
            try store.add(added)
        }

        #expect(try store.all() == [backdated, earlierSameDay, laterSameDay, newest])
    }

    @Test func failedAddLeavesStoreAsItWasAndRetrySavesOneRecord() throws {
        try withFolder { folder in
            let url = folder.appending(path: "basdai.store")
            var writesRefused = true
            let store = try refusingStore(url: url) { writesRefused }
            let added = try result()

            #expect(throws: BasdaiStoreError.notSaved) { try store.add(added) }
            #expect(try store.all().isEmpty)
            writesRefused = false
            try store.add(added)

            #expect(try SwiftDataBasdaiStore(url: url).all() == [added])
        }
    }

    @Test(arguments: [[4, 5, 6, 7, 3], [4, 5, 6, 7, 3, 8, 2], [4, 5, 6, 7, 3, 11]])
    func aResultWithoutSixAnswersFromZeroToTenIsNotSaved(answers: [Int]) throws {
        let store = try SwiftDataBasdaiStore.inMemory()
        var invalid = try result()
        invalid.answers = answers

        #expect(throws: BasdaiStoreError.notSaved) { try store.add(invalid) }
        #expect(try store.all().isEmpty)
    }

    @Test func removeDeletesOnlyThatResult() throws {
        try withFolder { folder in
            let url = folder.appending(path: "basdai.store")
            let store = try SwiftDataBasdaiStore(url: url)
            let kept = try result(days: 0)
            let removed = try result(days: 1)
            try store.add(kept)
            try store.add(removed)

            try store.remove(id: removed.id)

            #expect(try SwiftDataBasdaiStore(url: url).all() == [kept])
        }
    }

    @Test func removeOfAnUnknownIDIsNotSaved() throws {
        let store = try SwiftDataBasdaiStore.inMemory()
        try store.add(result())

        #expect(throws: BasdaiStoreError.notSaved) { try store.remove(id: UUID()) }
    }

    @Test func aRefusedRemoveKeepsTheResult() throws {
        try withFolder { folder in
            let url = folder.appending(path: "basdai.store")
            var writesRefused = false
            let store = try refusingStore(url: url) { writesRefused }
            let kept = try result()
            try store.add(kept)

            writesRefused = true
            #expect(throws: BasdaiStoreError.notSaved) { try store.remove(id: kept.id) }

            #expect(try store.all() == [kept])
            #expect(try SwiftDataBasdaiStore(url: url).all() == [kept])
        }
    }

    @Test(arguments: [-1, 11])
    func aStoredAnswerOutsideZeroToTenIsUnreadable(answer: Int) throws {
        try withFolder { folder in
            let url = folder.appending(path: "basdai.store")
            let record = try BasdaiRecord(result())
            record.q3 = answer
            let container = try ModelContainer(for: BasdaiRecord.self, configurations: ModelConfiguration(url: url))
            container.mainContext.insert(record)
            try container.mainContext.save()

            #expect(throws: BasdaiStoreError.unreadable) { try SwiftDataBasdaiStore(url: url).all() }
        }
    }

    @Test func resultsGoToTheirOwnFileAndLeaveTheOtherStoresAsTheyWere() throws {
        try withFolder { folder in
            let severity = try #require(Severity(4))
            let entry = Entry(id: UUID(), kind: .pain, severity: severity, date: date, note: nil, places: [])
            let medication = Medication(id: UUID(), name: "Zorblex", takenAs: .asNeeded, createdAt: date)
            let entries = folder.appending(path: "entries.store")
            let medications = folder.appending(path: "medications.store")
            let basdai = folder.appending(path: "basdai.store")
            try SwiftDataEntryStore(url: entries).add(entry)
            try SwiftDataMedicationStore(url: medications).add(medication)
            let saved = try result()

            try SwiftDataBasdaiStore(url: basdai).add(saved)

            #expect(try SwiftDataBasdaiStore(url: basdai).all() == [saved])
            #expect(try SwiftDataEntryStore(url: entries).load() == [entry])
            #expect(try SwiftDataMedicationStore(url: medications).all() == [medication])
        }
    }
}
