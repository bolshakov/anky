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

    @Test func crossingOutTapsOnceAndCrossingBackTapsNever() {
        let offsets: [Double] = [0, 100, 250, 200, 150]
        let crossings = zip(offsets, offsets.dropFirst()).filter {
            PinSwipe.crossedCommitPoint(from: $0.0, to: $0.1, rowWidth: rowWidth)
        }
        #expect(crossings.count == 1)
    }

    @Test func crossingOutAgainAfterGoingBackTapsAgain() {
        let offsets: [Double] = [0, 250, 200, 260]
        let crossings = zip(offsets, offsets.dropFirst()).filter {
            PinSwipe.crossedCommitPoint(from: $0.0, to: $0.1, rowWidth: rowWidth)
        }
        #expect(crossings.count == 2)
    }
}
