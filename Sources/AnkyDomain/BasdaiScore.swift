// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// The BASDAI score, (Q1 + Q2 + Q3 + Q4 + (Q5 + Q6) / 2) / 5. It is computed from the answers each time and never
/// stored.
public enum BasdaiScore {
    /// The score times ten, which the formula gives as a whole number, so no rounding error enters the sum.
    public static func tenths(_ q: [Int]) -> Int {
        2 * (q[0] + q[1] + q[2] + q[3]) + q[4] + q[5]
    }

    public static func text(tenths: Int, locale: Locale) -> String {
        (Double(tenths) / 10).formatted(style(locale: locale))
    }

    static func style(locale: Locale) -> FloatingPointFormatStyle<Double> {
        .number.precision(.fractionLength(1)).rounded(rule: .toNearestOrAwayFromZero).locale(locale)
    }
}
