// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyMedicationModel
import SwiftUI

struct SettingsView: View {
    let model: EntryLogModel
    let medications: MedicationsModel
    @State private var isConfirmingErase = false
    @State private var eraseTicks = 0

    var body: some View {
        NavigationStack {
            Form {
                CardSection(id: "settings-general") {
                    NavigationLink {
                        MedicationsView(medications: medications)
                    } label: {
                        Text("Manage medications")
                            .foregroundStyle(Color.ink)
                    }
                    .rowHeight()
                    .accessibilityIdentifier("settings-manage-medications")
                }
                CardSection(
                    Text("Your data"),
                    footnote: Text("Everything stays on this iPhone."),
                    id: "your-data"
                ) {
                    Button("Erase all data", role: .destructive) {
                        isConfirmingErase = true
                    }
                    .rowHeight()
                    .accessibilityIdentifier("settings-erase-all")
                }
            }
            .entryDeleteConfirmation(isPresented: $isConfirmingErase, words: .allData) {
                try model.removeAll()
                eraseTicks += 1
            }
            .sensoryFeedback(.warning, trigger: eraseTicks)
            .screenSpacing()
            .accessibilityIdentifier("settings-screen")
            .navigationTitle("Settings")
        }
    }
}
