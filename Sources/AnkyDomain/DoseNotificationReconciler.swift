// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public struct PendingNotification: Equatable, Sendable {
    public let identifier: String
    public let title: String

    public init(identifier: String, title: String) {
        self.identifier = identifier
        self.title = title
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
        let pending = await center.pending()
        let pendingDoses = pending.filter { DoseNotificationPlan.isDose(identifier: $0.identifier) }
        let window = DoseNotificationPlan.window(
            medications: medications,
            now: now,
            budget: DoseNotificationPlan.budget(otherPending: pending.count - pendingDoses.count),
            calendar: calendar
        )
        let plannedTitles = Dictionary(
            window.map { ($0.identifier, DoseNotificationContent($0, body: "").title) },
            uniquingKeysWith: { first, _ in first }
        )
        let (current, stale) = pendingDoses.partitioned { plannedTitles[$0.identifier] == $0.title }
        if !stale.isEmpty {
            await center.remove(identifiers: stale.map(\.identifier))
        }
        let present = Set(current.map(\.identifier))
        let missing = window.filter { !present.contains($0.identifier) }
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

private extension Array {
    func partitioned(by belongsToFirst: (Element) -> Bool) -> (first: [Element], second: [Element]) {
        (filter(belongsToFirst), filter { !belongsToFirst($0) })
    }
}
