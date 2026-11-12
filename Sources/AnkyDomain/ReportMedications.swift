// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public struct ReportPainRange: Equatable, Sendable {
    public let average: Double
    public let lowest: Int
    public let highest: Int
    public let count: Int

    public init(average: Double, lowest: Int, highest: Int, count: Int) {
        self.average = average
        self.lowest = lowest
        self.highest = highest
        self.count = count
    }

    init?(_ values: [Int]) {
        guard let lowest = values.min(), let highest = values.max() else { return nil }
        self.init(
            average: Double(values.reduce(0, +)) / Double(values.count),
            lowest: lowest,
            highest: highest,
            count: values.count
        )
    }
}

/// Pain and time figures come only from the doses that have both a before and an after reading, so a dose missing
/// either one cannot skew the comparison.
public struct ReportMedicationRow: Equatable, Sendable {
    public let medication: Medication
    public let doseCount: Int
    public let perWeek: Double
    public let afterReadingCount: Int
    public let before: ReportPainRange?
    public let after: ReportPainRange?
    public let averageTimeToAfter: TimeInterval?

    private struct Paired {
        let before: Entry
        let after: Entry
        let gap: TimeInterval
    }

    init(medication: Medication, doses: [Dose], entries: EntriesByID, weeks: Double) {
        let readings = doses.map { (dose: $0, readings: DoseReadings($0, in: entries)) }
        let paired = readings.compactMap { dose, readings -> Paired? in
            guard let before = readings.before, let after = readings.after else { return nil }
            return Paired(before: before, after: after, gap: max(0, after.date.timeIntervalSince(dose.takenAt)))
        }
        self.medication = medication
        doseCount = doses.count
        perWeek = Double(doses.count) / weeks
        afterReadingCount = readings.count { $0.readings.after != nil }
        before = ReportPainRange(paired.map(\.before.severity.value))
        after = ReportPainRange(paired.map(\.after.severity.value))
        averageTimeToAfter = paired.isEmpty ? nil : paired.map(\.gap).reduce(0, +) / Double(paired.count)
    }
}

/// One row per medication, archived ones included, with a dose taken from the period's start to `now`, both ends
/// included. A dose of a medication missing from `medications` adds no row.
public struct ReportMedications: Equatable, Sendable {
    public let rows: [ReportMedicationRow]

    public var hasScheduled: Bool {
        rows.contains { $0.medication.takenAs == .scheduled }
    }

    public init(
        medications: [Medication], doses: [Dose], entries: [Entry], period: ReportPeriod, now: Date, calendar: Calendar
    ) {
        // #lizard forgives
        let range = period.start(endingAt: now, calendar: calendar) ... now
        let dosesByMedication = Dictionary(grouping: doses.filter { range.contains($0.takenAt) }, by: \.medicationID)
        let weeks = Double(Self.days(in: range, calendar: calendar)) / 7
        let entriesByID = EntriesByID(entries)
        rows = medications
            .compactMap { medication in
                dosesByMedication[medication.id].map {
                    ReportMedicationRow(medication: medication, doses: $0, entries: entriesByID, weeks: weeks)
                }
            }
            .sorted(by: Self.readsFirst)
    }

    private static func days(in range: ClosedRange<Date>, calendar: Calendar) -> Int {
        let first = calendar.startOfDay(for: range.lowerBound)
        let last = calendar.startOfDay(for: range.upperBound)
        return (calendar.dateComponents([.day], from: first, to: last).day ?? 0) + 1
    }

    /// Equal dose counts fall back to name and then id, so the order is the same on every build.
    private static func readsFirst(_ lhs: ReportMedicationRow, _ rhs: ReportMedicationRow) -> Bool {
        if lhs.doseCount != rhs.doseCount {
            return lhs.doseCount > rhs.doseCount
        }
        if lhs.medication.name != rhs.medication.name {
            return lhs.medication.name < rhs.medication.name
        }
        return lhs.medication.id.uuidString < rhs.medication.id.uuidString
    }
}
