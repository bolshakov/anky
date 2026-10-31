// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

enum ShortcutFeedbackStyle {
    static func sensoryFeedback(for feedback: ShortcutFeedback) -> SensoryFeedback? {
        switch feedback {
        case .selection: .selection
        case .warning: .warning
        case .none: nil
        }
    }
}

extension View {
    func shortcutFeedback(_ shortcuts: ShortcutsModel) -> some View {
        modifier(ShortcutFeedbackModifier(shortcuts: shortcuts))
    }
}

private struct ShortcutFeedbackModifier: ViewModifier {
    let shortcuts: ShortcutsModel

    func body(content: Content) -> some View {
        content.sensoryFeedback(trigger: shortcuts.feedbackCount) { _, _ in
            ShortcutFeedbackStyle.sensoryFeedback(for: shortcuts.lastFeedback)
        }
    }
}
