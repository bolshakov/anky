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
