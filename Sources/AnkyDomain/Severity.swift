// SPDX-License-Identifier: GPL-3.0-or-later
public struct Severity: Equatable, Hashable, Sendable {
    public let value: Int

    public init?(_ value: Int) {
        guard (0 ... 10).contains(value) else { return nil }
        self.value = value
    }

    public init?(exactly value: Double) {
        guard let whole = Int(exactly: value) else { return nil }
        self.init(whole)
    }

    public init(nearestToFraction fraction: Double) {
        // NaN fails this comparison, so a fraction that is not a number gives 0.
        let level = fraction > 0 ? min((fraction * 10).rounded(), 10) : 0
        value = Int(level)
    }

    public static func startLevel(after saved: [Entry]) -> Severity {
        saved.last?.severity ?? Severity(0)!
    }
}
