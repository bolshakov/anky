// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum BasdaiCSV {
    public static let header = ["id", "created_at", "updated_at", "date"]
        + ["q1", "q2", "q3", "q4", "q5", "q6", "score"]

    public static func table(_ results: [BasdaiResult]) -> CSVTable {
        let sorted = results.sorted { order(of: $0) < order(of: $1) }
        return CSVTable(header: header, rows: sorted.map(row))
    }

    /// The printed second, not the stored date, so rows in one printed second follow the id column.
    private static func order(of result: BasdaiResult) -> (Double, String) {
        (result.date.timeIntervalSince1970.rounded(.down), result.id.uuidString)
    }

    /// The phone's language never reaches the file, so the score always has a dot.
    private static func row(_ result: BasdaiResult) -> [CSVCell] {
        let moments = [result.createdAt, result.updatedAt, result.date].map { CSVCell.text(ExportTime.utc($0)) }
        let score = BasdaiScore.text(of: result, locale: Locale(identifier: "en_US_POSIX"))
        return [.text(result.id.uuidString)] + moments + result.answers.map { CSVCell.number($0) } + [.bare(score)]
    }
}
