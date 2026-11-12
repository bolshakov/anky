// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

/// The report's blocks laid out on pages, with the totals band first on page 1. Every page repeats the header, the
/// Name line and the footer, so what is left for the blocks is measured once per build.
@MainActor struct ReportDocument {
    let size: ReportPageSize
    let headerLine: String
    let totals: ReportTotalsText
    let blocks: [ReportBlock]

    var pages: [ReportPage] {
        let width = size.width - 2 * ReportMetrics.sideMargin
        let laterPages = laterPagesRoom(width: width)
        let firstPage = laterPages - ReportMeasure.height(of: ReportTotalsBand(totals: totals), width: width)
            - ReportMetrics.sectionGap
        let flow = ReportFlow.pages(
            blocks: blocks.map { $0.flowBlock(width: width) },
            gap: Double(ReportMetrics.sectionGap),
            firstPage: Double(firstPage),
            laterPages: Double(laterPages)
        )
        return flow.enumerated().map { index, slices in
            ReportPage(
                size: size, headerLine: headerLine, pageNumber: index + 1, pageCount: flow.count,
                content: AnyView(ReportPageContent(
                    totals: index == 0 ? totals : nil,
                    slices: slices.map { blocks[$0.block].view(for: $0) }
                ))
            )
        }
    }

    private func laterPagesRoom(width: CGFloat) -> CGFloat {
        size.height - ReportMetrics.topMargin - ReportMetrics.bottomMargin
            - ReportMeasure.height(of: ReportPageHeader(headerLine: headerLine), width: width)
            - ReportMeasure.height(of: ReportPageNameLine(), width: width)
            - ReportMeasure.height(of: ReportPageFooter(pageNumber: 1, pageCount: 1), width: width)
    }
}

private struct ReportPageContent: View {
    let totals: ReportTotalsText?
    let slices: [AnyView]

    var body: some View {
        VStack(alignment: .leading, spacing: ReportMetrics.sectionGap) {
            if let totals {
                ReportTotalsBand(totals: totals)
            }
            ForEach(slices.indices, id: \.self) { index in
                slices[index]
            }
        }
    }
}

@MainActor private extension ReportBlock {
    /// An empty table draws only its heading and "None logged in this period", so it is packed as one whole block.
    func flowBlock(width: CGFloat) -> ReportFlowBlock {
        func height(_ view: some View) -> Double {
            Double(ReportMeasure.height(of: view, width: width))
        }
        switch self {
        case let .whole(view):
            return .whole(height: height(view))
        case let .table(rows, hasScheduled) where rows.isEmpty:
            let block = ReportMedicationBlock(
                rows: rows,
                hasScheduled: hasScheduled,
                isContinued: false,
                showsNote: false
            )
            return .whole(height: height(block))
        case let .table(rows, hasScheduled):
            return .table(
                heading: height(ReportMedicationHeading(isContinued: false)),
                columnHeader: height(ReportMedicationColumnHeader()),
                rows: rows.map { height(ReportMedicationRowView(text: $0)) },
                note: height(ReportMedicationNoteLine(hasScheduled: hasScheduled))
            )
        }
    }

    func view(for slice: ReportFlowSlice) -> AnyView {
        switch self {
        case let .whole(view):
            view
        case let .table(rows, hasScheduled):
            AnyView(ReportMedicationBlock(
                rows: Array(rows[slice.rows ?? rows.indices]), hasScheduled: hasScheduled,
                isContinued: slice.isContinued, showsNote: slice.showsNote
            ))
        }
    }
}
