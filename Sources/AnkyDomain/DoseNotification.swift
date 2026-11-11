// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public struct DoseNotification: Equatable, Sendable {
    public let medicationID: UUID
    public let medicationName: String
    public let fireAt: Date

    public init(medicationID: UUID, medicationName: String, fireAt: Date) {
        self.medicationID = medicationID
        self.medicationName = medicationName
        self.fireAt = fireAt
    }

    /// Never a bare UUID: the check-in scheduler cancels pending UUID identifiers it does not want, and a tap on a
    /// bare UUID reads as a check-in.
    public var identifier: String {
        "\(DoseNotificationPlan.identifierPrefix)\(medicationID.uuidString).\(Int(fireAt.timeIntervalSince1970))"
    }
}

public enum DoseNotificationPlan {
    public static let limit = 64
    public static let identifierPrefix = "dose-due."

    public static func isDose(identifier: String) -> Bool {
        medicationID(fromIdentifier: identifier) != nil
    }

    public static func medicationID(fromIdentifier identifier: String) -> UUID? {
        guard identifier.hasPrefix(identifierPrefix) else { return nil }
        let parts = identifier.dropFirst(identifierPrefix.count).split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 2, Int(parts[1]) != nil else { return nil }
        return UUID(uuidString: String(parts[0]))
    }

    public static func budget(otherPending: Int) -> Int {
        max(0, limit - otherPending)
    }

    public static func window(
        medications: [Medication],
        now: Date,
        budget: Int,
        calendar: Calendar
    ) -> [DoseNotification] {
        guard budget > 0 else { return [] }
        return medications
            .flatMap { doses(of: $0, after: now, count: budget, calendar: calendar) }
            .sorted { ($0.fireAt, $0.medicationID.uuidString) < ($1.fireAt, $1.medicationID.uuidString) }
            .prefix(budget)
            .map(\.self)
    }

    private static func doses(
        of medication: Medication,
        after now: Date,
        count: Int,
        calendar: Calendar
    ) -> [DoseNotification] {
        guard medication.archivedAt == nil, medication.takenAs == .scheduled, let schedule = medication.schedule else {
            return []
        }
        return schedule.nextDoses(after: now, count: count, calendar: calendar).map {
            DoseNotification(medicationID: medication.id, medicationName: medication.name, fireAt: $0)
        }
    }
}
