// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public struct Dose: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var medicationID: UUID
    public var takenAt: Date
    public var checkInAfter: CheckInDelay?
    public var beforeReadingID: UUID?
    public var afterReadingID: UUID?

    public init(id: UUID, medicationID: UUID, takenAt: Date, beforeReadingID: UUID? = nil) {
        self.id = id
        self.medicationID = medicationID
        self.takenAt = takenAt
        self.beforeReadingID = beforeReadingID
    }
}
