// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// What the person has chosen on Log Dose. Each value stays nil or at its default until they act on it.
public struct LogDoseDraft: Equatable, Sendable {
    public var selectedID: UUID?
    /// The time the person set by hand. Nil while the dose follows the clock.
    public var takenAt: Date?
    public var manualReadingID: UUID?
    public var checkIn: DoseCheckIn

    public init(selectedID: UUID?, takenAt: Date?, manualReadingID: UUID?, checkIn: DoseCheckIn) {
        self.selectedID = selectedID
        self.takenAt = takenAt
        self.manualReadingID = manualReadingID
        self.checkIn = checkIn
    }
}

/// What the form is read against: the list and log as they are now, and the clock.
public struct LogDoseContext: Sendable {
    public let preselected: UUID?
    public let active: [Medication]
    public let entries: [Entry]
    public let now: Date

    public init(preselected: UUID?, active: [Medication], entries: [Entry], now: Date) {
        self.preselected = preselected
        self.active = active
        self.entries = entries
        self.now = now
    }
}

public extension LogDoseDraft {
    static func untouched(preselected: UUID?, active: [Medication]) -> LogDoseDraft {
        let checked = MedicationSelection.kept(preselected, in: active)
        let savedDelay = active.first { $0.id == checked }?.checkInAfter
        return LogDoseDraft(
            selectedID: preselected,
            takenAt: nil,
            manualReadingID: nil,
            checkIn: DoseCheckIn(savedDelay: savedDelay)
        )
    }

    /// True when Save would write a dose that an untouched Log Dose would not write at this moment. Comparing what
    /// Save would write, not what the person touched, keeps a form that moves under them (the clock, the medication
    /// list, a saved check-in delay) from reading as changed.
    func hasChanges(in context: LogDoseContext) -> Bool {
        let untouched = Self.untouched(preselected: context.preselected, active: context.active)
        return written(in: context) != untouched.written(in: context)
    }
}

private struct WrittenDose: Equatable {
    let medicationID: UUID?
    let minute: Double
    let readingID: UUID?
    let checkInAfter: CheckInDelay?
}

private extension LogDoseDraft {
    func written(in context: LogDoseContext) -> WrittenDose {
        let time = takenAt ?? context.now
        return WrittenDose(
            medicationID: MedicationSelection.kept(selectedID, in: context.active),
            minute: time.wholeMinute,
            readingID: ReadingWindow.pick(manualReadingID, in: context.entries, before: time)?.id,
            checkInAfter: checkIn.checkInAfter
        )
    }
}
