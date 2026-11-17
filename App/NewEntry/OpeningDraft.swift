// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation

func openingDraft(after saved: [Entry], now: Date, startDate: Date? = nil, latestDate: Date? = nil) -> EntryDraft {
    let opening = min(startDate ?? now, latestDate ?? .distantFuture)
    return EntryDraft(severity: Severity.startLevel(after: saved), date: opening)
}
