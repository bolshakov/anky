// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct PinSwipeTests {
    private let rowWidth: Double = 400

    @Test func aShortDragClosesTheRow() {
        let halfReveal = PinSwipe.revealWidth / 2
        #expect(PinSwipe.release(at: 0, rowWidth: rowWidth) == .close)
        #expect(PinSwipe.release(at: halfReveal - 1, rowWidth: rowWidth) == .close)
    }

    @Test func aMediumDragRevealsTheAction() {
        let halfReveal = PinSwipe.revealWidth / 2
        let commit = PinSwipe.commitPoint(rowWidth: rowWidth)
        #expect(PinSwipe.release(at: halfReveal, rowWidth: rowWidth) == .reveal)
        #expect(PinSwipe.release(at: 100, rowWidth: rowWidth) == .reveal)
        #expect(PinSwipe.release(at: commit - 1, rowWidth: rowWidth) == .reveal)
    }

    @Test func aDragPastTheCommitPointCommits() {
        let commit = PinSwipe.commitPoint(rowWidth: rowWidth)
        #expect(PinSwipe.release(at: commit, rowWidth: rowWidth) == .commit)
        #expect(PinSwipe.release(at: rowWidth, rowWidth: rowWidth) == .commit)
    }

    @Test func theCommitPointIsSixtyPercentOfTheRowWidth() {
        #expect(PinSwipe.commitPoint(rowWidth: 400) == 240)
        #expect(PinSwipe.commitPoint(rowWidth: 250) == 150)
    }

    @Test func crossingOutAndCrossingBackEachTapOnce() {
        let offsets: [Double] = [0, 100, 250, 200, 150]
        #expect(crossings(in: offsets) == 2)
    }

    @Test func crossingOutAgainAfterGoingBackTapsAgain() {
        let offsets: [Double] = [0, 250, 200, 260]
        #expect(crossings(in: offsets) == 3)
    }

    @Test func landingOnTheCommitPointCrossesOut() {
        let commit = PinSwipe.commitPoint(rowWidth: rowWidth)
        #expect(PinSwipe.crossedCommitPoint(from: commit - 1, to: commit, rowWidth: rowWidth))
    }

    @Test func leavingTheCommitPointCrossesBack() {
        let commit = PinSwipe.commitPoint(rowWidth: rowWidth)
        #expect(PinSwipe.crossedCommitPoint(from: commit, to: commit - 1, rowWidth: rowWidth))
    }

    @Test func movingOnOneSideOfThePointNeverCrosses() {
        let commit = PinSwipe.commitPoint(rowWidth: rowWidth)
        #expect(!PinSwipe.crossedCommitPoint(from: 0, to: commit - 1, rowWidth: rowWidth))
        #expect(!PinSwipe.crossedCommitPoint(from: commit - 1, to: 0, rowWidth: rowWidth))
        #expect(!PinSwipe.crossedCommitPoint(from: commit, to: rowWidth, rowWidth: rowWidth))
        #expect(!PinSwipe.crossedCommitPoint(from: rowWidth, to: commit, rowWidth: rowWidth))
    }

    @Test func theTapsMatchWhereTheFingerLetsGo() {
        assertTapsMatchRelease(at: [0, 100, 250, 200, 150])
        assertTapsMatchRelease(at: [0, 250, 200, 260])
        assertTapsMatchRelease(at: [0, 240])
        assertTapsMatchRelease(at: [0, 250, 240, 250])
        assertTapsMatchRelease(at: [0, 100, 200])
    }

    private func assertTapsMatchRelease(at offsets: [Double]) {
        let committed = PinSwipe.release(at: offsets[offsets.count - 1], rowWidth: rowWidth) == .commit
        #expect(crossings(in: offsets).isMultiple(of: 2) == !committed)
    }

    private func crossings(in offsets: [Double]) -> Int {
        zip(offsets, offsets.dropFirst()).filter {
            PinSwipe.crossedCommitPoint(from: $0.0, to: $0.1, rowWidth: rowWidth)
        }.count
    }
}
