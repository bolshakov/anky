// SPDX-License-Identifier: GPL-3.0-or-later
#if DEBUG
    import Foundation
    import notify

    /// Debug builds only, for the walks: a Darwin notification stands in for a tap on the reminder, which the simulator
    /// does not deliver to the app. The walk writes the dose's id to `reminder-tap.txt` in the entries folder, then
    /// posts the notification.
    enum ReminderTapSwitch {
        static let notificationName = "dev.bolshakov.Anky.debug-reminder-tap"

        @MainActor static func listen(taps: ReminderTapModel, folder: URL) {
            var token: Int32 = 0
            _ = notify_register_dispatch(notificationName, &token, .main) { _ in
                MainActor.assumeIsolated {
                    let file = folder.appending(path: "reminder-tap.txt")
                    guard let identifier = try? String(contentsOf: file, encoding: .utf8) else { return }
                    taps.received(identifier: identifier.trimmingCharacters(in: .whitespacesAndNewlines), at: .now)
                }
            }
        }
    }
#endif
