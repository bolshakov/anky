// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Testing

struct ScrollRestoreTests {
    @Test func anIdleFormAtItsTopWithASavedPositionGoesBackToIt() {
        #expect(ScrollRestore.target(offset: 0, saved: 23.7, isIdle: true) == 23.7)
    }

    @Test func anOffsetAboveTheTopIsStillTheTop() {
        #expect(ScrollRestore.target(offset: -3, saved: 23.7, isIdle: true) == 23.7)
    }

    @Test func aFormThePersonLeftAtItsTopStaysThere() {
        #expect(ScrollRestore.target(offset: 0, saved: 0, isIdle: true) == nil)
    }

    @Test func aFormNotAtItsTopIsLeftWhereItIs() {
        #expect(ScrollRestore.target(offset: 40, saved: 23.7, isIdle: true) == nil)
    }

    @Test func aFormThePersonIsScrollingBackToItsTopIsNotPulledAway() {
        #expect(ScrollRestore.target(offset: 0, saved: 23.7, isIdle: false) == nil)
    }
}
