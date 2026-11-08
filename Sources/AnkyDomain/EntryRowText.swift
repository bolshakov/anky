// SPDX-License-Identifier: GPL-3.0-or-later
public enum EntryRowText {
    /// `places` is nil for a kind that has none to say, so the label then skips that part.
    public static func spokenLabel(kind: String, time: String, places: String?, severity: String) -> String {
        [kind, time, places, severity].compactMap(\.self).joined(separator: ", ")
    }
}
