// SPDX-License-Identifier: GPL-3.0-or-later
public enum ShortcutEvent: Equatable, Sendable {
    case pinChangedBySwipe, pinChangedByAction, pinChangedByMenu, pinRefused, menuOpened
}

public enum ShortcutFeedback: Equatable, Sendable { case none, selection, warning }

public enum ShortcutFeedbackRule {
    public static func feedback(for event: ShortcutEvent) -> ShortcutFeedback {
        switch event {
        case .pinChangedByAction, .pinChangedByMenu: .selection
        case .pinRefused: .warning
        case .pinChangedBySwipe, .menuOpened: .none
        }
    }
}
