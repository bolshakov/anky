// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation

func openingDraft(
    after saved: [Entry],
    now: Date,
    startDate: Date? = nil,
    latestDate: Date? = nil,
    kinds: [EntryKind] = EntryKind.allCases
) -> EntryDraft {
    // #lizard forgives
    let opening = min(startDate ?? now, latestDate ?? .distantFuture)
    var draft = EntryDraft(severity: Severity.startLevel(after: saved), date: opening)
    draft.kind = kinds.first ?? draft.kind
    return draft
}
