// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct ReadingPromptTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func aDoseAtTheClockIsNow() {
        #expect(ReadingPrompt.forDose(at: now, now: now) == .now)
    }

    @Test func aDoseExactlyFiveMinutesBackIsStillNow() {
        #expect(ReadingPrompt.forDose(at: now.addingTimeInterval(-300), now: now) == .now)
    }

    @Test func aDoseJustOverFiveMinutesBackIsEarlier() {
        #expect(ReadingPrompt.forDose(at: now.addingTimeInterval(-301), now: now) == .earlier)
    }

    @Test func aDoseLaterThanTheClockIsNow() {
        #expect(ReadingPrompt.forDose(at: now.addingTimeInterval(7200), now: now) == .now)
    }

    @Test func aDoseADayBackIsEarlier() {
        #expect(ReadingPrompt.forDose(at: now.addingTimeInterval(-86400), now: now) == .earlier)
    }
}
