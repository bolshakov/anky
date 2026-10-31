// SPDX-License-Identifier: GPL-3.0-or-later
public enum ShortcutEvent: CaseIterable, Equatable, Sendable {
    case crossedCommitPoint, pinChangedByLongSwipe, pinChangedByAction, pinChangedByVoiceOver, pinChangedByMenu
    case pinRefused, menuOpened
}

public enum ShortcutFeedback: Equatable, Sendable { case none, selection, warning, lightImpact }

public enum ShortcutFeedbackRule {
    public static func feedback(for event: ShortcutEvent) -> ShortcutFeedback {
        switch event {
        case .crossedCommitPoint: .lightImpact
        case .pinChangedByAction: .selection
        case .pinRefused: .warning
        case .pinChangedByLongSwipe, .pinChangedByVoiceOver, .pinChangedByMenu, .menuOpened: .none
        }
    }
}
