// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum TakenAs: String, CaseIterable, Sendable {
    case asNeeded, scheduled
}

public enum CheckInDelay: Int, CaseIterable, Sendable {
    case thirtyMinutes = 30, oneHour = 60, twoHours = 120, threeHours = 180, fourHours = 240
}

public struct Medication: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var strength: String?
    public var takenAs: TakenAs
    public var checkInAfter: CheckInDelay?
    public let createdAt: Date
    public var updatedAt: Date
    public var archivedAt: Date?

    public init(id: UUID, name: String, takenAs: TakenAs, createdAt: Date) {
        self.id = id
        self.name = name
        self.takenAs = takenAs
        self.createdAt = createdAt
        updatedAt = createdAt
    }
}
