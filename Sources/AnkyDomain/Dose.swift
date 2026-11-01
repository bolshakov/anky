// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// One logged dose of a medication. The check-in fields stay empty until the dose is checked in.
public struct Dose: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var medicationID: UUID
    public var takenAt: Date
    public var painBefore: Severity
    public var checkInAfter: CheckInDelay?
    public var painAfter: Severity?
    public var checkedInAt: Date?

    public init(
        id: UUID,
        medicationID: UUID,
        takenAt: Date,
        painBefore: Severity,
        checkInAfter: CheckInDelay? = nil
    ) {
        self.id = id
        self.medicationID = medicationID
        self.takenAt = takenAt
        self.painBefore = painBefore
        self.checkInAfter = checkInAfter
    }
}
