// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct ExportArchiveTests {
    private let morning = Date(timeIntervalSince1970: 1_762_848_900)

    private func sample() throws -> ExportData {
        let pain = try Entry(
            id: #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001")),
            kind: .pain, severity: #require(Severity(4)), date: morning, note: "Synthetic note", places: []
        )
        let stiffness = try Entry(
            id: #require(UUID(uuidString: "00000000-0000-0000-0000-000000000002")),
            kind: .stiffness, severity: #require(Severity(6)), date: morning.addingTimeInterval(60), note: nil,
            places: []
        )
        let medication = try Medication(
            id: #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")),
            name: "Zorblex", takenAs: .asNeeded, createdAt: morning
        )
        let doses = try ["00000000-0000-0000-0000-0000000000D1", "00000000-0000-0000-0000-0000000000D2"].map {
            try Dose(id: #require(UUID(uuidString: $0)), medicationID: medication.id, takenAt: morning)
        }
        return ExportData(entries: [pain, stiffness], medications: [medication], doses: doses)
    }

    private func files(_ data: ExportData, at date: Date? = nil) throws -> [ZipFile] {
        try ExportArchive.files(data, appVersion: "1.2", build: "34", exportedAt: date ?? morning)
    }

    private func manifest(_ files: [ZipFile]) throws -> ExportManifest {
        try JSONDecoder().decode(ExportManifest.self, from: #require(files.first).data)
    }

    /// The data of a stored zip's first file, read from its local header.
    private func firstFile(_ zip: Data) -> Data {
        let bytes = [UInt8](zip)
        let little = { (at: Int, count: Int) in (0 ..< count).reduce(0) { $0 | Int(bytes[at + $1]) << (8 * $1) } }
        let start = 30 + little(26, 2) + little(28, 2)
        return Data(bytes[start ..< start + little(18, 4)])
    }

    private func calendar(_ zone: String) throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: zone))
        return calendar
    }

    private func moment(_ text: String) throws -> Date {
        try Date(text, strategy: .iso8601)
    }

    @Test func holdsTheManifestThenTheThreeTablesInOrder() throws {
        let names = try files(sample()).map(\.name)
        #expect(names == ["manifest.json", "entries.csv", "medications.csv", "doses.csv"])
    }

    @Test func writesEachTableAsItsCSVText() throws {
        let data = try sample()
        let texts = try files(data).dropFirst().map { try #require(String(bytes: $0.data, encoding: .utf8)) }
        let tables = [EntriesCSV.table(data.entries), MedicationsCSV.table(data.medications),
                      DosesCSV.table(data.doses, entries: data.entries)]
        #expect(texts == tables.map(\.text))
    }

    @Test func manifestNamesTheVersionsTheMomentAndEachFilesDataRows() throws {
        let manifest = try manifest(files(sample()))
        #expect(manifest.schemaVersion == 1)
        #expect(ExportArchive.schemaVersion == 1)
        #expect(manifest.appVersion == "1.2")
        #expect(manifest.build == "34")
        #expect(manifest.exportedAt == "2025-11-11T08:15:00Z")
        #expect(manifest.files.map(\.name) == ["entries.csv", "medications.csv", "doses.csv"])
        #expect(manifest.files.map(\.rows) == [2, 1, 2])
    }

    @Test func manifestCountsZeroRowsForAnEmptyExport() throws {
        let empty = ExportData(entries: [], medications: [], doses: [])
        #expect(try manifest(files(empty)).files.map(\.rows) == [0, 0, 0])
    }

    @Test func manifestUsesSnakeCaseKeysInSortedOrder() throws {
        let manifestFile = try #require(files(sample()).first)
        let text = try #require(String(bytes: manifestFile.data, encoding: .utf8))
        let keys = text.split(separator: "\n").filter { $0.hasPrefix("  \"") }.map { $0.split(separator: "\"")[1] }
        #expect(keys == ["app_version", "build", "exported_at", "files", "schema_version"])
        #expect(text.contains("\"rows\" : 2"))
    }

    @Test func sameDataGivesTheSameBytesButForTheExportMoment() throws {
        let data = try sample()
        let first = try files(data)
        let later = try files(data, at: morning.addingTimeInterval(86400 + 5))
        #expect(first.dropFirst() == later.dropFirst())
        let lines = try [first, later]
            .map { try #require(String(bytes: $0[0].data, encoding: .utf8)).split(separator: "\n") }
        let differing = zip(lines[0], lines[1]).filter { $0 != $1 }.map(\.1)
        #expect(lines[0].count == lines[1].count)
        #expect(differing == ["  \"exported_at\" : \"2025-11-12T08:15:05Z\","])
        #expect(try files(data) == first)
    }

    @Test(arguments: [("Asia/Tokyo", "2026-11-11T14:59:00Z", "anky-export-2026-11-11.zip"),
                      ("Asia/Tokyo", "2026-11-11T15:01:00Z", "anky-export-2026-11-12.zip"),
                      ("America/Los_Angeles", "2026-11-12T07:59:00Z", "anky-export-2026-11-11.zip"),
                      ("America/Los_Angeles", "2026-11-12T08:01:00Z", "anky-export-2026-11-12.zip")])
    func namesTheFileByTheLocalDay(zone: String, utc: String, expected: String) throws {
        #expect(try ExportArchive.fileName(on: moment(utc), calendar: calendar(zone)) == expected)
    }

    @Test(arguments: [Calendar.Identifier.buddhist, .japanese, .islamicUmmAlQura])
    func namesTheFileByTheGregorianDayWhateverThePersonsCalendar(identifier: Calendar.Identifier) throws {
        var calendar = Calendar(identifier: identifier)
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let name = try ExportArchive.fileName(on: moment("2026-11-11T15:01:00Z"), calendar: calendar)
        #expect(name == "anky-export-2026-11-12.zip")
    }

    @Test func exportJustAfterLocalMidnightTakesTheNewDayWhileTheManifestStaysInUTC() throws {
        let folder = try TemporaryFolder()
        let now = try moment("2026-11-11T15:01:00Z")
        let file = try ExportArchive.writeArchive(
            sample(), appVersion: "1.2", build: "34", now: now, calendar: calendar("Asia/Tokyo"), into: folder.url
        )
        #expect(file.lastPathComponent == "anky-export-2026-11-12.zip")
        #expect(try JSONDecoder().decode(ExportManifest.self, from: firstFile(Data(contentsOf: file))).exportedAt
            == "2026-11-11T15:01:00Z")
    }

    @Test(arguments: [("anky-export-2026-11-11.zip", true),
                      ("anky-export-.zip", true),
                      ("anky-export.zip", false),
                      ("anky-export.txt", false),
                      ("anky-export-2026-11-11.zip.txt", false),
                      ("other.zip", false),
                      ("my-anky-export-2026-11-11.zip", false)])
    func recognisesOnlyExportFileNames(name: String, expected: Bool) {
        #expect(ExportArchive.isExportFileName(name) == expected)
    }

    @Test func writesTheZipOfTheFilesIntoTheFolderUnderTheDaysName() throws {
        let folder = try TemporaryFolder()
        let data = try sample()
        let file = try ExportArchive.writeArchive(
            data, appVersion: "1.2", build: "34", now: morning, calendar: calendar("UTC"), into: folder.url
        )
        #expect(file == folder.url.appendingPathComponent("anky-export-2025-11-11.zip"))
        #expect(try Data(contentsOf: file) == ZipWriter.archive(files(data)))
    }

    @Test func replacesAnEarlierExportOfTheSameDay() throws {
        let folder = try TemporaryFolder()
        let earlier = folder.url.appendingPathComponent("anky-export-2025-11-11.zip")
        try Data("stale".utf8).write(to: earlier)
        let file = try ExportArchive.writeArchive(
            sample(), appVersion: "1.2", build: "34", now: morning, calendar: calendar("UTC"), into: folder.url
        )
        #expect(try Data(contentsOf: file) == ZipWriter.archive(files(sample())))
        #expect(try folder.names() == ["anky-export-2025-11-11.zip"])
    }

    @Test func aWriteIntoAReadOnlyFolderThrowsAndLeavesNoFile() throws {
        let folder = try TemporaryFolder()
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: folder.url.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: folder.url.path) }
        #expect(throws: (any Error).self) {
            try ExportArchive.writeArchive(
                sample(), appVersion: "1.2", build: "34", now: morning, calendar: calendar("UTC"), into: folder.url
            )
        }
        #expect(try folder.names() == [])
    }

    @Test func sweepRemovesExportFilesAndLeavesEverythingElse() throws {
        let folder = try TemporaryFolder()
        let names = ["anky-export-2025-11-10.zip", "anky-export-2025-11-11.zip", "other.zip", "anky-export.txt"]
        for name in names {
            try Data("x".utf8).write(to: folder.url.appendingPathComponent(name))
        }
        let nested = folder.url.appendingPathComponent("nested")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: false)
        try Data("x".utf8).write(to: nested.appendingPathComponent("anky-export-2025-11-09.zip"))
        try ExportArchive.removeLeftovers(in: folder.url)
        #expect(try folder.names() == ["anky-export.txt", "nested", "other.zip"])
        #expect(FileManager.default
            .fileExists(atPath: nested.appendingPathComponent("anky-export-2025-11-09.zip").path))
    }

    @Test func sweepOfAFolderWithNoExportsChangesNothing() throws {
        let folder = try TemporaryFolder()
        try ExportArchive.removeLeftovers(in: folder.url)
        #expect(try folder.names() == [])
    }
}

/// A folder of its own under the test's temporary directory, removed when the value goes away.
private final class TemporaryFolder {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory.appendingPathComponent("anky-export-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }

    func names() throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: url.path).sorted()
    }
}
