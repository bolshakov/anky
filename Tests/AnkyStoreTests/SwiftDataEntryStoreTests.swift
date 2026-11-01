// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
@testable import AnkyStore
import Foundation
import SwiftData
import Testing

@MainActor
struct SwiftDataEntryStoreTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private struct WriteRefused: Error {}

    private func withFolder<T>(_ body: (URL) throws -> T) throws -> T {
        let folder = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        return try body(folder)
    }

    private func entry(
        id: UUID = UUID(),
        kind: EntryKind = .pain,
        severity: Int = 4,
        date: Date? = nil,
        note: String? = nil,
        places: [PlaceID] = []
    ) throws -> Entry {
        try Entry(
            id: id,
            kind: kind,
            severity: #require(Severity(severity)),
            date: date ?? self.date,
            note: note,
            places: places
        )
    }

    private func writeRecord(_ record: EntryRecord, to url: URL) throws {
        let container = try ModelContainer(for: EntryRecord.self, configurations: ModelConfiguration(url: url))
        container.mainContext.insert(record)
        try container.mainContext.save()
    }

    @Test func reopenedStoreReadsBackEveryField() throws {
        try withFolder { folder in
            let url = folder.appending(path: "entries.store")
            let note = "First paragraph, Ünïcödé 🙂\n\nSecond: 痛み\n  third line  "
            let unknown = PlaceID(rawValue: "tentacle")
            let full = try entry(
                kind: .stiffness,
                severity: 7,
                date: date.addingTimeInterval(0.5),
                note: note,
                places: [unknown, PlaceID(rawValue: "jaw"), PlaceID(rawValue: "lower")]
            )
            let bare = try entry(kind: .fatigue, severity: 0, date: date.addingTimeInterval(60))
            let store = try SwiftDataEntryStore(url: url)
            try store.add(full)
            try store.add(bare)

            let reopened = try SwiftDataEntryStore(url: url)

            #expect(try reopened.load() == [full, bare])
            #expect(try reopened.load().first?.places.last == unknown)
        }
    }

    @Test func aNewStoreAtANewURLReadsNoEntries() throws {
        try withFolder { folder in
            let first = try SwiftDataEntryStore(url: folder.appending(path: "first.store"))
            try first.add(entry())

            let second = try SwiftDataEntryStore(url: folder.appending(path: "second.store"))

            #expect(try second.load().isEmpty)
        }
    }

    @Test func refusedAddLeavesTheSameStoreReadingAsItWas() throws {
        try withFolder { folder in
            var refuses = false
            let store = try SwiftDataEntryStore(url: folder.appending(path: "entries.store")) {
                if refuses {
                    throw WriteRefused()
                }
            }
            let kept = try entry(severity: 2)
            try store.add(kept)
            refuses = true
            let refused = try entry(severity: 9)

            #expect(throws: EntryStoreError.notSaved) { try store.add(refused) }

            #expect(try store.load() == [kept])
            refuses = false
            try store.add(refused)
            #expect(try store.load() == [kept, refused])
        }
    }

    @Test func refusedReplaceLeavesTheSameStoreReadingAsItWas() throws {
        try withFolder { folder in
            var refuses = false
            let store = try SwiftDataEntryStore(url: folder.appending(path: "entries.store")) {
                if refuses {
                    throw WriteRefused()
                }
            }
            let kept = try entry(severity: 2)
            try store.add(kept)
            refuses = true

            #expect(throws: EntryStoreError.notSaved) { try store.replace(entry(id: kept.id, severity: 8)) }

            #expect(try store.load() == [kept])
        }
    }

    @Test func refusedRemoveLeavesTheSameStoreReadingAsItWas() throws {
        try withFolder { folder in
            var refuses = false
            let store = try SwiftDataEntryStore(url: folder.appending(path: "entries.store")) {
                if refuses {
                    throw WriteRefused()
                }
            }
            let kept = try entry(severity: 2)
            try store.add(kept)
            refuses = true

            #expect(throws: EntryStoreError.notSaved) { try store.remove(id: kept.id) }

            #expect(try store.load() == [kept])
        }
    }

    @Test func inMemoryStoreRollsBackARefusedWriteToo() throws {
        var refuses = false
        let store = try SwiftDataEntryStore.inMemory {
            if refuses {
                throw WriteRefused()
            }
        }
        let kept = try entry(severity: 2)
        try store.add(kept)
        refuses = true

        #expect(throws: EntryStoreError.notSaved) { try store.add(entry(severity: 9)) }

        #expect(try store.load() == [kept])
    }

    @Test func saveOrderSurvivesDatesThatRunBackwards() throws {
        try withFolder { folder in
            let url = folder.appending(path: "entries.store")
            let first = try entry(date: date.addingTimeInterval(120))
            let second = try entry(date: date.addingTimeInterval(60))
            let third = try entry(date: date)
            let store = try SwiftDataEntryStore(url: url)
            try store.add(first)
            try store.add(second)
            try store.add(third)

            #expect(try SwiftDataEntryStore(url: url).load() == [first, second, third])
        }
    }

    @Test func deletingTheNewestThenAddingKeepsTheNewOneLast() throws {
        try withFolder { folder in
            let url = folder.appending(path: "entries.store")
            let first = try entry()
            let second = try entry()
            let newest = try entry()
            let added = try entry()
            let store = try SwiftDataEntryStore(url: url)
            try store.add(first)
            try store.add(second)
            try store.add(newest)

            try store.remove(id: newest.id)
            try store.add(added)

            #expect(try SwiftDataEntryStore(url: url).load() == [first, second, added])
        }
    }

    @Test func replaceLeavesEveryOtherRecordAsItWas() throws {
        try withFolder { folder in
            let url = folder.appending(path: "entries.store")
            let first = try entry()
            let middle = try entry()
            let last = try entry()
            let store = try SwiftDataEntryStore(url: url)
            try store.add(first)
            try store.add(middle)
            try store.add(last)
            let changed = try entry(id: middle.id, kind: .fatigue, severity: 8)

            try store.replace(changed)

            #expect(try SwiftDataEntryStore(url: url).load() == [first, changed, last])
        }
    }

    @Test func anEntryMovedToYesterdayKeepsItsPlaceInSaveOrderAfterReopen() throws {
        try withFolder { folder in
            let url = folder.appending(path: "entries.store")
            let first = try entry()
            let moved = try entry()
            let store = try SwiftDataEntryStore(url: url)
            try store.add(first)
            try store.add(moved)
            let yesterday = try entry(id: moved.id, date: date.addingTimeInterval(-86400))

            try store.replace(yesterday)

            #expect(try SwiftDataEntryStore(url: url).load() == [first, yesterday])
        }
    }

    @Test func aSecondAddOfAKnownIdLeavesOneRecord() throws {
        try withFolder { folder in
            let url = folder.appending(path: "entries.store")
            let id = UUID()
            let store = try SwiftDataEntryStore(url: url)
            try store.add(entry(id: id, severity: 3))

            try store.add(entry(id: id, severity: 9))

            #expect(try SwiftDataEntryStore(url: url).load().count == 1)
        }
    }

    @Test func aRecordWithAnUnreadableKindLoadsAsUnreadable() throws {
        try withFolder { folder in
            let url = folder.appending(path: "entries.store")
            try writeRecord(
                EntryRecord(id: UUID(), kind: "headache", severity: 4, date: date, note: nil, places: [], position: 0),
                to: url
            )

            #expect(throws: EntryStoreError.unreadable) { try SwiftDataEntryStore(url: url).load() }
        }
    }

    @Test func aRecordWithAnUnreadableLevelLoadsAsUnreadable() throws {
        try withFolder { folder in
            let url = folder.appending(path: "entries.store")
            try writeRecord(
                EntryRecord(id: UUID(), kind: "pain", severity: 11, date: date, note: nil, places: [], position: 0),
                to: url
            )

            #expect(throws: EntryStoreError.unreadable) { try SwiftDataEntryStore(url: url).load() }
        }
    }
}
