// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyMedicationModel
import SwiftUI

struct SettingsView: View {
    let model: EntryLogModel
    let medications: MedicationsModel

    private let repository = URL(string: "https://github.com/bolshakov/anky")!

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
                FooterBlockSection(Text("About"), footer: AboutBlock()) {
                    Link(destination: repository) {
                        Text("Source code and licence")
                            .foregroundStyle(Color.ink)
                    }
                    .rowHeight()
                    .accessibilityIdentifier("settings-source-code")
                }
            }
            .screenSpacing()
            .accessibilityIdentifier("settings-screen")
            .navigationTitle("Settings")
        }
    }
}
