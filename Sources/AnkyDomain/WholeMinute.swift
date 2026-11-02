// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

extension Date {
    var wholeMinute: Double {
        (timeIntervalSinceReferenceDate / 60).rounded(.down)
    }
}
