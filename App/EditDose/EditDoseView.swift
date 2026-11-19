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
    private let savedReadingID: UUID?
    private(set) var deletedAction: () -> Void = {}
    @Environment(\.dismiss) private var dismiss
    @State private var selectedID: UUID?
    @State private var takenAt: Date
    /// What the before row points at. A time moved before an entry shows None, and a time moved back shows the entry
    /// again.
    @State private var before: EditDoseBefore
    @State private var isAfterRemoved = false
    @State private var newEntry: DoseEntryRequest?
    @State private var doseSave = DoseSave()
    @State private var isShowingSaveFailure = false
    @State private var isConfirmingDelete = false
    @State private var readingSaveTicks = 0
    @State private var readingDeleteTicks = 0
    @State private var selectionTicks = 0
    @State private var addedTicks = 0

    init(dose: Dose, medications: MedicationsModel, model: EntryLogModel, onSaved: @escaping () -> Void) {
        self.dose = dose
        self.medications = medications
        self.model = model
        self.onSaved = onSaved
        _selectedID = State(initialValue: dose.medicationID)
        _takenAt = State(initialValue: dose.takenAt)
        savedReadingID = ReadingLink.kept(
            DoseReadings(dose, in: model.entries).before?.id, in: model.entries, at: dose.takenAt
        )
        _before = State(initialValue: .opening(
            savedLink: dose.beforeReadingID, in: model.entries, at: dose.takenAt
        ))
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
                        MedicationChoiceRows(
                            medications: medications,
                            choices: EditDoseMedications.choices(for: dose, in: medications.medications),
                            selectedID: selectedID,
                            onSelect: select,
                            onAdded: medicationAdded
                        )
                    }
                    readingSections
                    CardSection(id: "date") {
                        DateSection(date: $takenAt, onOpen: { scrollToDate(proxy) })
                            .id(Self.dateBlockID)
                    }
                }
                .screenSpacing()
                .lastBlockClearance()
                .accessibilityIdentifier("edit-dose-screen")
            }
            .discardConfirmation(hasChanges: hasChanges, cancelID: "edit-dose-cancel", close: { dismiss() })
            .navigationTitle("Edit Dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Delete dose", systemImage: "trash", role: .destructive) {
                        isConfirmingDelete = true
                    }
                    .tint(Color.destructive)
                    .accessibilityIdentifier("delete-dose")
                }
                ToolbarSpacer(.fixed, placement: .primaryAction)
            }
            .saveToolbarItem(id: "save-dose-changes", action: saveChanges)
            .doseEntrySheet(
                $newEntry,
                model: model,
                onSaved: { readingSaveTicks += 1 },
                onAdded: { before = .entry($0.id) }
            )
            .entryDeleteConfirmation(isPresented: $isConfirmingDelete, words: .dose, onDelete: removeDose)
            .alert("Couldn't save this dose. Try again.", isPresented: $isShowingSaveFailure) {
                Button("OK") {}
            }
        }
        .sensoryFeedback(.selection, trigger: selectionTicks)
        .sensoryFeedback(.success, trigger: readingSaveTicks)
        .sensoryFeedback(.success, trigger: addedTicks)
        .sensoryFeedback(.warning, trigger: readingDeleteTicks)
    }

    private var hasChanges: Bool {
        guard let selectedID else { return false }
        return dose.moved(to: dose.medicationID, at: dose.takenAt, beforeReadingID: savedReadingID)
            .isMoved(
                to: selectedID, at: takenAt, beforeReadingID: resolvedReadingID, afterReadingID: keptAfterReadingID
            )
    }

    private var keptAfterReadingID: UUID? {
        isAfterRemoved ? nil : dose.afterReadingID
    }

    private var resolvedReadingID: UUID? {
        before.linkedID(in: model.entries, at: takenAt)
    }

    private func scrollToDate(_ proxy: ScrollViewProxy) {
        Task { @MainActor in
            await Task.yield()
            withAnimation { proxy.scrollTo(Self.dateBlockID, anchor: .bottom) }
        }
    }

    /// The dose keeps its own check-in delay. The medication, the time and both readings come from the form.
    private func saveChanges() {
        guard let selectedID else { return }
        let edited = dose.moved(
            to: selectedID, at: takenAt, beforeReadingID: resolvedReadingID, afterReadingID: keptAfterReadingID
        )
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

    /// A reading that was deleted leaves the dose with no before-reading, which shows as None and still opens the
    /// choice of an entry. A dose saved with no link and no entry in its window shows the row that logs one.
    @ViewBuilder private var readingSections: some View {
        let readings = DoseReadings(dose, in: model.entries)
        BeforeThisDoseSection(
            reading: model.entries.first { $0.id == resolvedReadingID },
            isNone: before.isNone(in: model.entries, at: takenAt),
            prompt: before == .prompt ? .forDose(at: takenAt, now: .now) : nil,
            onLog: { newEntry = DoseEntryRequest(doseAt: takenAt) },
            onRemove: { before = .none },
            destination: readingChoice
        )
        if let after = readings.after, !isAfterRemoved {
            CardSection(Text(afterLabel(after)), id: "after-reading") {
                NavigationLink {
                    readingEditor(after)
                } label: {
                    EntryIconRow(entry: after)
                        .spokenAsReading()
                }
                .accessibilityIdentifier("after-reading-row")
                .removeSwipe(id: "after-reading-remove") { isAfterRemoved = true }
            }
        }
    }

    private func readingChoice() -> some View {
        ReadingChoiceView(
            entries: model.entries,
            model: model,
            chosenID: resolvedReadingID,
            doseAt: takenAt,
            isNoneChosen: before.isNone(in: model.entries, at: takenAt),
            onPickNone: { before = .none },
            onPick: { before = .entry($0.id) },
            onAdded: { before = .entry($0.id) },
            onSaved: { readingSaveTicks += 1 }
        )
    }

    private func readingEditor(_ entry: Entry) -> NewEntryView {
        NewEntryView(model: model, mode: .edit(entry), onSaved: { readingSaveTicks += 1 })
            .onDeleted { readingDeleteTicks += 1 }
    }

    private func afterLabel(_ entry: Entry) -> String {
        let time = ClockText.text(for: entry.date, calendar: .current, locale: .current)
        return String(format: String(localized: "After · checked in at %@"), time)
    }

    private func select(_ medication: Medication) {
        guard medication.id != selectedID else { return }
        selectedID = medication.id
        selectionTicks += 1
    }

    /// The medication the form just wrote becomes the chosen row. Choosing it does not tick, because the success
    /// haptic plays instead.
    private func medicationAdded(_ id: Medication.ID) {
        selectedID = id
        addedTicks += 1
    }
}
