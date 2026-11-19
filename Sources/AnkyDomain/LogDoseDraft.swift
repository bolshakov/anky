// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// What the person has chosen on Log Dose. Each value stays nil or at its default until they act on it.
public struct LogDoseDraft: Equatable, Sendable {
    public var selectedID: UUID?
    /// The time the person set by hand. Nil while the dose follows the clock.
    public var takenAt: Date?
    public var manualReadingID: UUID?
    /// The entry logged for this dose. Unlike `manualReadingID` no two-hour window bounds it, only the dose time.
    public var linkedReadingID: UUID?
    /// The person, or the medication's start, chose no reading. A different state from no pick yet.
    public var noReading: Bool
    /// True once the person picked, chose None, swiped or logged an entry in this form.
    public var readingTouched: Bool
    public var checkIn: DoseCheckIn

    public init(
        selectedID: UUID?, takenAt: Date?, manualReadingID: UUID?, linkedReadingID: UUID? = nil,
        noReading: Bool = false, readingTouched: Bool = false, checkIn: DoseCheckIn
    ) {
        // #lizard forgives
        self.selectedID = selectedID
        self.takenAt = takenAt
        self.manualReadingID = manualReadingID
        self.linkedReadingID = linkedReadingID
        self.noReading = noReading
        self.readingTouched = readingTouched
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
            noReading: Self.startsAtNone(selectedID: preselected, in: active),
            checkIn: DoseCheckIn(savedDelay: savedDelay)
        )
    }

    /// An untouched row follows the new medication's start. A touched row keeps its choice. No memory is written.
    func changingMedication(to id: UUID?, in context: LogDoseContext) -> LogDoseDraft {
        var draft = self
        draft.selectedID = id
        guard !readingTouched else { return draft }
        draft.manualReadingID = nil
        draft.linkedReadingID = nil
        draft.noReading = Self.startsAtNone(selectedID: id, in: context.active)
        return draft
    }

    /// Picking the entry already linked keeps the link, since a manual pick outside the window would not hold.
    func picking(_ id: UUID) -> LogDoseDraft {
        var draft = self
        if id != linkedReadingID {
            draft.manualReadingID = id
            draft.linkedReadingID = nil
        } else {
            draft.manualReadingID = nil
        }
        draft.noReading = false
        draft.readingTouched = true
        return draft
    }

    /// A pick the new time no longer holds falls back to the checked medication's start. None stays None.
    func movingTime(to date: Date?, in context: LogDoseContext) -> LogDoseDraft {
        var draft = self
        draft.takenAt = date
        guard !noReading else { return draft }
        let time = date ?? context.now
        let window = ReadingWindow.entries(in: context.entries, before: time)
        draft.linkedReadingID = ReadingLink.kept(linkedReadingID, in: context.entries, at: time)
        draft.manualReadingID = window.first { $0.id == manualReadingID }?.id
        let hadPick = linkedReadingID != nil || manualReadingID != nil
        if hadPick, draft.linkedReadingID == nil, draft.manualReadingID == nil {
            draft.noReading = Self.startsAtNone(selectedID: selectedID, in: context.active)
        }
        return draft
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
    let noReading: Bool
    let checkInAfter: CheckInDelay?
}

private extension LogDoseDraft {
    static func startsAtNone(selectedID: UUID?, in active: [Medication]) -> Bool {
        let checked = MedicationSelection.kept(selectedID, in: active)
        return ReadingStart.forMedication(active.first { $0.id == checked }) == .none
    }

    func written(in context: LogDoseContext) -> WrittenDose {
        let time = takenAt ?? context.now
        return WrittenDose(
            medicationID: MedicationSelection.kept(selectedID, in: context.active),
            minute: time.wholeMinute,
            readingID: ReadingLink.resolve(
                linked: linkedReadingID,
                manual: manualReadingID,
                noReading: noReading,
                in: context.entries,
                at: time
            )?.id,
            noReading: noReading,
            checkInAfter: checkIn.checkInAfter
        )
    }
}
