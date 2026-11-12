// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum DosesCSV {
    public static let header = ["id", "logged_at", "medication_id", "time_taken"]
        + ["pain_before", "pain_after", "after_time"]

    public static func table(_ doses: [Dose], entries: [Entry]) -> CSVTable {
        let readings = Dictionary(entries.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let sorted = doses.sorted { order(of: $0) < order(of: $1) }
        return CSVTable(header: header, rows: sorted.map { row($0, readings: readings) })
    }

    /// The printed second, not the stored date, so rows in one printed second follow the id column.
    private static func order(of dose: Dose) -> (Double, String) {
        (dose.takenAt.timeIntervalSince1970.rounded(.down), dose.id.uuidString)
    }

    private static func row(_ dose: Dose, readings: [UUID: Entry]) -> [CSVCell] {
        let before = dose.beforeReadingID.flatMap { readings[$0] }
        let after = dose.afterReadingID.flatMap { readings[$0] }
        let logged = dose.loggedAt.map { CSVCell.text(ExportTime.utc($0)) } ?? .empty
        let named: [CSVCell] = [.text(dose.id.uuidString), logged, .text(dose.medicationID.uuidString)]
        let pains = [before, after].map { $0.map { CSVCell.number($0.severity.value) } ?? .empty }
        let afterTime = after.map { CSVCell.text(ExportTime.utc($0.date)) } ?? .empty
        return named + [.text(ExportTime.utc(dose.takenAt))] + pains + [afterTime]
    }
}
