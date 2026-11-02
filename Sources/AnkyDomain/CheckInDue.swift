// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// Which doses wait for a check-in. A dose waits from its due moment until it has an after-reading. An after-reading
/// id that matches no entry reads as none, so a deleted check-in brings the dose back to waiting.
public enum CheckInDue {
    /// Nil when the dose never waits: check-in is off for it, its medication is gone or archived, or it has its
    /// after-reading. The delay is the dose's own, not the medication's saved one.
    public static func dueMoment(for dose: Dose, medication: Medication?, readings: DoseReadings) -> Date? {
        guard let delay = dose.checkInAfter, let medication, medication.archivedAt == nil, readings.after == nil else {
            return nil
        }
        return dose.takenAt.addingTimeInterval(TimeInterval(delay.rawValue * 60))
    }

    public static func isWaiting(_ dose: Dose, medication: Medication?, readings: DoseReadings, now: Date) -> Bool {
        dueMoment(for: dose, medication: medication, readings: readings).map { $0 <= now } ?? false
    }

    /// Oldest first.
    public static func waiting(doses: [Dose], medications: [Medication], entries: [Entry], now: Date) -> [Dose] {
        doses
            .filter { (dueMoment(of: $0, medications: medications, entries: entries) ?? .distantFuture) <= now }
            .sorted { $0.takenAt < $1.takenAt }
    }

    /// The first due moment after `now` among the doses that can wait, or nil. A screen wakes at it to refresh.
    public static func nextDue(doses: [Dose], medications: [Medication], entries: [Entry], after now: Date) -> Date? {
        doses
            .compactMap { dueMoment(of: $0, medications: medications, entries: entries) }
            .filter { $0 > now }
            .min()
    }

    private static func dueMoment(of dose: Dose, medications: [Medication], entries: [Entry]) -> Date? {
        dueMoment(
            for: dose,
            medication: medications.first { $0.id == dose.medicationID },
            readings: DoseReadings(dose, in: entries)
        )
    }
}
