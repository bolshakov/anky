// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public struct DoseTime: Equatable, Comparable, Hashable, Sendable {
    public let hour: Int
    public let minute: Int

    public init?(hour: Int, minute: Int) {
        guard (0 ... 23).contains(hour), (0 ... 59).contains(minute) else { return nil }
        self.hour = hour
        self.minute = minute
    }

    public static func < (lhs: DoseTime, rhs: DoseTime) -> Bool {
        (lhs.hour, lhs.minute) < (rhs.hour, rhs.minute)
    }
}
