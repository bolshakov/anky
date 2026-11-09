// SPDX-License-Identifier: GPL-3.0-or-later
public enum EntryRowText {
    /// `places` is nil for a kind that has none to say, so the label then skips that part.
    public static func spokenLabel(kind: String, time: String, places: String?, severity: String) -> String {
        [kind, severity, time, places].compactMap(\.self).filter { !$0.isEmpty }.joined(separator: ", ")
    }

    /// A reading speaks its time first, unlike an entry row, which speaks its kind first.
    public static func readingLabel(time: String, kind: String, places: String?, severity: String) -> String {
        [time, kind, places, severity].compactMap(\.self).joined(separator: ", ")
    }

    /// The part of a reading a control says after its label, when that label is the kind word alone.
    public static func readingOptionValue(time: String, places: String?, severity: String) -> String {
        [time, places, severity].compactMap(\.self).joined(separator: ", ")
    }
}
