// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation

/// A notification center held in memory. It keeps what is pending by identifier and records every call.
actor FakeNotificationCenter: NotificationCenterPort {
    enum Call: Equatable {
        case add(String)
        case remove([String])
    }

    private(set) var pendingIdentifiers: [String]
    private(set) var permissionRequests = 0
    private(set) var calls: [Call] = []
    /// The most requests that were pending at once, so a test can tell whether a rebuild passed the limit midway.
    private(set) var peakPending: Int
    private var current: NotificationPermission
    private let answer: Bool

    /// `answer` is what a request for permission returns. Answering true makes the permission `.allowed`, and
    /// answering false makes it `.denied`.
    init(
        pending: [String] = [],
        permission: NotificationPermission = .allowed,
        answer: Bool = true
    ) {
        pendingIdentifiers = pending
        peakPending = pending.count
        current = permission
        self.answer = answer
    }

    var addedIdentifiers: [String] {
        calls.compactMap { call in
            guard case let .add(identifier) = call else { return nil }
            return identifier
        }
    }

    var removedIdentifiers: [String] {
        calls.flatMap { call -> [String] in
            guard case let .remove(identifiers) = call else { return [] }
            return identifiers
        }
    }

    func pending() -> [PendingNotification] {
        pendingIdentifiers.map { PendingNotification(identifier: $0) }
    }

    func permission() -> NotificationPermission {
        current
    }

    func requestPermission() -> Bool {
        permissionRequests += 1
        current = answer ? .allowed : .denied
        return answer
    }

    func setPermission(_ permission: NotificationPermission) {
        current = permission
    }

    func add(_ notification: DoseNotification) {
        calls.append(.add(notification.identifier))
        pendingIdentifiers.append(notification.identifier)
        peakPending = max(peakPending, pendingIdentifiers.count)
    }

    func remove(identifiers: [String]) {
        calls.append(.remove(identifiers))
        pendingIdentifiers.removeAll { identifiers.contains($0) }
    }
}
