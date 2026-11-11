// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyMedicationModel
import SwiftUI

/// Today's sheets, and the order a reminder tap closes and opens them in. Check In and New Entry wait for the sheet
/// that was open to finish dismissing, since SwiftUI can drop a sheet presented while another one is still on its way
/// out.
struct TodaySheets: ViewModifier {
    let model: EntryLogModel
    let medications: MedicationsModel
    let onSaved: () -> Void
    let onCreated: () -> Void
    let onDeleted: () -> Void
    @Binding var reminderCheckIn: Dose?
    @Binding var reminderNewEntry: Bool
    @Binding var reminderLogDose: UUID?
    @Binding var isShowingNewEntry: Bool
    @Binding var isShowingLogDose: Bool
    @Binding var editing: Entry?
    @Binding var editingDose: Dose?
    @Binding var checkingIn: Dose?
    @State private var logDoseMedication: UUID?
    @State private var pending: Pending?

    private enum Pending {
        case checkIn(Dose)
        case newEntry
        case logDose(UUID)
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: reminderCheckIn, initial: true) { _, dose in
                guard let dose else { return }
                reminderCheckIn = nil
                showCheckIn(dose)
            }
            .onChange(of: reminderNewEntry, initial: true) { _, isRequested in
                guard isRequested else { return }
                reminderNewEntry = false
                showNewEntry()
            }
            .onChange(of: reminderLogDose, initial: true) { _, medicationID in
                guard let medicationID else { return }
                reminderLogDose = nil
                showLogDose(medicationID)
            }
            .sheet(isPresented: $isShowingNewEntry, onDismiss: presentPending) {
                NewEntryView(model: model, onSaved: onCreated)
            }
            .sheet(isPresented: $isShowingLogDose, onDismiss: logDoseDismissed) {
                LogDoseView(medications: medications, model: model, preselected: logDoseMedication, onSaved: onSaved)
            }
            .sheet(item: $editing, onDismiss: presentPending) { entry in
                NewEntryView(model: model, mode: .edit(entry), onSaved: onSaved)
                    .onDeleted(onDeleted)
            }
            .sheet(item: $editingDose, onDismiss: presentPending) { dose in
                EditDoseView(dose: dose, medications: medications, model: model, onSaved: onSaved)
                    .onDeleted(onDeleted)
            }
            .sheet(item: $checkingIn, onDismiss: presentPending) { dose in
                CheckInView(dose: dose, medications: medications, model: model, onSaved: onSaved)
            }
    }

    private func showCheckIn(_ dose: Dose) {
        guard isShowingNewEntry || isShowingLogDose || editing != nil || editingDose != nil else {
            checkingIn = dose
            return
        }
        pending = .checkIn(dose)
        closeSheets()
    }

    private func showNewEntry() {
        guard !isShowingNewEntry else { return }
        guard isShowingLogDose || editing != nil || editingDose != nil || checkingIn != nil else {
            isShowingNewEntry = true
            return
        }
        pending = .newEntry
        closeSheets()
        checkingIn = nil
    }

    private func showLogDose(_ medicationID: UUID) {
        guard isShowingNewEntry || isShowingLogDose || editing != nil || editingDose != nil || checkingIn != nil else {
            logDoseMedication = medicationID
            isShowingLogDose = true
            return
        }
        pending = .logDose(medicationID)
        closeSheets()
        checkingIn = nil
    }

    private func logDoseDismissed() {
        logDoseMedication = nil
        presentPending()
    }

    private func closeSheets() {
        isShowingNewEntry = false
        isShowingLogDose = false
        editing = nil
        editingDose = nil
    }

    private func presentPending() {
        guard let next = pending else { return }
        pending = nil
        switch next {
        case let .checkIn(dose): checkingIn = dose
        case .newEntry: isShowingNewEntry = true
        case let .logDose(medicationID):
            logDoseMedication = medicationID
            isShowingLogDose = true
        }
    }
}
