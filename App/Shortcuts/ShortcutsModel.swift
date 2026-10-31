// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Observation
import TipKit

@MainActor @Observable final class ShortcutsModel {
    @ObservationIgnored private let log: ShortcutsLog
    private(set) var pinned: [PlaceID]
    private(set) var lastChips: [PlaceID]
    var isShowingPinLimit = false
    private(set) var lastFeedback: ShortcutFeedback = .none
    private(set) var feedbackCount = 0

    init(log: ShortcutsLog) {
        self.log = log
        pinned = log.shortcuts.pinned
        lastChips = log.shortcuts.lastChips
    }

    func isPinned(_ place: PlaceID) -> Bool {
        pinned.contains(place)
    }

    func pin(_ place: PlaceID, event: ShortcutEvent) {
        handle(log.pin(place), event: event)
    }

    func pin(all places: [PlaceID], event: ShortcutEvent) {
        handle(log.pin(all: places), event: event)
    }

    func unpin(_ place: PlaceID, event: ShortcutEvent) {
        log.unpin(place)
        copyFromLog()
        report(event)
    }

    func recordLastChips(_ chips: [PlaceID]) {
        log.setLastChips(chips)
        copyFromLog()
    }

    func report(_ event: ShortcutEvent) {
        lastFeedback = ShortcutFeedbackRule.feedback(for: event)
        if lastFeedback != .none {
            feedbackCount += 1
        }
    }

    private func handle(_ outcome: PinOutcome, event: ShortcutEvent) {
        switch outcome {
        case .pinned:
            copyFromLog()
            report(event)
            PinShortcutTip().invalidate(reason: .actionPerformed)
        case .refused:
            isShowingPinLimit = true
            report(.pinRefused)
        case .alreadyPinned:
            break
        }
    }

    private func copyFromLog() {
        pinned = log.shortcuts.pinned
        lastChips = log.shortcuts.lastChips
    }
}
