// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation

/// A notification center held in memory. It keeps what is pending, with each request's title, and records every call.
/// Like the system, it holds at most `DoseNotificationPlan.limit` requests and silently drops the earliest-added one
/// past that.
actor FakeNotificationCenter: NotificationCenterPort {
    enum Call: Equatable {
        case add(String)
        case remove([String])
    }

    private var held: [PendingNotification]
    private(set) var permissionRequests = 0
    private(set) var calls: [Call] = []
    private(set) var offered: [DoseNotification] = []
    private(set) var droppedIdentifiers: [String] = []
    /// The most requests that were pending at once, so a test can tell whether a rebuild passed the limit midway.
    private(set) var peakPending: Int
    private var current: NotificationPermission
    private let answer: Bool
    private var refusing: Set<String>

    var pendingIdentifiers: [String] {
        held.map(\.identifier)
    }

    var pendingTitles: [String] {
        held.map(\.title)
    }

    /// `answer` is what a request for permission returns. Answering true makes the permission `.allowed`, and
    /// answering false makes it `.denied`. An identifier in `refusing` is refused by `add` and never becomes pending.
    init(
        pending: [PendingNotification] = [],
        permission: NotificationPermission = .allowed,
        answer: Bool = true,
        refusing: Set<String> = []
    ) {
        held = pending
        peakPending = pending.count
        current = permission
        self.answer = answer
        self.refusing = refusing
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
        held
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

    func setRefusing(_ identifiers: Set<String>) {
        refusing = identifiers
    }

    func add(_ notification: DoseNotification) -> Bool {
        calls.append(.add(notification.identifier))
        offered.append(notification)
        guard !refusing.contains(notification.identifier) else { return false }
        hold(PendingNotification(
            identifier: notification.identifier,
            title: DoseNotificationContent(notification, body: "").title
        ))
        return true
    }

    /// A request from another scheduler, such as a check-in or the daily reminder.
    func addOther(_ identifier: String) {
        hold(.other(identifier))
    }

    func remove(identifiers: [String]) {
        calls.append(.remove(identifiers))
        held.removeAll { identifiers.contains($0.identifier) }
    }

    private func hold(_ request: PendingNotification) {
        held.append(request)
        peakPending = max(peakPending, held.count)
        while held.count > DoseNotificationPlan.limit {
            droppedIdentifiers.append(held.removeFirst().identifier)
        }
    }
}

extension PendingNotification {
    /// A request from another scheduler, whose title no test reads.
    static func other(_ identifier: String) -> PendingNotification {
        PendingNotification(identifier: identifier, title: "Other")
    }
}
