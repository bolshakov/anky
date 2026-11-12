// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum EntriesCSV {
    public static let header = ["id", "time", "kind", "severity", "places", "note"]

    public static func table(_ entries: [Entry]) -> CSVTable {
        let sorted = entries.sorted { order(of: $0) < order(of: $1) }
        return CSVTable(header: header, rows: sorted.map(row))
    }

    /// The printed second, not the stored date, so rows in one printed second follow the id column.
    private static func order(of entry: Entry) -> (Double, String) {
        (entry.date.timeIntervalSince1970.rounded(.down), entry.id.uuidString)
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
