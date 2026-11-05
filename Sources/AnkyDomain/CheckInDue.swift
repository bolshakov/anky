// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// Which doses have their check-in offered. Nothing is stored about an offer, so a move or a delete reopens it.
public enum CheckInDue {
    public static let windowLength: TimeInterval = 12 * 60 * 60

    /// Nil when the dose never waits: check-in is off for it, its medication is missing, or it has its after-reading.
    /// The delay is the dose's own, not the medication's saved one.
    private static func dueMoment(for dose: Dose, medication: Medication?, readings: DoseReadings) -> Date? {
        guard let delay = dose.checkInAfter, medication != nil, readings.after == nil else {
            return nil
        }
        return dose.takenAt.addingTimeInterval(TimeInterval(delay.rawValue * 60))
    }

    /// The doses whose check-in is offered at `now`, oldest first.
    public static func waiting(doses: [Dose], medications: [Medication], entries: [Entry], now: Date) -> [Dose] {
        doses
            .filter { dose in
                guard let due = dueMoment(of: dose, medications: medications, entries: entries), due <= now,
                      now.timeIntervalSince(dose.takenAt) < windowLength
                else {
                    return false
                }
                return !doses.contains { isNewer($0, than: dose) } && !entries.contains { closes($0, dueMoment: due) }
            }
            .sorted { $0.takenAt < $1.takenAt }
    }

    /// The first due moment after `now` among the doses that can wait, or nil. A screen wakes at it to refresh.
    public static func nextDue(doses: [Dose], medications: [Medication], entries: [Entry], after now: Date) -> Date? {
        doses
            .compactMap { dueMoment(of: $0, medications: medications, entries: entries) }
            .filter { $0 > now }
            .min()
    }

    /// Dose times compare by whole minute. Within one minute the dose logged last is newer; a legacy dose with no
    /// `loggedAt` is older than a logged one, and two legacy doses are not newer than each other.
    private static func isNewer(_ other: Dose, than dose: Dose) -> Bool {
        guard other.id != dose.id else { return false }
        let otherMinute = other.takenAt.wholeMinute
        let minute = dose.takenAt.wholeMinute
        guard otherMinute == minute else { return otherMinute > minute }
        guard let otherLogged = other.loggedAt else { return false }
        return dose.loggedAt.map { otherLogged > $0 } ?? true
    }

    /// Compared by whole minute, as the entry and the due moment are shown. Every entry kind is a reading that closes.
    private static func closes(_ entry: Entry, dueMoment due: Date) -> Bool {
        entry.date.wholeMinute >= due.wholeMinute
    }

    private static func dueMoment(of dose: Dose, medications: [Medication], entries: [Entry]) -> Date? {
        dueMoment(
            for: dose,
            medication: medications.first { $0.id == dose.medicationID },
            readings: DoseReadings(dose, in: entries)
        )
    }
}
