// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum EntriesCSV {
    public static let header = ["id", "time", "kind", "severity", "places", "note"]

    public static func table(_ entries: [Entry]) -> CSVTable {
        let sorted = entries.sorted { ($0.date, $0.id.uuidString) < ($1.date, $1.id.uuidString) }
        return CSVTable(header: header, rows: sorted.map(row))
    }

    private static func row(_ entry: Entry) -> [CSVCell] {
        let time = ExportTime.utc(entry.date)
        let places = entry.places.map(\.rawValue).joined(separator: ";")
        let named: [CSVCell] = [.text(entry.id.uuidString), .text(time), .text(entry.kind.rawValue)]
        return named + [.number(entry.severity.value), textOrEmpty(places), textOrEmpty(entry.note ?? "")]
    }

    private static func textOrEmpty(_ value: String) -> CSVCell {
        value.isEmpty ? .empty : .text(value)
    }
}
