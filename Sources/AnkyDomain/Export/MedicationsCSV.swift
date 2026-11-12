// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum MedicationsCSV {
    public static let header = ["id", "created_at", "updated_at", "name", "strength", "how_taken"]
        + ["check_in_delay_minutes", "archived_at", "repeat_unit", "repeat_every", "weekdays", "day_of_month"]
        + ["times", "starts", "ends"]

    public static func table(_ medications: [Medication]) -> CSVTable {
        let sorted = medications.sorted { order(of: $0) < order(of: $1) }
        return CSVTable(header: header, rows: sorted.map { named($0) + scheduleColumns($0) })
    }

    /// The printed second, not the stored date, so rows in one printed second follow the id column.
    private static func order(of medication: Medication) -> (Double, String) {
        (medication.createdAt.timeIntervalSince1970.rounded(.down), medication.id.uuidString)
    }

    private static func named(_ medication: Medication) -> [CSVCell] {
        let times: [CSVCell] = [medication.createdAt, medication.updatedAt].map { .text(ExportTime.utc($0)) }
        let howTaken = medication.takenAs == .scheduled ? "scheduled" : "as_needed"
        let delay = medication.checkInAfter.map { CSVCell.number($0.rawValue) } ?? .empty
        let archived = medication.archivedAt.map { CSVCell.text(ExportTime.utc($0)) } ?? .empty
        let strength = medication.strength.map(CSVCell.text) ?? .empty
        let id = CSVCell.text(medication.id.uuidString)
        return [id] + times + [.text(medication.name), strength, .text(howTaken), delay, archived]
    }

    private static func scheduleColumns(_ medication: Medication) -> [CSVCell] {
        guard medication.takenAs == .scheduled, let schedule = medication.schedule else {
            return Array(repeating: .empty, count: 7)
        }
        let times = schedule.times.map { String(format: "%02d:%02d", $0.hour, $0.minute) }.joined(separator: ";")
        let dates = [schedule.start, schedule.end].map { $0.map { .text(day($0)) } ?? CSVCell.empty }
        return repeatColumns(schedule.repeat) + [.text(times)] + dates
    }

    private static func repeatColumns(_ repetition: ScheduleRepeat) -> [CSVCell] {
        switch repetition {
        case let .days(interval):
            [.text("days"), .number(interval), .empty, .empty]
        case let .weeks(interval, weekdays):
            [.text("weeks"), .number(interval), .text(spelled(weekdays)), .empty]
        case let .months(interval, day):
            [.text("months"), .number(interval), .empty, .number(day)]
        }
    }

    private static let weekdayNames: [(Locale.Weekday, String)] = [(.monday, "mon"), (.tuesday, "tue")]
        + [(.wednesday, "wed"), (.thursday, "thu"), (.friday, "fri"), (.saturday, "sat"), (.sunday, "sun")]

    private static func spelled(_ weekdays: Set<Locale.Weekday>) -> String {
        weekdayNames.filter { weekdays.contains($0.0) }.map(\.1).joined(separator: ";")
    }

    private static func day(_ day: ScheduleDay) -> String {
        String(format: "%04d-%02d-%02d", day.year, day.month, day.day)
    }
}
