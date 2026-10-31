// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct TipProgressTests {
    private let tail = PlaceID(rawValue: "tail")
    private let jaw = PlaceID(rawValue: "jaw")
    private let neck = PlaceID(rawValue: "neck")

    private func withFolder<T>(_ body: (URL) throws -> T) throws -> T {
        let folder = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        return try body(folder)
    }

    @Test func theThirdVisitMakesTheTipReady() {
        var progress = TipProgress()
        progress.recordVisit()
        progress.recordVisit()
        progress.recordVisit()
        #expect(progress.visits == 3)
        #expect(progress.isReady)
    }

    @Test func twoVisitsAreNotEnough() {
        var progress = TipProgress()
        progress.recordVisit()
        progress.recordVisit()
        #expect(progress.visits == 2)
        #expect(!progress.isReady)
    }

    @Test func visitsSurviveAReload() throws {
        try withFolder { folder in
            let fileURL = folder.appending(path: "tip-progress.json")
            var progress = TipProgress()
            progress.recordVisit()
            progress.recordVisit()
            try FileTipProgressStore(fileURL: fileURL, protection: .deviceDefault).save(progress)
            let reloaded = FileTipProgressStore(fileURL: fileURL, protection: .deviceDefault).load()
            #expect(reloaded.visits == 2)
            #expect(reloaded == progress)
        }
    }

    @Test func theThirdPickOfOnePlaceMakesTheTipReady() {
        var progress = TipProgress()
        progress.recordPick(tail)
        progress.recordPick(tail)
        #expect(!progress.isReady)
        progress.recordPick(tail)
        #expect(progress.picks["tail"] == 3)
        #expect(progress.isReady)
    }

    @Test func picksOfDifferentPlacesAreNotAdded() {
        var progress = TipProgress()
        progress.recordPick(tail)
        progress.recordPick(jaw)
        progress.recordPick(neck)
        #expect(progress.picks == ["tail": 1, "jaw": 1, "neck": 1])
        #expect(!progress.isReady)
    }

    @Test func aPickThatClearsAPlaceIsNotCounted() {
        var progress = TipProgress()
        progress.recordPick(tail)
        progress.recordPick(tail)
        #expect(progress.picks["tail"] == 2)
        #expect(!progress.isReady)
    }

    @Test func picksSurviveAReload() throws {
        try withFolder { folder in
            let fileURL = folder.appending(path: "tip-progress.json")
            var progress = TipProgress()
            progress.recordPick(tail)
            progress.recordPick(tail)
            progress.recordPick(jaw)
            try FileTipProgressStore(fileURL: fileURL, protection: .deviceDefault).save(progress)
            let reloaded = FileTipProgressStore(fileURL: fileURL, protection: .deviceDefault).load()
            #expect(reloaded.picks == ["tail": 2, "jaw": 1])
            #expect(reloaded == progress)
        }
    }

    @Test func aMissingFileGivesAnEmptyProgress() throws {
        try withFolder { folder in
            let store = FileTipProgressStore(
                fileURL: folder.appending(path: "tip-progress.json"),
                protection: .complete
            )
            #expect(store.load() == TipProgress())
        }
    }

    @Test func anUnreadableOrNewerFileGivesAnEmptyProgress() throws {
        try withFolder { folder in
            let fileURL = folder.appending(path: "tip-progress.json")
            let store = FileTipProgressStore(fileURL: fileURL, protection: .complete)
            try Data("not a progress file".utf8).write(to: fileURL)
            #expect(store.load() == TipProgress())
            try Data(#"{"version":2,"visits":5,"picks":{"tail":4}}"#.utf8).write(to: fileURL)
            #expect(store.load() == TipProgress())
        }
    }

    @Test func theFileHoldsAVersionVisitsAndPicks() throws {
        try withFolder { folder in
            let fileURL = folder.appending(path: "tip-progress.json")
            var progress = TipProgress()
            progress.recordVisit()
            progress.recordPick(tail)
            try FileTipProgressStore(fileURL: fileURL, protection: .deviceDefault).save(progress)
            let object = try JSONSerialization.jsonObject(with: Data(contentsOf: fileURL)) as? [String: Any]
            #expect(object?["version"] as? Int == 1)
            #expect(object?["visits"] as? Int == 1)
            #expect((object?["picks"] as? [String: Int]) == ["tail": 1])
        }
    }
}
