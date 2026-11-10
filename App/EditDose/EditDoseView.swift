// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyMedicationModel
import SwiftUI

struct EditDoseView: View {
    private static let dateBlockID = "date-block"
    let dose: Dose
    let medications: MedicationsModel
    let model: EntryLogModel
    let onSaved: () -> Void
    private(set) var deletedAction: () -> Void = {}
    @Environment(\.dismiss) private var dismiss
    @State private var selectedID: UUID?
    @State private var takenAt: Date
    @State private var doseSave = DoseSave()
    @State private var isShowingSaveFailure = false
    @State private var isConfirmingDelete = false
    @State private var readingSaveTicks = 0
    @State private var readingDeleteTicks = 0

    init(dose: Dose, medications: MedicationsModel, model: EntryLogModel, onSaved: @escaping () -> Void) {
        self.dose = dose
        self.medications = medications
        self.model = model
        self.onSaved = onSaved
        _selectedID = State(initialValue: dose.medicationID)
        _takenAt = State(initialValue: dose.takenAt)
    }

    func onDeleted(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.deletedAction = action
        return copy
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                Form {
                    CardSection(Text("Medication"), id: "medication") {
                        ForEach(EditDoseMedications.choices(for: dose, in: medications.medications)) { medication in
                            medicationRow(medication)
                        }
                    }
                    readingSections
                    CardSection(id: "date") {
                        DateSection(date: $takenAt, onOpen: { scrollToDate(proxy) })
                            .id(Self.dateBlockID)
                    }
                }
                .screenSpacing()
                .accessibilityIdentifier("edit-dose-screen")
            }
            .navigationTitle("Edit Dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .frame(minHeight: Spacing.rowMinimumHeight)
                        .contentShape(Rectangle())
                        .accessibilityIdentifier("edit-dose-cancel")
                }
                ToolbarItem(placement: .primaryAction) {
                    DoseMoreMenu { isConfirmingDelete = true }
                }
            }
            .bottomPrimaryButton(Text("Save"), id: "save-dose-changes", action: saveChanges)
            .entryDeleteConfirmation(isPresented: $isConfirmingDelete, words: .dose, onDelete: removeDose)
            .alert("Couldn't save this dose. Try again.", isPresented: $isShowingSaveFailure) {
                Button("OK") {}
            }
        }
        .sensoryFeedback(.success, trigger: readingSaveTicks)
        .sensoryFeedback(.warning, trigger: readingDeleteTicks)
    }

    private func scrollToDate(_ proxy: ScrollViewProxy) {
        Task { @MainActor in
            await Task.yield()
            withAnimation { proxy.scrollTo(Self.dateBlockID, anchor: .bottom) }
        }
    }

    /// The dose keeps its own check-in delay and its readings. Only the medication and the time come from the form.
    private func saveChanges() {
        guard let selectedID else { return }
        let edited = dose.moved(to: selectedID, at: takenAt)
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

    /// Dismisses only after the store removed the dose, and does not call `onSaved`, so no save haptic fires.
    private func removeDose() throws {
        try medications.removeDose(id: dose.id)
        deletedAction()
        dismiss()
    }

    /// A reading that was deleted leaves the dose with no before-reading, which shows as None and opens nothing.
    @ViewBuilder private var readingSections: some View {
        let readings = DoseReadings(dose, in: model.entries)
        CardSection(
            Text("Before this dose"),
            footnote: readings.before.map { _ in Text("The entry used for this dose. Tap to open it.") },
            id: "before-reading"
        ) {
            if let before = readings.before {
                NavigationLink {
                    readingEditor(before)
                } label: {
                    EntryIconRow(entry: before)
                        .spokenAsReading()
                }
                .accessibilityIdentifier("before-reading-row")
            } else {
                Text("None")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("before-reading-row")
            }
        }
        if let after = readings.after {
            CardSection(Text(afterLabel(after)), id: "after-reading") {
                NavigationLink {
                    readingEditor(after)
                } label: {
                    EntryIconRow(entry: after)
                        .spokenAsReading()
                }
                .accessibilityIdentifier("after-reading-row")
            }
        }
    }

    private func readingEditor(_ entry: Entry) -> NewEntryView {
        NewEntryView(model: model, mode: .edit(entry), onSaved: { readingSaveTicks += 1 })
            .onDeleted { readingDeleteTicks += 1 }
    }

    private func afterLabel(_ entry: Entry) -> String {
        let time = ClockText.text(for: entry.date, calendar: .current, locale: .current)
        return String(format: String(localized: "After · checked in at %@"), time)
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
                        .foregroundStyle(.tint)
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
