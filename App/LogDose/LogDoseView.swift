// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyMedicationModel
import SwiftUI

struct LogDoseView: View {
    let medications: MedicationsModel
    let model: EntryLogModel
    let onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedID: UUID?
    @State private var selectionTicks = 0
    @State private var saveTicks = 0
    @State private var isShowingNewMedication = false
    @State private var isShowingNewEntry = false
    /// The reading the person picked, or the one a new entry became. Nil means the newest in the window.
    @State private var manualReadingID: UUID?
    // Made once per opening, so a second tap on "Save dose" logs the same dose again.
    @State private var doseID = UUID()
    @State private var takenAt = Date.now
    /// Set once the person picks a time, so a reading added later does not move the dose.
    @State private var isTimeChosen = false
    @State private var doseSave = DoseSave()
    @State private var isShowingSaveFailure = false

    init(medications: MedicationsModel, model: EntryLogModel, onSaved: @escaping () -> Void) {
        self.medications = medications
        self.model = model
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication") {
                    if active.isEmpty {
                        Text("No medications yet")
                            .accessibilityIdentifier("dose-no-medications")
                    }
                    ForEach(active) { medication in
                        medicationRow(medication)
                    }
                    Button("Add medication") {
                        isShowingNewMedication = true
                    }
                    .accessibilityIdentifier("dose-add-medication")
                }
                Section {
                    DateSection(
                        date: dateBinding,
                        labelPadding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color("CardBackground").clipShape(.card))
                    .listRowSeparator(.hidden)
                }
                readingSection
            }
            .scrollContentBackground(.hidden)
            .background(Color("PageBackground"))
            .navigationTitle("Log Dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                        .accessibilityIdentifier("log-dose-cancel")
                }
                if !medications.medications.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink("Manage") {
                            MedicationsView(medications: medications)
                        }
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                        .accessibilityIdentifier("log-dose-manage")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    saveDose()
                } label: {
                    Text("Save dose")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .disabled(checkedID == nil)
                .accessibilityIdentifier("save-dose")
                .padding()
            }
            .alert("This dose could not be saved.", isPresented: $isShowingSaveFailure) {
                Button("OK") {}
            }
            .onChange(of: active) {
                selectedID = MedicationSelection.kept(selectedID, in: active)
            }
            .sheet(isPresented: $isShowingNewMedication) {
                MedicationFormView(medications: medications, onSaved: medicationSaved)
            }
            .sheet(isPresented: $isShowingNewEntry) {
                NewEntryView(
                    model: model,
                    onSaved: { saveTicks += 1 },
                    onAdded: readingAdded
                )
            }
            .sensoryFeedback(.selection, trigger: selectionTicks)
            .sensoryFeedback(.success, trigger: saveTicks)
            .onAppear { medications.reload() }
        }
    }

    private var active: [Medication] {
        medications.active
    }

    private var checkedID: UUID? {
        MedicationSelection.kept(selectedID, in: active)
    }

    private var dateBinding: Binding<Date> {
        Binding(
            get: { takenAt },
            set: {
                takenAt = $0
                isTimeChosen = true
            }
        )
    }

    private var reading: Entry? {
        ReadingWindow.pick(manualReadingID, in: model.entries, before: takenAt)
    }

    /// New Entry starts its draft at the moment it opens, which is after the dose time, so a reading saved there
    /// would fall outside the window. The dose time moves to it, unless the person chose the time by hand.
    private func readingAdded(_ saved: Entry) {
        manualReadingID = saved.id
        if !isTimeChosen {
            takenAt = max(takenAt, saved.date)
        }
    }

    private var readingSection: some View {
        Section {
            if let reading {
                Button {} label: {
                    ReadingRow(caption: String(localized: "Before this dose"), entry: reading)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("before-reading-row")
            } else {
                Button("Log how you feel") {
                    isShowingNewEntry = true
                }
                .accessibilityIdentifier("log-how-you-feel-row")
            }
        } footer: {
            if reading != nil {
                Text("Your latest entry before this dose. Tap to choose another.")
                    .accessibilityIdentifier("before-reading-footer")
            }
        }
    }

    private func medicationRow(_ medication: Medication) -> some View {
        let isChecked = medication.id == checkedID
        return Button {
            select(medication)
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(medication.listTitle)
                        .fontWeight(isChecked ? .semibold : .regular)
                    Text(medication.takenAs.title)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isChecked {
                    Image(systemName: "checkmark")
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("dose-medication-row")
        .accessibilityAddTraits(isChecked ? .isSelected : [])
    }

    private func saveDose() {
        guard let medication = active.first(where: { $0.id == checkedID }) else { return }
        let dose = Dose.logged(
            id: doseID,
            medication: medication,
            takenAt: takenAt,
            entries: model.entries,
            manualReadingID: manualReadingID
        )
        do {
            let logged = try doseSave.save(dose, log: medications.logDose)
            if logged {
                onSaved()
            }
            dismiss()
        } catch {
            isShowingSaveFailure = true
        }
    }

    private func select(_ medication: Medication) {
        guard medication.id != checkedID else { return }
        selectedID = medication.id
        selectionTicks += 1
    }

    /// The new medication is the newest, so it is last in the active list and becomes the chosen row. Choosing it
    /// does not tick, because the success haptic plays instead.
    private func medicationSaved() {
        selectedID = active.last?.id
        saveTicks += 1
    }
}
