// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct ShortcutFeedbackTests {
    @Test func openingAMenuGivesNoFeedback() {
        #expect(ShortcutFeedbackRule.feedback(for: .menuOpened) == ShortcutFeedback.none)
    }

    @Test func aPinFromTheSwipeGivesNoTapOfTheAppsOwn() {
        #expect(ShortcutFeedbackRule.feedback(for: .pinChangedBySwipe) == ShortcutFeedback.none)
    }

    @Test func aPinFromTheActionOrAMenuGivesASelectionTap() {
        #expect(ShortcutFeedbackRule.feedback(for: .pinChangedByAction) == .selection)
        #expect(ShortcutFeedbackRule.feedback(for: .pinChangedByMenu) == .selection)
    }

    @Test func aRefusedPinGivesAWarning() {
        #expect(ShortcutFeedbackRule.feedback(for: .pinRefused) == .warning)
    }
}
