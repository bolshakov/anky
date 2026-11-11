// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import UserNotifications

/// Keeps at most one local notification pending, for the next day with nothing logged. It never touches a delivered
/// notification and never asks for permission on its own.
@MainActor final class DailyReminderScheduler {
    private let center: UNUserNotificationCenter
    private var lastRun: Task<Void, Never>?

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    /// Runs one after another, so two reconciles never add the request at once. The date is fixed when called, so the
    /// last call decides what stays pending.
    func reconcile(settings: DailyReminderSettings, entries: [Entry], doses: [Dose]) {
        let date = DailyReminder.pendingFireDate(
            isOn: settings.isOn,
            entries: entries,
            doses: doses,
            time: settings.time,
            now: .now,
            calendar: .current
        )
        let previous = lastRun
        lastRun = Task { [center] in
            await previous?.value
            await Self.schedule(date, in: center)
        }
    }

    /// The one call of `requestAuthorization` for this reminder. Only the toggle's action may call it.
    func requestPermission() async -> Bool {
        await (try? center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func isDeniedByiOS() async -> Bool {
        await center.notificationSettings().authorizationStatus == .denied
    }

    /// Adding under the same identifier replaces the request in place. A remove first would leave a moment with one
    /// request fewer, and a dose rebuild that reads then sizes its window one too big.
    private static func schedule(_ date: Date?, in center: UNUserNotificationCenter) async {
        guard let date, await isAllowed(by: center) else {
            center.removePendingNotificationRequests(withIdentifiers: [DailyReminder.identifier])
            return
        }
        try? await center.add(request(at: date))
    }

    private static func isAllowed(by center: UNUserNotificationCenter) async -> Bool {
        switch await center.notificationSettings().authorizationStatus {
        case .authorized, .provisional, .ephemeral: true
        default: false
        }
    }

    private static func request(at date: Date) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Anky")
        content.body = String(localized: "Log how you feel today.")
        content.sound = .default
        content.interruptionLevel = .active
        let moment = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        return UNNotificationRequest(
            identifier: DailyReminder.identifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: moment, repeats: false)
        )
    }
}
