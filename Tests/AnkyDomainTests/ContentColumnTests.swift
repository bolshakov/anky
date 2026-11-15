// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Testing

struct ContentColumnTests {
    private func edges(width: Double, leading: Double = 0, trailing: Double = 0) -> ContentEdges {
        ContentColumn.edges(
            width: width, leadingInset: leading, trailingInset: trailing, margin: 16, maximumWidth: 600
        )
    }

    @Test func portraitOnA402PointScreenKeepsTheMargin() {
        #expect(edges(width: 402) == ContentEdges(leading: 16, trailing: 16))
    }

    @Test func landscapeOn874WithSideInsetsCentresTheCappedColumn() {
        #expect(edges(width: 874, leading: 62, trailing: 62) == ContentEdges(leading: 137, trailing: 137))
    }

    @Test func aWidthUnderTheCapWithNoInsetKeepsTheMargin() {
        #expect(edges(width: 500) == ContentEdges(leading: 16, trailing: 16))
    }

    @Test func anInsetLargerThanTheMarginAndTheCapIsTheEdge() {
        #expect(edges(width: 700, leading: 80, trailing: 80) == ContentEdges(leading: 80, trailing: 80))
    }

    @Test func eachSideTakesItsOwnInset() {
        #expect(edges(width: 700, leading: 80, trailing: 20) == ContentEdges(leading: 80, trailing: 50))
    }

    @Test func landscapeOn667WithNoInsetCentresTheCappedColumn() {
        #expect(edges(width: 667) == ContentEdges(leading: 33.5, trailing: 33.5))
    }

    @Test func aSmallerPhoneKeepsTheMarginInPortraitAndTheCappedColumnInLandscape() {
        #expect(edges(width: 375) == ContentEdges(leading: 16, trailing: 16))
        #expect(edges(width: 812) == ContentEdges(leading: 106, trailing: 106))
    }

    @Test func theEdgeIsTheLargestTermAndNeverTheirSum() {
        #expect(edges(width: 874, leading: 200, trailing: 0) == ContentEdges(leading: 200, trailing: 137))
    }
}
