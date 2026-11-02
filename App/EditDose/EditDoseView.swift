// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyMedicationModel
import SwiftUI

struct EditDoseView: View {
    let dose: Dose
    let medications: MedicationsModel
    let model: EntryLogModel
    let onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedID: UUID?
    @State private var takenAt: Date
    @State private var doseSave = DoseSave()
    @State private var isShowingSaveFailure = false

    init(dose: Dose, medications: MedicationsModel, model: EntryLogModel, onSaved: @escaping () -> Void) {
        self.dose = dose
        self.medications = medications
        self.model = model
        self.onSaved = onSaved
        _selectedID = State(initialValue: dose.medicationID)
        _takenAt = State(initialValue: dose.takenAt)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication") {
                    ForEach(EditDoseMedications.choices(for: dose, in: medications.medications)) { medication in
                        medicationRow(medication)
                    }
                }
                Section {
                    DateSection(date: $takenAt)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                readingSection
            }
            .scrollContentBackground(.hidden)
            .background(Color("PageBackground"))
            .accessibilityIdentifier("edit-dose-screen")
            .navigationTitle("Edit Dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                        .accessibilityIdentifier("edit-dose-cancel")
                }
            }
            .safeAreaInset(edge: .bottom) {
                saveButton
            }
            .alert("This dose could not be saved.", isPresented: $isShowingSaveFailure) {
                Button("OK") {}
            }
        }
    }

    private var saveButton: some View {
        Button {
            saveChanges()
        } label: {
            Text("Save changes")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
        .accessibilityIdentifier("save-dose-changes")
        .padding()
    }

    /// The dose keeps its own check-in delay and its readings. Only the medication and the time come from the form.
    private func saveChanges() {
        guard let selectedID else { return }
        var edited = dose
        edited.medicationID = selectedID
        edited.takenAt = takenAt
        do {
            let saved = try doseSave.save(edited, log: medications.replaceDose)
            if saved {
                onSaved()
            }
            dismiss()
        } catch {
            isShowingSaveFailure = true
        }
    }

    /// A reading that was deleted leaves the dose with no before-reading, which shows as None and opens nothing.
    private var readingSection: some View {
        let readings = DoseReadings(dose, in: model.entries)
        return Section {
            if let before = readings.before {
                NavigationLink {
                    NewEntryView(model: model, mode: .edit(before))
                } label: {
                    ReadingRow(caption: String(localized: "Before this dose"), entry: before)
                }
                .accessibilityIdentifier("before-reading-row")
            } else {
                LabeledContent("Before this dose") {
                    Text("None")
                }
                .accessibilityIdentifier("before-reading-row")
            }
            if let after = readings.after {
                NavigationLink {
                    NewEntryView(model: model, mode: .edit(after))
                } label: {
                    ReadingRow(caption: afterCaption, entry: after)
                }
                .accessibilityIdentifier("after-reading-row")
            }
        }
    }

    private var afterCaption: String {
        "\(String(localized: "After")) · \(String(localized: "checked in at"))"
    }

    private func medicationRow(_ medication: Medication) -> some View {
        let isChecked = medication.id == selectedID
        return Button {
            selectedID = medication.id
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
}
