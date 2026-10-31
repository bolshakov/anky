// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct ShortcutFeedbackTests {
    private var rows: [ShortcutEvent: ShortcutFeedback] {
        var table: [ShortcutEvent: ShortcutFeedback] = [:]
        table[.crossedCommitPoint] = .lightImpact
        table[.pinChangedByLongSwipe] = ShortcutFeedback.none
        table[.pinChangedByAction] = .selection
        table[.pinChangedByVoiceOver] = ShortcutFeedback.none
        table[.pinChangedByMenu] = ShortcutFeedback.none
        table[.pinRefused] = .warning
        table[.menuOpened] = ShortcutFeedback.none
        return table
    }

    @Test func openingAMenuGivesNoFeedback() {
        #expect(ShortcutFeedbackRule.feedback(for: .menuOpened) == ShortcutFeedback.none)
    }

    @Test func crossingTheCommitPointGivesALightTap() {
        #expect(ShortcutFeedbackRule.feedback(for: .crossedCommitPoint) == .lightImpact)
    }

    @Test func aLongSwipeThatTakesEffectGivesNoSecondTap() {
        #expect(ShortcutFeedbackRule.feedback(for: .pinChangedByLongSwipe) == ShortcutFeedback.none)
    }

    @Test func aPinFromTheRevealedButtonGivesASelectionTap() {
        #expect(ShortcutFeedbackRule.feedback(for: .pinChangedByAction) == .selection)
    }

    @Test func aPinFromAMenuGivesNoFeedback() {
        #expect(ShortcutFeedbackRule.feedback(for: .pinChangedByMenu) == ShortcutFeedback.none)
    }

    @Test func aPinFromVoiceOverGivesNoFeedback() {
        #expect(ShortcutFeedbackRule.feedback(for: .pinChangedByVoiceOver) == ShortcutFeedback.none)
    }

    @Test func aRefusedPinGivesAWarning() {
        #expect(ShortcutFeedbackRule.feedback(for: .pinRefused) == .warning)
    }

    @Test func everyPinEventHasARowInTheTable() {
        for event in ShortcutEvent.allCases {
            #expect(rows[event] == ShortcutFeedbackRule.feedback(for: event))
        }
        #expect(rows.count == ShortcutEvent.allCases.count)
    }
}
