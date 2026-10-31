// SPDX-License-Identifier: GPL-3.0-or-later
public enum ShortcutEvent: Equatable, Sendable {
    case crossedCommitPoint, pinChangedByLongSwipe, pinChangedByAction, pinChangedByMenu, pinRefused, menuOpened
}

public enum ShortcutFeedback: Equatable, Sendable { case none, selection, warning, lightImpact }

public enum ShortcutFeedbackRule {
    public static func feedback(for event: ShortcutEvent) -> ShortcutFeedback {
        switch event {
        case .crossedCommitPoint: .lightImpact
        case .pinChangedByAction, .pinChangedByMenu: .selection
        case .pinRefused: .warning
        case .pinChangedByLongSwipe, .menuOpened: .none
        }
    }
}
