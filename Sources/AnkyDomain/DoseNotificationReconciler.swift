// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public struct PendingNotification: Equatable, Sendable {
    public let identifier: String

    public init(identifier: String) {
        self.identifier = identifier
    }
}

public enum NotificationPermission: Sendable {
    case notDetermined, allowed, denied
}

public protocol NotificationCenterPort: Sendable {
    func pending() async -> [PendingNotification]
    func permission() async -> NotificationPermission
    func requestPermission() async -> Bool
    /// True when the system took the request.
    func add(_ notification: DoseNotification) async -> Bool
    func remove(identifiers: [String]) async
}

public struct DoseNotificationReconciler: Sendable {
    private let center: any NotificationCenterPort

    public init(center: any NotificationCenterPort) {
        self.center = center
    }

    public func reconcile(medications: [Medication], now: Date, calendar: Calendar) async {
        let pending = await center.pending().map(\.identifier)
        let pendingDoses = pending.filter(DoseNotificationPlan.isDose(identifier:))
        let window = DoseNotificationPlan.window(
            medications: medications,
            now: now,
            budget: DoseNotificationPlan.budget(otherPending: pending.count - pendingDoses.count),
            calendar: calendar
        )
        let wanted = Set(window.map(\.identifier))
        let stale = pendingDoses.filter { !wanted.contains($0) }
        if !stale.isEmpty {
            await center.remove(identifiers: stale)
        }
        let missing = window.filter { !pendingDoses.contains($0.identifier) }
        guard !missing.isEmpty, await isAllowed() else { return }
        // A refused dose stays missing, so the next rebuild offers it again.
        for notification in missing {
            _ = await center.add(notification)
        }
    }

    /// Asks only while the person has not answered. After a refusal nothing is scheduled and nothing asks again.
    private func isAllowed() async -> Bool {
        switch await center.permission() {
        case .notDetermined: await center.requestPermission()
        case .allowed: true
        case .denied: false
        }
    }
}
