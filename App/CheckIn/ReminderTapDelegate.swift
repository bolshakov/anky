// SPDX-License-Identifier: GPL-3.0-or-later
import UserNotifications

/// Passes a tap on a delivered reminder to the model. It has no `willPresent`, so a reminder still shows no banner
/// while the app is open.
///
/// The conformance is main-actor isolated because UIKit finishes handling the response on the thread `didReceive`
/// returns on, and aborts the app with "Call must be made on main thread" when that is not the main thread.
@MainActor final class ReminderTapDelegate: NSObject, @MainActor UNUserNotificationCenterDelegate {
    private let taps: ReminderTapModel

    init(taps: ReminderTapModel) {
        self.taps = taps
    }

    func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else { return }
        taps.received(identifier: response.notification.request.identifier, at: .now)
    }
}
