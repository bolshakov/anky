// SPDX-License-Identifier: GPL-3.0-or-later
import UserNotifications

/// Passes a tap on a delivered reminder to the model. It has no `willPresent`, so a reminder still shows no banner
/// while the app is open.
final class ReminderTapDelegate: NSObject, UNUserNotificationCenterDelegate, Sendable {
    private let taps: ReminderTapModel

    init(taps: ReminderTapModel) {
        self.taps = taps
    }

    func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else { return }
        let identifier = response.notification.request.identifier
        await taps.received(identifier: identifier, at: .now)
    }
}
