// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Testing

struct CheckInDelayTests {
    @Test func eachDelayIsStoredAsItsMinutes() {
        #expect(CheckInDelay.allCases.map(\.rawValue) == [30, 60, 120, 180, 240])
    }
}
