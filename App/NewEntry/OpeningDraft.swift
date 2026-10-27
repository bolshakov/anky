import AnkyDomain
import Foundation

func openingDraft(after saved: [Entry], now: Date) -> EntryDraft {
    EntryDraft(severity: Severity.startLevel(after: saved), date: now)
}
