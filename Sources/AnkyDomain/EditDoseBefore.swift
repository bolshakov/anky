// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// What Edit Dose's Before this dose row points at. The form picks it once on opening and changes it only by the
/// person's own act, so entries that appear or vanish while it is open never turn None into the prompt or back.
public enum EditDoseBefore: Equatable, Sendable {
    case entry(UUID)
    case none
    case prompt

    /// A saved link that is gone or no longer before the dose is None. With no link, the window decides: entries in it
    /// give None, and an empty one gives the prompt that logs one.
    public static func opening(savedLink: UUID?, in entries: [Entry], at doseTime: Date) -> EditDoseBefore {
        if let savedLink {
            return ReadingLink.kept(savedLink, in: entries, at: doseTime) == nil ? .none : .entry(savedLink)
        }
        return ReadingWindow.latest(in: entries, before: doseTime) == nil ? .prompt : .none
    }

    /// The id to save: the entry while the dose time keeps it, else nil.
    public func linkedID(in entries: [Entry], at doseTime: Date) -> UUID? {
        guard case let .entry(id) = self else { return nil }
        return ReadingLink.kept(id, in: entries, at: doseTime)
    }

    /// An entry the dose time no longer keeps reads as None, since the person had chosen a reading and not the prompt.
    public func isNone(in entries: [Entry], at doseTime: Date) -> Bool {
        switch self {
        case .none: true
        case .prompt: false
        case .entry: linkedID(in: entries, at: doseTime) == nil
        }
    }
}
