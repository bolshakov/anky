// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
@preconcurrency import UserNotifications

/// Rebuilds the pending dose notifications from the medications. The decisions live in `DoseNotificationReconciler`,
/// and this class only hands it the system's notification center.
@MainActor final class DoseNotificationScheduler {
    private let reconciler: DoseNotificationReconciler
    private var lastRun: Task<Void, Never>?

    init(center: UNUserNotificationCenter = .current()) {
        reconciler = DoseNotificationReconciler(center: SystemNotificationCenter(center: center))
    }

    /// Runs one after another, so two rebuilds never interleave. The date is fixed when called, so the last call
    /// decides what stays pending. It starts once `others` end, so its read counts the requests they add.
    func reconcile(medications: [Medication], after others: [Task<Void, Never>]) {
        let now = Date.now
        let calendar = Calendar.current
        let previous = lastRun
        lastRun = Task { [reconciler] in
            await previous?.value
            for other in others {
                await other.value
            }
            await reconciler.reconcile(medications: medications, now: now, calendar: calendar)
        }
    }
}

private struct SystemNotificationCenter: NotificationCenterPort {
    let center: UNUserNotificationCenter

    func pending() async -> [PendingNotification] {
        await center.pendingNotificationRequests().map { PendingNotification(identifier: $0.identifier) }
    }

    func permission() async -> NotificationPermission {
        switch await center.notificationSettings().authorizationStatus {
        case .notDetermined: .notDetermined
        case .authorized, .provisional, .ephemeral: .allowed
        default: .denied
        }
    }

    func requestPermission() async -> Bool {
        await (try? center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func add(_ notification: DoseNotification) async -> Bool {
        do {
            try await center.add(Self.request(for: notification))
            return true
        } catch {
            return false
        }
    }

    func remove(identifiers: [String]) async {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private static func request(for notification: DoseNotification) -> UNNotificationRequest {
        let text = DoseNotificationContent(notification, body: String(localized: "Time for your dose."))
        let content = UNMutableNotificationContent()
        content.title = text.title
        content.body = text.body
        content.sound = .default
        content.interruptionLevel = .active
        let moment = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: notification.fireAt
        )
        return UNNotificationRequest(
            identifier: notification.identifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: moment, repeats: false)
        )
    }
}
