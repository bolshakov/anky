// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyMedicationModel
import SwiftUI

struct RootView: View {
    let model: EntryLogModel
    let medications: MedicationsModel
    @State private var selection = Tab.today
    @State private var reminders = CheckInReminderScheduler()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: $selection) {
            TodayView(model: model, medications: medications)
                .tabItem {
                    Label("Today", systemImage: "calendar")
                        .fontWeight(selection == .today ? .bold : .regular)
                }
                .tag(Tab.today)

            HistoryView(model: model, medications: medications)
                .tabItem {
                    Label("History", systemImage: "clock")
                        .fontWeight(selection == .history ? .bold : .regular)
                }
                .tag(Tab.history)
        }
        .onChange(of: reminderInputs, initial: true) { _, inputs in
            guard inputs.phase == .active else { return }
            reminders.reconcile(doses: inputs.doses, medications: inputs.medications, entries: inputs.entries)
        }
    }

    private var reminderInputs: ReminderInputs {
        ReminderInputs(
            doses: medications.doses,
            medications: medications.medications,
            entries: model.entries,
            phase: scenePhase
        )
    }

    private struct ReminderInputs: Equatable {
        let doses: [Dose]
        let medications: [Medication]
        let entries: [Entry]
        let phase: ScenePhase
    }

    private enum Tab {
        case today, history
    }
}
