// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyMedicationModel
import SwiftUI

/// The period is the screen's own state, so every open starts on three months and nothing is remembered.
struct ReportView: View {
    let model: EntryLogModel
    let medications: MedicationsModel
    @State private var period = ReportPeriod.threeMonths
    @State private var isBuilding = false
    @State private var preview: PreviewFile?

    private var summary: ReportSummary {
        ReportSummary(entries: model.entries, doses: medications.doses, period: period, now: .now, calendar: .current)
    }

    var body: some View {
        Form {
            CardSection(
                Text("Period"),
                footnote: countsLine,
                id: "report-period-section",
                footnoteID: "report-counts"
            ) {
                Picker("Period", selection: $period) {
                    ForEach(ReportPeriod.allCases, id: \.self) { period in
                        Text(period.title).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .controlSize(.large)
                .labelsHidden()
                .accessibilityLabel("Period")
                .accessibilityIdentifier("report-period")
                .nonCardBlock()
            }
        }
        .screenSpacing()
        .accessibilityIdentifier("report-screen")
        .navigationTitle("Report")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { previewButton }
        .sheet(item: $preview) { file in
            ReportPreview(url: file.url).ignoresSafeArea()
        }
    }

    private var countsLine: Text {
        Text(verbatim: ReportCountsLine.text(
            summary: summary, period: period, now: .now, locale: .current, calendar: .current, bundle: .main
        ))
    }

    private var previewButton: some View {
        Button(action: buildPreview) {
            Group {
                if isBuilding {
                    ProgressView().tint(Color.onTint)
                } else {
                    Text("Preview")
                }
            }
            .frame(maxWidth: .infinity, minHeight: Spacing.primaryButtonLabelHeight)
        }
        .primaryButton()
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .disabled(summary.isEmpty)
        .padding(.horizontal, Spacing.screenMargin)
        .padding(.bottom, Spacing.bottomClearance)
        .accessibilityIdentifier("report-preview")
    }

    private func buildPreview() {
        guard !isBuilding, preview == nil else { return }
        isBuilding = true
        Task {
            await Task.yield()
            defer { isBuilding = false }
            guard let url = try? ReportPDFFile.write(page(now: .now)) else { return }
            preview = PreviewFile(url: url)
        }
    }

    /// One `now` for the whole page, so the header and the totals count the same days.
    private func page(now: Date) -> ReportPage {
        let summary = ReportSummary(
            entries: model.entries, doses: medications.doses, period: period, now: now, calendar: .current
        )
        return ReportPage(
            size: .forRegion(Locale.current.region),
            headerLine: ReportHeaderLine.text(
                period: period, now: now, locale: .current, calendar: .current, bundle: .main
            ),
            totals: ReportTotalsText(summary: summary, locale: .current, calendar: .current, bundle: .main),
            pageNumber: 1,
            pageCount: 1
        )
    }
}

private struct PreviewFile: Identifiable {
    let url: URL
    let id = UUID()
}

private extension ReportPeriod {
    var title: LocalizedStringKey {
        switch self {
        case .oneMonth: "1 month"
        case .threeMonths: "3 months"
        case .sixMonths: "6 months"
        }
    }
}
