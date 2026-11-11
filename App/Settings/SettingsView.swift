// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyMedicationModel
import SwiftUI

struct SettingsView: View {
    let model: EntryLogModel
    let medications: MedicationsModel
    let dailyReminder: DailyReminderSettings
    let reminderScheduler: DailyReminderScheduler
    @State private var isConfirmingErase = false
    @State private var eraseTicks = 0

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
                RemindersSection(settings: dailyReminder, scheduler: reminderScheduler)
                CardSection(
                    Text("Your data"),
                    footnote: Text("Your data stays on this iPhone unless you share an export."),
                    id: "your-data"
                ) {
                    Button("Erase all data", role: .destructive) {
                        isConfirmingErase = true
                    }
                    .rowHeight()
                    .accessibilityIdentifier("settings-erase-all")
                }
                FooterBlockSection(Text("About"), footer: AboutBlock()) {
                    Link(destination: repository) {
                        HStack {
                            Text("Source code and license")
                                .foregroundStyle(Color.ink)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Color.ink2)
                                .accessibilityHidden(true)
                        }
                    }
                    .rowHeight()
                    .accessibilityIdentifier("settings-source-code")
                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        Text("Privacy policy")
                            .foregroundStyle(Color.ink)
                    }
                    .rowHeight()
                    .accessibilityIdentifier("settings-privacy-policy")
                }
            }
            .entryDeleteConfirmation(isPresented: $isConfirmingErase, words: .allData) {
                try model.removeAll()
                do {
                    try medications.removeAll()
                } catch {
                    throw PartialDelete()
                }
                eraseTicks += 1
            }
            .sensoryFeedback(.warning, trigger: eraseTicks)
            .screenSpacing()
            .lastBlockClearance()
            .accessibilityIdentifier("settings-screen")
            .navigationTitle("Settings")
        }
    }
}
