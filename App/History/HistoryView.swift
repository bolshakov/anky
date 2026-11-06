// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyMedicationModel
import SwiftUI

struct HistoryView: View {
    let model: EntryLogModel
    let medications: MedicationsModel
    @State private var now = Date.now
    @State private var editing: Entry?
    @State private var editingDose: Dose?
    @State private var checkingIn: Dose?
    @State private var pendingDelete: Entry?
    @State private var pendingDoseDelete: Dose?
    @State private var saveTicks = 0
    @State private var derived: HistoryDerived?

    private var sections: [DaySection] {
        HistoryList.sections(model.entries, doses: medications.doses, now: now, calendar: .current)
    }

    private var inputs: HistoryInputs {
        HistoryInputs(
            entries: model.entries,
            doses: medications.doses,
            medications: medications.medications,
            now: now
        )
    }

    private func open(_ dose: Dose) {
        if (derived ?? HistoryDerived(inputs)).waiting.contains(dose.id) {
            checkingIn = dose
        } else {
            editingDose = dose
        }
    }

    private var isConfirmingDelete: Binding<Bool> {
        Binding(
            get: { pendingDelete != nil },
            set: { isShowing in
                if !isShowing {
                    pendingDelete = nil
                }
            }
        )
    }

    private var isConfirmingDoseDelete: Binding<Bool> {
        Binding(
            get: { pendingDoseDelete != nil },
            set: { isShowing in
                if !isShowing {
                    pendingDoseDelete = nil
                }
            }
        )
    }

    var body: some View {
        // Captured here, so the alert's button deletes the entry it was asked about even after the binding clears.
        let target = pendingDelete
        let doseTarget = pendingDoseDelete
        let days = sections
        let current = derived ?? HistoryDerived(inputs)
        NavigationStack {
            Group {
                if days.isEmpty {
                    EmptyHistoryView()
                } else {
                    List {
                        ForEach(days) { section in
                            DaySectionView(
                                section: section,
                                medications: medications.medications,
                                entriesByID: current.entriesByID,
                                waiting: current.waiting,
                                onSelect: { editing = $0 },
                                onSelectDose: open,
                                onDelete: { pendingDelete = $0 },
                                onDeleteDose: { pendingDoseDelete = $0 },
                                isLastDay: section.id == days.last?.id
                            )
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .headerProminence(.increased)
                }
            }
            .entryDeleteConfirmation(isPresented: isConfirmingDelete) {
                guard let target else { return }
                try model.remove(id: target.id)
            }
            .entryDeleteConfirmation(isPresented: isConfirmingDoseDelete, words: .dose) {
                guard let doseTarget else { return }
                try medications.removeDose(id: doseTarget.id)
            }
            .background(Color("PageBackground"))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("history-screen")
            .navigationTitle("History")
            .onChange(of: inputs, initial: true) { _, inputs in
                derived = HistoryDerived(inputs)
            }
            .checkInClock(now: $now, nextChange: current.nextCheckInChange)
            .sheet(item: $editing) { entry in
                NewEntryView(model: model, mode: .edit(entry), onSaved: { saveTicks += 1 })
            }
            .sheet(item: $editingDose) { dose in
                EditDoseView(dose: dose, medications: medications, model: model, onSaved: { saveTicks += 1 })
            }
            .sheet(item: $checkingIn) { dose in
                CheckInView(dose: dose, medications: medications, model: model, onSaved: { saveTicks += 1 })
            }
            .sensoryFeedback(.success, trigger: saveTicks)
        }
    }
}
