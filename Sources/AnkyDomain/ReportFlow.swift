// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// A report block as measured on the page, heights in points.
public enum ReportFlowBlock: Equatable, Sendable {
    case whole(height: Double)
    case table(heading: Double, columnHeader: Double, rows: [Double], note: Double)
}

/// The part of one block that a page shows.
public struct ReportFlowSlice: Equatable, Sendable {
    public let block: Int
    public let rows: Range<Int>?
    public let isContinued: Bool
    public let showsNote: Bool

    public init(block: Int, rows: Range<Int>?, isContinued: Bool, showsNote: Bool) {
        self.block = block
        self.rows = rows
        self.isContinued = isContinued
        self.showsNote = showsNote
    }
}

/// Decides where each report page ends.
public enum ReportFlow {
    public static func pages(
        blocks: [ReportFlowBlock], gap: Double, firstPage: Double, laterPages: Double
    ) -> [[ReportFlowSlice]] {
        var packer = Packer(gap: gap, firstPage: firstPage, laterPages: laterPages)
        for (index, block) in blocks.enumerated() {
            switch block {
            case let .whole(height):
                packer.placeWhole(index, height: height)
            case let .table(heading, columnHeader, rows, note):
                packer.placeTable(index, Table(top: heading + columnHeader, rows: rows, note: note))
            }
        }
        return packer.pages
    }
}

private struct Table {
    let top: Double
    let rows: [Double]
    let note: Double

    func height(_ range: Range<Int>) -> Double {
        top + rows[range].reduce(0, +) + (range.upperBound == rows.count ? note : 0)
    }
}

/// Every placement puts at least one block or row on a page, so packing always ends.
private struct Packer {
    let gap: Double
    let firstPage: Double
    let laterPages: Double
    private(set) var pages: [[ReportFlowSlice]] = [[]]
    private var used = 0.0
    private var isFull = false

    init(gap: Double, firstPage: Double, laterPages: Double) {
        self.gap = gap
        self.firstPage = firstPage
        self.laterPages = laterPages
    }

    private var isFresh: Bool {
        pages[pages.count - 1].isEmpty
    }

    private var room: Double {
        guard !isFull else { return -.infinity }
        let capacity = pages.count == 1 ? firstPage : laterPages
        return capacity - used - (isFresh ? 0 : gap)
    }

    mutating func placeWhole(_ block: Int, height: Double) {
        if height > room, !isFresh {
            startPage()
        }
        let fits = height <= room
        place(ReportFlowSlice(block: block, rows: nil, isContinued: false, showsNote: false), height: height)
        isFull = !fits
    }

    mutating func placeTable(_ block: Int, _ table: Table) {
        var start = 0
        repeat {
            if rowsFitting(table, from: start) == nil, !isFresh {
                startPage()
            }
            let fitting = rowsFitting(table, from: start)
            let end = start + (fitting ?? min(1, table.rows.count - start))
            let rows = start ..< end
            let slice = ReportFlowSlice(
                block: block, rows: rows, isContinued: start > 0, showsNote: end == table.rows.count
            )
            place(slice, height: table.height(rows))
            isFull = fitting == nil || end < table.rows.count
            start = end
        } while start < table.rows.count
    }

    /// The most rows from `start` that fit under the heading, with the note when they reach the end.
    private func rowsFitting(_ table: Table, from start: Int) -> Int? {
        let room = room
        guard start < table.rows.count else { return table.height(start ..< start) <= room ? 0 : nil }
        var fitting: Int?
        for end in start + 1 ... table.rows.count {
            guard table.height(start ..< end) <= room else { break }
            fitting = end - start
        }
        return fitting
    }

    private mutating func place(_ slice: ReportFlowSlice, height: Double) {
        used += (isFresh ? 0 : gap) + height
        pages[pages.count - 1].append(slice)
    }

    private mutating func startPage() {
        pages.append([])
        used = 0
        isFull = false
    }
}
