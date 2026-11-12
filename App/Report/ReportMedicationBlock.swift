// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

/// A run of the Medication table's rows. The heading, the column header, each row and the note carry their own spacing,
/// so each can be measured alone and their heights add up to the block's.
struct ReportMedicationBlock: View {
    let rows: [ReportMedicationRowText]
    let hasScheduled: Bool
    let isContinued: Bool
    let showsNote: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ReportMedicationHeading(isContinued: isContinued)
            if rows.isEmpty {
                Text("None logged in this period")
                    .font(.system(size: ReportMetrics.bodySize))
                    .foregroundStyle(ReportPalette.secondary)
            } else {
                ReportMedicationColumnHeader()
                ForEach(rows.indices, id: \.self) { index in
                    ReportMedicationRowView(text: rows[index])
                }
                if showsNote {
                    ReportMedicationNoteLine(hasScheduled: hasScheduled)
                }
            }
        }
    }
}

struct ReportMedicationHeading: View {
    let isContinued: Bool

    var body: some View {
        Group {
            if isContinued {
                Text("Medication, continued")
            } else {
                Text("Medication: doses, and pain before and after")
            }
        }
        .font(.system(size: ReportMetrics.totalsSize, weight: .semibold))
        .padding(.bottom, ReportMetrics.headingToContent)
    }
}

struct ReportMedicationColumnHeader: View {
    var body: some View {
        VStack(spacing: 0) {
            ReportMedicationColumns(
                alignment: .bottom,
                name: Text("Medication"),
                cells: Text("Doses"),
                Text("Per week"),
                Text("With an after-reading"),
                Text("Pain before: average (lowest–highest)"),
                Text("Pain after: average (lowest–highest)"),
                Text("Average time to after-reading")
            )
            .font(.system(size: ReportMetrics.smallSize))
            .foregroundStyle(ReportPalette.secondary)
            ReportHairline()
        }
    }
}

struct ReportMedicationRowView: View {
    let text: ReportMedicationRowText

    var body: some View {
        VStack(spacing: 0) {
            ReportMedicationColumns(
                alignment: .firstTextBaseline,
                name: name,
                cells: Text(verbatim: text.doses),
                Text(verbatim: text.perWeek),
                Text(verbatim: text.withAfter),
                Text(verbatim: text.before),
                Text(verbatim: text.after),
                Text(verbatim: text.time)
            )
            .font(.system(size: ReportMetrics.bodySize))
            .monospacedDigit()
            ReportHairline()
        }
    }

    private var name: some View {
        VStack(alignment: .leading, spacing: ReportMetrics.nameToKind) {
            Text(verbatim: text.name)
            Text(verbatim: text.kind)
                .font(.system(size: ReportMetrics.smallSize))
                .foregroundStyle(ReportPalette.secondary)
        }
    }
}

struct ReportMedicationNoteLine: View {
    let hasScheduled: Bool

    var body: some View {
        Text(verbatim: ReportMedicationNote.text(hasScheduled: hasScheduled, locale: .current, bundle: .main))
            .font(.system(size: ReportMetrics.smallSize))
            .foregroundStyle(ReportPalette.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, ReportMetrics.headingToContent)
    }
}

/// The name in the column that takes what the fixed columns leave, then one cell per fixed column. A row's widths never
/// depend on another row, so a table split across pages keeps its columns.
private struct ReportMedicationColumns<Name: View>: View {
    let alignment: VerticalAlignment
    let name: Name
    let cells: [Text]

    init(alignment: VerticalAlignment, name: Name, cells: Text...) {
        self.alignment = alignment
        self.name = name
        self.cells = cells
    }

    var body: some View {
        HStack(alignment: alignment, spacing: ReportMetrics.medicationColumnGap) {
            name
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(Array(zip(cells, ReportMetrics.medicationColumnWidths).enumerated()), id: \.offset) { _, column in
                column.0
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: column.1, alignment: .trailing)
            }
        }
        .padding(.vertical, ReportMetrics.medicationRowInset)
    }
}

extension ReportMetrics {
    static let medicationColumnGap: CGFloat = 8
    static let medicationRowInset: CGFloat = 4
    static let nameToKind: CGFloat = 1
    /// Doses, Per week, With an after-reading, Pain before, Pain after and Average time, in that order.
    static let medicationColumnWidths: [CGFloat] = [36, 40, 56, 90, 90, 64]
}
