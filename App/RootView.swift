// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyMedicationModel
import SwiftUI

struct RootView: View {
    let model: EntryLogModel
    let medications: MedicationsModel
    let basdai: BasdaiModel
    let reminderTaps: ReminderTapModel
    @State private var selection = Tab.today
    @State private var reminderCheckIn: Dose?
    @State private var reminderNewEntry = false
    @State private var reminderLogDose: UUID?
    @State private var checkInAwaitingHistory: Dose?
    @State private var newEntryAwaitingHistory = false
    @State private var logDoseAwaitingHistory: UUID?
    @State private var reminders = CheckInReminderScheduler()
    @State private var dailyReminder = DailyReminderSettings()
    @State private var dailyReminderScheduler = DailyReminderScheduler()
    @State private var doseNotifications = DoseNotificationScheduler()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: $selection) {
            TodayView(
                model: model,
                medications: medications,
                reminderCheckIn: $reminderCheckIn,
                reminderNewEntry: $reminderNewEntry,
                reminderLogDose: $reminderLogDose
            )
            .tabItem {
                Label("Today", systemImage: "calendar")
                    .fontWeight(selection == .today ? .bold : .regular)
            }
            .tag(Tab.today)

            HistoryView(
                model: model,
                medications: medications,
                isClosingSheets: checkInAwaitingHistory != nil || newEntryAwaitingHistory || logDoseAwaitingHistory !=
                    nil,
                onSheetsClosed: historyClosedSheets
            )
            .tabItem {
                Label("History", systemImage: "clock")
                    .fontWeight(selection == .history ? .bold : .regular)
            }
            .tag(Tab.history)

            SettingsView(
                model: model,
                medications: medications,
                dailyReminder: dailyReminder,
                reminderScheduler: dailyReminderScheduler
            )
            .tabItem {
                Label("Settings", systemImage: "slider.horizontal.3")
                    .fontWeight(selection == .settings ? .bold : .regular)
            }
            .tag(Tab.settings)
        }
        .onChange(of: reminderInputs, initial: true) { _, inputs in
            guard inputs.phase == .active else { return }
            let checkIns = reminders.reconcile(
                doses: inputs.doses,
                medications: inputs.medications,
                entries: inputs.entries
            )
            let daily = dailyReminderScheduler.reconcile(
                settings: dailyReminder,
                entries: inputs.entries,
                doses: inputs.doses
            )
            doseNotifications.reconcile(medications: inputs.medications, after: [checkIns, daily])
        }
        .onChange(of: tapInputs, initial: true) { _, inputs in
            guard inputs.phase == .active, let tap = inputs.tap else { return }
            reminderTaps.pending = nil
            open(tap)
        }
        .onChange(of: newEntryInputs, initial: true) { _, inputs in
            guard inputs.phase == .active, inputs.isPending else { return }
            reminderTaps.pendingNewEntry = false
            if selection == .history {
                newEntryAwaitingHistory = true
            } else {
                showNewEntryOnToday()
            }
        }
        .onChange(of: logDoseInputs, initial: true) { _, inputs in
            guard inputs.phase == .active, let medicationID = inputs.medicationID else { return }
            reminderTaps.pendingLogDose = nil
            openLogDose(for: medicationID)
        }
    }

    private func openLogDose(for medicationID: UUID) {
        guard DoseTap.opensLogDose(medicationID: medicationID, medications: medications.medications) else {
            selection = .today
            return
        }
        if selection == .history {
            logDoseAwaitingHistory = medicationID
        } else {
            showLogDoseOnToday(medicationID)
        }
    }

    private func open(_ tap: ReminderTapModel.Tap) {
        let destination = CheckInDue.destination(
            forReminderOf: tap.doseID,
            doses: medications.doses,
            medications: medications.medications,
            entries: model.entries,
            now: tap.at
        )
        guard case let .checkIn(dose) = destination else {
            selection = .today
            return
        }
        if selection == .history {
            checkInAwaitingHistory = dose
        } else {
            showCheckInOnToday(dose)
        }
    }

    private func historyClosedSheets() {
        if newEntryAwaitingHistory {
            newEntryAwaitingHistory = false
            showNewEntryOnToday()
        }
        if let medicationID = logDoseAwaitingHistory {
            logDoseAwaitingHistory = nil
            showLogDoseOnToday(medicationID)
        }
        guard let dose = checkInAwaitingHistory else { return }
        checkInAwaitingHistory = nil
        showCheckInOnToday(dose)
    }

    private func showNewEntryOnToday() {
        selection = .today
        reminderNewEntry = true
    }

    private func showLogDoseOnToday(_ medicationID: UUID) {
        selection = .today
        reminderLogDose = medicationID
    }

    private func showCheckInOnToday(_ dose: Dose) {
        selection = .today
        reminderCheckIn = dose
    }

    private var reminderInputs: ReminderInputs {
        ReminderInputs(
            doses: medications.doses,
            medications: medications.medications,
            entries: model.entries,
            dailyReminder: DailyReminderChoice(isOn: dailyReminder.isOn, time: dailyReminder.time),
            phase: scenePhase
        )
    }

    private var tapInputs: TapInputs {
        TapInputs(tap: reminderTaps.pending, phase: scenePhase)
    }

    private var logDoseInputs: LogDoseInputs {
        LogDoseInputs(medicationID: reminderTaps.pendingLogDose, phase: scenePhase)
    }

    private var newEntryInputs: NewEntryInputs {
        NewEntryInputs(isPending: reminderTaps.pendingNewEntry, phase: scenePhase)
    }

    private struct LogDoseInputs: Equatable {
        let medicationID: UUID?
        let phase: ScenePhase
    }

    private struct NewEntryInputs: Equatable {
        let isPending: Bool
        let phase: ScenePhase
    }

    private struct TapInputs: Equatable {
        let tap: ReminderTapModel.Tap?
        let phase: ScenePhase
    }

    private struct ReminderInputs: Equatable {
        let doses: [Dose]
        let medications: [Medication]
        let entries: [Entry]
        let dailyReminder: DailyReminderChoice
        let phase: ScenePhase
    }

    private struct DailyReminderChoice: Equatable {
        let isOn: Bool
        let time: DailyReminderTime
    }

    private enum Tab {
        case today, history, settings
    }
}
