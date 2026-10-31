// SPDX-License-Identifier: GPL-3.0-or-later
public enum SwipeRelease: Equatable, Sendable { case close, reveal, commit }

public enum PinSwipe {
    public static let revealWidth: Double = 88
    public static let commitFraction: Double = 0.6

    public static func commitPoint(rowWidth: Double) -> Double {
        rowWidth * commitFraction
    }

    public static func release(at offset: Double, rowWidth: Double) -> SwipeRelease {
        if offset >= commitPoint(rowWidth: rowWidth) {
            return .commit
        }
        if offset >= revealWidth / 2 {
            return .reveal
        }
        return .close
    }

    public static func crossedCommitPoint(from: Double, to: Double, rowWidth: Double) -> Bool {
        let point = commitPoint(rowWidth: rowWidth)
        return (from >= point) != (to >= point)
    }
}
