// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

/// Builds the export on tap and shares it. The file is deleted however the sheet closes, and a failed build shows an
/// alert that names nothing from the data or the error.
struct ExportDataRow: View {
    let read: @MainActor () throws -> ExportData
    @State private var flow = ExportFlow()

    var body: some View {
        Button(action: start) {
            HStack {
                Text("Export data")
                    .foregroundStyle(Color.ink)
                Spacer()
                trailing
                    .minimumTapTarget()
            }
        }
        .rowHeight()
        .accessibilityLabel(flow.isShowingProgress ? Text("Exporting") : Text("Export data"))
        .accessibilityIdentifier("settings-export")
        .sheet(isPresented: isSharing, onDismiss: closeSheet) {
            if let file = flow.sharedFile {
                ShareSheet(file: file, onClose: closeSheet)
                    .presentationDetents([.medium, .large])
            }
        }
        .alert("Couldn't export", isPresented: isFailing) {
            Button("OK") { flow.failureDismissed() }
        } message: {
            Text("Nothing was shared. Try again.")
        }
    }

    @ViewBuilder private var trailing: some View {
        if flow.isShowingProgress {
            ProgressView()
        } else {
            Image(systemName: "square.and.arrow.up")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.ink2)
                .accessibilityHidden(true)
        }
    }

    private var isSharing: Binding<Bool> {
        Binding(get: { flow.sharedFile != nil }, set: {
            if !$0 {
                closeSheet()
            }
        })
    }

    private var isFailing: Binding<Bool> {
        Binding(get: { flow.isShowingFailure }, set: {
            if !$0 {
                flow.failureDismissed()
            }
        })
    }

    private func start() {
        guard flow.tap() else { return }
        let progress = Task {
            try await Task.sleep(for: ExportFlow.progressDelay)
            flow.progressDelayPassed()
        }
        Task {
            let result = await build()
            progress.cancel()
            flow.finish(result)
        }
    }

    private func build() async -> Result<URL, any Error> {
        do {
            return try await .success(ExportBuild.archive(read()))
        } catch {
            return .failure(error)
        }
    }

    /// Runs once per sheet: the share sheet's own handler and the sheet's dismissal both call it, and only the first
    /// gets a file back.
    private func closeSheet() {
        guard let file = flow.sheetClosed() else { return }
        try? FileManager.default.removeItem(at: file)
    }
}
