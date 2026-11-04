// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// The Check in later switch on Log Dose and the delay under it. It starts from the selected medication's saved delay.
public struct DoseCheckIn: Equatable, Sendable {
    public var isOn: Bool
    public var delay: CheckInDelay

    public init(savedDelay: CheckInDelay?) {
        isOn = savedDelay != nil
        delay = savedDelay ?? .twoHours
    }

    /// The delay the dose and the medication's saved delay take, or nil when the switch is off.
    public var checkInAfter: CheckInDelay? {
        isOn ? delay : nil
    }
}

public extension DoseCheckIn {
    /// A value still equal to what the old saved delay produced has not been touched on this screen, so it takes the
    /// new saved delay. Comparing the value avoids a flag that would have to stay in step with the switch and menu.
    func following(savedDelay: CheckInDelay?, from oldDelay: CheckInDelay?) -> DoseCheckIn {
        self == DoseCheckIn(savedDelay: oldDelay) ? DoseCheckIn(savedDelay: savedDelay) : self
    }
}
