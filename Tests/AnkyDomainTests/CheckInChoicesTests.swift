// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Testing

struct CheckInChoicesTests {
    @Test func theAfterMenuOffersOffThenTheFiveDelaysInOrder() {
        #expect(CheckInChoices.all == [nil, .thirtyMinutes, .oneHour, .twoHours, .threeHours, .fourHours])
    }

    @Test func eachDelayIsStoredAsItsMinutes() {
        #expect(CheckInDelay.allCases.map(\.rawValue) == [30, 60, 120, 180, 240])
    }
}
