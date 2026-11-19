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

    /// Nil when `noReading`, whatever else is set. Otherwise `linked` when kept, else the existing
    /// `ReadingWindow.pick(manual, in:, before:)`.
    public static func resolve(
        linked: UUID?, manual: UUID?, noReading: Bool = false, in entries: [Entry], at doseTime: Date
    ) -> Entry? {
        // #lizard forgives
        if noReading {
            return nil
        }
        if let kept = kept(linked, in: entries, at: doseTime) {
            return entries.first { $0.id == kept }
        }
        return ReadingWindow.pick(manual, in: entries, before: doseTime)
    }

    /// The entries Choose an Entry lists: the window's, and the `chosen` one in its place by date when the window
    /// leaves it out, whatever its kind or age, so the row that points at it never points at a hidden entry.
    public static func choices(in entries: [Entry], chosen: UUID?, at doseTime: Date) -> [Entry] {
        let window = Set(ReadingWindow.entries(in: entries, before: doseTime).map(\.id))
        let keptChosen = kept(chosen, in: entries, at: doseTime)
        return ReadingWindow.newestFirst(entries) { window.contains($0.id) || $0.id == keptChosen }
    }
}
