// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct LogDoseView: View {
    let medications: MedicationsModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication") {}
            }
            .navigationTitle("Log Dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("log-dose-cancel")
                }
            }
        }
    }
}
