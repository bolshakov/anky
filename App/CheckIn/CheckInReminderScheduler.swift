// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import UserNotifications

/// Keeps one local notification pending per dose that `CheckInDue.reminders` lists. It adds and refreshes requests;
/// it never removes one, and never touches a delivered notification.
@MainActor final class CheckInReminderScheduler {
    private let center: UNUserNotificationCenter
    private var lastRun: Task<Void, Never>?

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    /// Runs one after another, so two reconciles never ask for permission or add the same request at once.
    func reconcile(doses: [Dose], medications: [Medication], entries: [Entry]) {
        let wanted = CheckInDue.reminders(doses: doses, medications: medications, entries: entries, now: .now)
        guard !wanted.isEmpty else { return }
        let previous = lastRun
        lastRun = Task { [center] in
            await previous?.value
            await Self.schedule(wanted, in: center)
        }
    }

    private static func schedule(_ wanted: [CheckInReminder], in center: UNUserNotificationCenter) async {
        guard await isAllowed(by: center) else { return }
        let pending = await pendingFireDates(in: center)
        for reminder in CheckInReminder.toSchedule(wanted, pending: pending) where reminder.fireAt > .now {
            try? await center.add(request(for: reminder))
        }
    }

    /// Asks only while the person has not answered. After a refusal the reminders are skipped without asking again.
    private static func isAllowed(by center: UNUserNotificationCenter) async -> Bool {
        switch await center.notificationSettings().authorizationStatus {
        case .notDetermined:
            await (try? center.requestAuthorization(options: [.alert, .sound])) ?? false
        case .authorized, .provisional, .ephemeral:
            true
        default:
            false
        }
    }

    private static func pendingFireDates(in center: UNUserNotificationCenter) async -> [UUID: Date] {
        var dates: [UUID: Date] = [:]
        for request in await center.pendingNotificationRequests() {
            let trigger = request.trigger as? UNCalendarNotificationTrigger
            if let id = UUID(uuidString: request.identifier), let date = trigger?.nextTriggerDate() {
                dates[id] = date
            }
        }
        return dates
    }

    private static func request(for reminder: CheckInReminder) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.body = String(localized: "Time to check in")
        content.sound = .default
        let moment = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: reminder.fireAt
        )
        return UNNotificationRequest(
            identifier: reminder.doseID.uuidString,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: moment, repeats: false)
        )
    }
}
