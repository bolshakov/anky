// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum PainPrefill {
    /// The Pain entry dated latest, of any age, that is not later than `now`. Other kinds and later entries never
    /// count.
    public static func latest(in entries: [Entry], notAfter now: Date) -> Entry? {
        entries
            .filter { $0.kind == .pain && $0.date <= now }
            .max { $0.date < $1.date }
    }
}
