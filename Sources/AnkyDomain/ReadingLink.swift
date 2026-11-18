// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// The entry logged for a dose is that dose's before-reading for as long as it exists and is not after the dose.
public enum ReadingLink {
    /// `id` while an entry with that id is in `entries` and is at or before `doseTime` by whole minute, else nil.
    public static func kept(_ id: UUID?, in entries: [Entry], at doseTime: Date) -> UUID? {
        guard let id,
              let linked = entries.first(where: { $0.id == id }),
              linked.date.wholeMinute <= doseTime.wholeMinute
        else { return nil }
        return id
    }

    /// `linked` when kept; otherwise the existing `ReadingWindow.pick(manual, in:, before:)`.
    public static func resolve(linked: UUID?, manual: UUID?, in entries: [Entry], at doseTime: Date) -> Entry? {
        if let kept = kept(linked, in: entries, at: doseTime) {
            return entries.first { $0.id == kept }
        }
        return ReadingWindow.pick(manual, in: entries, before: doseTime)
    }
}
