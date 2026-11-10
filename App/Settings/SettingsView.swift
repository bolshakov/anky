// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyMedicationModel
import SwiftUI

struct SettingsView: View {
    let model: EntryLogModel
    let medications: MedicationsModel

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
            }
            .screenSpacing()
            .accessibilityIdentifier("settings-screen")
            .navigationTitle("Settings")
        }
    }
}
