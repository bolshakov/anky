// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public struct ExportData: Equatable, Sendable {
    public let entries: [Entry]
    public let medications: [Medication]
    public let doses: [Dose]

    public init(entries: [Entry], medications: [Medication], doses: [Dose]) {
        self.entries = entries
        self.medications = medications
        self.doses = doses
    }
}

public enum ExportArchive {
    public static let schemaVersion = 1

    private static let prefix = "anky-export-"
    private static let suffix = ".zip"

    /// The manifest counts the rows of the very tables written beside it, so the two cannot disagree.
    public static func files(
        _ data: ExportData, appVersion: String, build: String, exportedAt: Date
    ) throws -> [ZipFile] {
        let tables = tables(data)
        let manifest = ExportManifest(
            schemaVersion: schemaVersion,
            appVersion: appVersion,
            build: build,
            exportedAt: ExportTime.utc(exportedAt),
            files: tables.map { ExportManifest.FileRows(name: $0.name, rows: $0.table.rows.count) }
        )
        let csvs = tables.map { ZipFile(name: $0.name, data: Data($0.table.text.utf8)) }
        return try [ZipFile(name: "manifest.json", data: manifest.json)] + csvs
    }

    private static func tables(_ data: ExportData) -> [(name: String, table: CSVTable)] {
        [("entries.csv", EntriesCSV.table(data.entries)),
         ("medications.csv", MedicationsCSV.table(data.medications)),
         ("doses.csv", DosesCSV.table(data.doses, entries: data.entries))]
    }

    /// The person's calendar gives only the time zone, so the day is always written as a Gregorian date.
    public static func fileName(on date: Date, calendar: Calendar) -> String {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        let day = gregorian.dateComponents([.year, .month, .day], from: date)
        let stamp = String(format: "%04d-%02d-%02d", day.year ?? 0, day.month ?? 0, day.day ?? 0)
        return prefix + stamp + suffix
    }

    public static func isExportFileName(_ name: String) -> Bool {
        name.hasPrefix(prefix) && name.hasSuffix(suffix)
    }

    /// The name holds a whole archive or nothing, even when the write fails part way.
    public static func writeArchive( // swiftlint:disable:this function_parameter_count
        _ data: ExportData, appVersion: String, build: String, now: Date, calendar: Calendar, into folder: URL
    ) throws -> URL {
        // #lizard forgives
        let archive = try ZipWriter.archive(files(data, appVersion: appVersion, build: build, exportedAt: now))
        let file = folder.appendingPathComponent(fileName(on: now, calendar: calendar))
        try archive.write(to: file, options: .atomic)
        return file
    }

    public static func removeLeftovers(in folder: URL) throws {
        let manager = FileManager.default
        for name in try manager.contentsOfDirectory(atPath: folder.path) where isExportFileName(name) {
            try manager.removeItem(at: folder.appendingPathComponent(name))
        }
    }
}
