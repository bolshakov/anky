// SPDX-License-Identifier: GPL-3.0-or-later
#if DEBUG
    import AnkyDomain
    import Foundation
    import notify
    @preconcurrency import UserNotifications

    /// Debug builds only, for the walks: a Darwin notification asks for the dose requests the system holds, which
    /// nothing else can read from outside the app. The answer is `pending-doses.txt` in the entries folder, one
    /// identifier and fire time per dose, then the count of the other requests. It holds no request content, so no
    /// medication name.
    enum PendingDosesSwitch {
        static let notificationName = "dev.bolshakov.Anky.debug-pending-doses"

        @MainActor static func listen(folder: URL) {
            var token: Int32 = 0
            _ = notify_register_dispatch(notificationName, &token, .main) { _ in
                Task { @MainActor in
                    await write(into: folder)
                }
            }
        }

        @MainActor private static func write(into folder: URL) async {
            let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
            let pending = requests.map {
                (identifier: $0.identifier, fireAt: ($0.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate())
            }
            let text = report(pending)
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try? text.write(to: folder.appending(path: "pending-doses.txt"), atomically: true, encoding: .utf8)
        }

        private static func report(_ pending: [(identifier: String, fireAt: Date?)]) -> String {
            let doses = pending
                .filter { DoseNotificationPlan.isDose(identifier: $0.identifier) }
                .sorted { ($0.fireAt ?? .distantFuture) < ($1.fireAt ?? .distantFuture) }
            let format = Date.ISO8601FormatStyle(timeZone: .current)
            let lines = doses.map { "\($0.identifier)\t\($0.fireAt.map { $0.formatted(format) } ?? "none")" }
            return (lines + ["other\t\(pending.count - doses.count)"]).joined(separator: "\n") + "\n"
        }
    }
#endif
