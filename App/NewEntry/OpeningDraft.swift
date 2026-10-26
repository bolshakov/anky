import AnkyDomain
import Foundation

func openingDraft(after _: [Entry], now: Date) -> EntryDraft {
    EntryDraft(severity: Severity(0)!, date: now)
}
