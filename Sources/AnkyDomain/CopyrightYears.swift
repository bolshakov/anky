// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// The year part of the About block's copyright line. Bump `latest` in the first release of each new year.
public enum CopyrightYears {
    public static let first = 2026
    public static let latest = 2026

    public static func text(first: Int = CopyrightYears.first, latest: Int = CopyrightYears.latest) -> String {
        latest > first ? "\(first)-\(latest)" : "\(first)"
    }
}
