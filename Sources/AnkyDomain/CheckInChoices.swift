// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum CheckInChoices {
    /// Off, which is nil, then the five delays, in the order the After menu lists them.
    public static let all: [CheckInDelay?] = [nil] + CheckInDelay.allCases
}
