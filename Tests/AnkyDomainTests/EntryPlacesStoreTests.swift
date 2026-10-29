import AnkyDomain
import Foundation
import Testing

struct EntryPlacesStoreTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)
    private let lower = PlaceID(rawValue: "lower")
    private let siLeft = PlaceID(rawValue: "si_l")

    private func entry(places: [PlaceID]) throws -> Entry {
        var draft = try EntryDraft(severity: #require(Severity(4)), date: date)
        draft.kind = .pain
        for place in places {
            draft.togglePlace(place)
        }
        return Entry(draft: draft)
    }

    private func withFolder<T>(_ body: (URL) throws -> T) throws -> T {
        let folder = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        return try body(folder)
    }

    private func jsonObject(at fileURL: URL) throws -> [String: Any] {
        try #require(JSONSerialization.jsonObject(with: Data(contentsOf: fileURL)) as? [String: Any])
    }

    @Test func placesSurviveAReloadFromTheFile() throws {
        try withFolder { folder in
            let store = FileEntryStore(fileURL: folder.appending(path: "entries.json"), protection: .deviceDefault)
            try store.save([entry(places: [lower, siLeft])])
            #expect(try store.load().map(\.places) == [[lower, siLeft]])
        }
    }

    @Test func aSavedFileWritesPlacesAsAnArrayOfTheRawIds() throws {
        try withFolder { folder in
            let fileURL = folder.appending(path: "entries.json")
            let store = FileEntryStore(fileURL: fileURL, protection: .deviceDefault)
            try store.save([entry(places: [lower, siLeft])])

            let saved = try jsonObject(at: fileURL)
            let entries = try #require(saved["entries"] as? [[String: Any]])
            #expect(entries.first?["places"] as? [String] == ["lower", "si_l"])
            let text = try String(contentsOf: fileURL, encoding: .utf8)
            #expect(text.contains("\"si_l\""))
            #expect(!text.contains("siJoint"))
        }
    }

    @Test func aVersionOneFileWithoutPlacesStillLoads() throws {
        try withFolder { folder in
            let fileURL = folder.appending(path: "entries.json")
            let file = #"""
            {
              "entries": [
                {"id": "\#(UUID())", "kind": "pain", "severity": 4, "date": "2026-10-26T08:15:00Z"}
              ],
              "version": 1
            }
            """#
            try Data(file.utf8).write(to: fileURL)
            let store = FileEntryStore(fileURL: fileURL, protection: .deviceDefault)

            #expect(try store.load().map(\.places) == [[]])
        }
    }

    @Test func anIdThisBuildDoesNotKnowSurvivesALoadAndASave() throws {
        try withFolder { folder in
            let fileURL = folder.appending(path: "entries.json")
            let file = #"""
            {
              "entries": [
                {
                  "id": "\#(UUID())", "kind": "pain", "severity": 4, "date": "2026-10-26T08:15:00Z",
                  "places": ["lower", "tentacle"]
                }
              ],
              "version": 1
            }
            """#
            try Data(file.utf8).write(to: fileURL)
            let store = FileEntryStore(fileURL: fileURL, protection: .deviceDefault)

            try store.save(store.load())

            let tentacle = PlaceID(rawValue: "tentacle")
            #expect(try store.load().map(\.places) == [[lower, tentacle]])
            let text = try String(contentsOf: fileURL, encoding: .utf8)
            #expect(text.contains("\"tentacle\""))
        }
    }

    @Test func theFileVersionStaysOne() throws {
        try withFolder { folder in
            let fileURL = folder.appending(path: "entries.json")
            let store = FileEntryStore(fileURL: fileURL, protection: .deviceDefault)
            try store.save([entry(places: [lower])])

            #expect(try jsonObject(at: fileURL)["version"] as? Int == 1)
        }
    }

    @Test func aKnownIdIsNeverRewrittenWhenAnEntryIsSavedAgain() throws {
        try withFolder { folder in
            let fileURL = folder.appending(path: "entries.json")
            let file = #"""
            {
              "entries": [
                {
                  "id": "\#(UUID())", "kind": "pain", "severity": 4, "date": "2026-10-26T08:15:00Z",
                  "places": ["lower", "si_l", "jaw"]
                }
              ],
              "version": 1
            }
            """#
            try Data(file.utf8).write(to: fileURL)
            let store = FileEntryStore(fileURL: fileURL, protection: .deviceDefault)

            let loaded = try store.load()
            try store.save(loaded)
            let reloaded = try store.load()

            #expect(reloaded.map { $0.places.map(\.rawValue) } == [["lower", "si_l", "jaw"]])
            #expect(reloaded == loaded)
        }
    }
}
