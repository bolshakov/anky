// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public struct DoseNotificationContent: Equatable, Sendable {
    public let title: String
    public let body: String

    public init(_ notification: DoseNotification, body: String) {
        title = notification.medicationName
        self.body = body
    }
}
