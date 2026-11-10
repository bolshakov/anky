// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyMedicationModel
import SwiftUI

/// Today's sheets, and the order a reminder tap closes and opens them in. Check In waits for the sheet that was open
/// to finish dismissing, since SwiftUI can drop a sheet presented while another one is still on its way out.
struct TodaySheets: ViewModifier {
    let model: EntryLogModel
    let medications: MedicationsModel
    let onSaved: () -> Void
    let onCreated: () -> Void
    let onDeleted: () -> Void
    @Binding var reminderCheckIn: Dose?
    @Binding var isShowingNewEntry: Bool
    @Binding var isShowingLogDose: Bool
    @Binding var editing: Entry?
    @Binding var editingDose: Dose?
    @Binding var checkingIn: Dose?
    @State private var pendingCheckIn: Dose?

    func body(content: Content) -> some View {
        content
            .onChange(of: reminderCheckIn, initial: true) { _, dose in
                guard let dose else { return }
                reminderCheckIn = nil
                showCheckIn(dose)
            }
            .sheet(isPresented: $isShowingNewEntry, onDismiss: presentPendingCheckIn) {
                NewEntryView(model: model, onSaved: onCreated)
            }
            .sheet(isPresented: $isShowingLogDose, onDismiss: presentPendingCheckIn) {
                LogDoseView(medications: medications, model: model, onSaved: onSaved)
            }
            .sheet(item: $editing, onDismiss: presentPendingCheckIn) { entry in
                NewEntryView(model: model, mode: .edit(entry), onSaved: onSaved)
                    .onDeleted(onDeleted)
            }
            .sheet(item: $editingDose, onDismiss: presentPendingCheckIn) { dose in
                EditDoseView(dose: dose, medications: medications, model: model, onSaved: onSaved)
                    .onDeleted(onDeleted)
            }
            .sheet(item: $checkingIn) { dose in
                CheckInView(dose: dose, medications: medications, model: model, onSaved: onSaved)
            }
    }

    private func showCheckIn(_ dose: Dose) {
        guard isShowingNewEntry || isShowingLogDose || editing != nil || editingDose != nil else {
            checkingIn = dose
            return
        }
        pendingCheckIn = dose
        isShowingNewEntry = false
        isShowingLogDose = false
        editing = nil
        editingDose = nil
    }

    private func presentPendingCheckIn() {
        guard let dose = pendingCheckIn else { return }
        pendingCheckIn = nil
        checkingIn = dose
    }
}
