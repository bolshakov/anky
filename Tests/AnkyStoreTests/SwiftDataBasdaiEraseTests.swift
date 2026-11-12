// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyStore
import Foundation
import Testing

@MainActor
struct SwiftDataBasdaiEraseTests {
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
    private func seed(_ store: SwiftDataBasdaiStore) throws -> [BasdaiResult] {
        let results = try (0 ..< 3).map { day in
            try #require(BasdaiResult(
                id: UUID(),
                date: date.addingTimeInterval(Double(day) * 86400),
                answers: [day, 5, 6, 7, 3, 8]
            ))
        }
        try results.forEach { try store.add($0) }
        return results
    }

    private func refusingStore(url: URL, refused: @escaping @MainActor () -> Bool) throws -> SwiftDataBasdaiStore {
        try SwiftDataBasdaiStore(url: url, beforeSave: {
            if refused() {
                throw WriteRefused()
            }
        })
    }

    @Test func removeAllDeletesEveryResult() throws {
        try withFolder { folder in
            let url = folder.appending(path: "basdai.store")
            let store = try SwiftDataBasdaiStore(url: url)
            _ = try seed(store)

            try store.removeAll()

            #expect(try SwiftDataBasdaiStore(url: url).all().isEmpty)
        }
    }

    @Test func removeAllDeletesInOneCommit() throws {
        try withFolder { folder in
            var commits = 0
            let store = try SwiftDataBasdaiStore(url: folder.appending(path: "basdai.store"), beforeSave: {
                commits += 1
            })
            _ = try seed(store)
            let before = commits

            try store.removeAll()

            #expect(commits == before + 1)
        }
    }

    @Test func aRefusedRemoveAllKeepsEveryResult() throws {
        try withFolder { folder in
            let url = folder.appending(path: "basdai.store")
            var writesRefused = false
            let store = try refusingStore(url: url) { writesRefused }
            let kept = try seed(store)

            writesRefused = true
            #expect(throws: BasdaiStoreError.notSaved) { try store.removeAll() }

            #expect(try store.all() == kept)
            #expect(try SwiftDataBasdaiStore(url: url).all() == kept)
        }
    }

    @Test func removeAllCanBeRetriedAfterARefusal() throws {
        try withFolder { folder in
            let url = folder.appending(path: "basdai.store")
            var writesRefused = false
            let store = try refusingStore(url: url) { writesRefused }
            _ = try seed(store)
            writesRefused = true
            #expect(throws: BasdaiStoreError.notSaved) { try store.removeAll() }
            writesRefused = false

            try store.removeAll()

            #expect(try SwiftDataBasdaiStore(url: url).all().isEmpty)
        }
    }

    @Test func removeAllOnAnEmptyStoreSucceedsWithoutACommit() throws {
        try withFolder { folder in
            var commits = 0
            let store = try SwiftDataBasdaiStore(url: folder.appending(path: "basdai.store"), beforeSave: {
                commits += 1
            })

            try store.removeAll()

            #expect(commits == 0)
        }
    }
}
