// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyMedicationModel
import SwiftUI

struct LogDoseView: View {
    private static let dateBlockID = "date-block"
    let medications: MedicationsModel
    let model: EntryLogModel
    let onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedID: UUID?
    @State private var selectionTicks = 0
    @State private var saveTicks = 0
    @State private var isShowingNewMedication = false
    @State private var isShowingNewEntry = false
    @State private var isShowingReadingChoice = false
    /// The reading the person picked, or the one a new entry became. Nil means the newest in the window.
    @State private var manualReadingID: UUID?
    /// Made once per opening, so a second tap on Save logs the same dose again.
    @State private var doseID = UUID()
    /// The time the person set by hand. Nil while unedited, so the dose follows the clock until it is saved.
    @State private var chosenTakenAt: Date?
    @State private var doseSave = DoseSave()
    @State private var isShowingSaveFailure = false
    @State private var checkIn = DoseCheckIn(savedDelay: nil)
    @State private var checkInBuiltFor: UUID?

    init(
        medications: MedicationsModel,
        model: EntryLogModel,
        preselected: UUID? = nil,
        onSaved: @escaping () -> Void
    ) {
        self.medications = medications
        self.model = model
        self.onSaved = onSaved
        _selectedID = State(initialValue: preselected)
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                TimelineView(.everyMinute) { _ in
                    Form {
                        CardSection(Text("Medication"), id: "medication") {
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
                        BeforeThisDoseSection(
                            reading: { reading(at: takenAtNow) },
                            onChoose: { isShowingReadingChoice = true },
                            onLog: { isShowingNewEntry = true }
                        )
                        if checkedMedication != nil {
                            DoseCheckInSection(checkIn: $checkIn)
                        }
                        dateSection(scrolling: proxy)
                    }
                    .screenSpacing()
                }
            }
            .navigationTitle("Log Dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .frame(minHeight: Spacing.rowMinimumHeight)
                        .contentShape(Rectangle())
                        .accessibilityIdentifier("log-dose-cancel")
                }
                if !medications.medications.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink("Manage") {
                            MedicationsView(medications: medications)
                        }
                        .minimumTapTarget()
                        .accessibilityIdentifier("log-dose-manage")
                    }
                }
            }
            .bottomPrimaryButton(Text("Save"), id: "save-dose", isEnabled: checkedID != nil, action: saveDose)
            .alert("Couldn't save this dose. Try again.", isPresented: $isShowingSaveFailure) {
                Button("OK") {}
            }
            .onChange(of: active) {
                selectedID = MedicationSelection.kept(selectedID, in: active)
            }
            .onChange(of: checkedID, initial: true) {
                guard checkedID != checkInBuiltFor else { return }
                checkInBuiltFor = checkedID
                checkIn = DoseCheckIn(savedDelay: checkedMedication?.checkInAfter)
            }
            .onChange(of: checkedMedication?.checkInAfter) { old, new in
                checkIn = checkIn.following(savedDelay: new, from: old)
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
            .sheet(isPresented: $isShowingReadingChoice) {
                ReadingChoiceView(
                    entries: ReadingWindow.entries(in: model.entries, before: takenAtNow),
                    model: model,
                    chosenID: reading(at: takenAtNow)?.id,
                    onPick: { manualReadingID = $0.id },
                    onAdded: readingAdded,
                    onSaved: { saveTicks += 1 }
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

    private var checkedMedication: Medication? {
        active.first { $0.id == checkedID }
    }

    /// The dose time as the clock has it now while the person has not set one.
    private var takenAtNow: Date {
        chosenTakenAt ?? .now
    }

    /// The date row redraws each minute while unedited, so the time it shows is the clock's.
    private func dateSection(scrolling proxy: ScrollViewProxy) -> some View {
        CardSection(id: "date") {
            DateSection(date: dateBinding, onOpen: { scrollToDate(proxy) })
                .fillsCardRow()
                .id(Self.dateBlockID)
        }
    }

    private func scrollToDate(_ proxy: ScrollViewProxy) {
        Task { @MainActor in
            await Task.yield()
            withAnimation { proxy.scrollTo(Self.dateBlockID, anchor: .bottom) }
        }
    }

    private var dateBinding: Binding<Date> {
        Binding(
            get: { takenAtNow },
            set: { chosenTakenAt = $0 }
        )
    }

    private func reading(at time: Date) -> Entry? {
        ReadingWindow.pick(manualReadingID, in: model.entries, before: time)
    }

    private func readingAdded(_ saved: Entry) {
        manualReadingID = saved.id
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
                        .foregroundStyle(Color.tint)
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
        guard let medication = checkedMedication else { return }
        var dose = Dose.logged(
            id: doseID,
            medication: medication,
            takenAt: takenAtNow,
            entries: model.entries,
            manualReadingID: manualReadingID,
            loggedAt: .now
        )
        dose.checkInAfter = checkIn.checkInAfter
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

    /// The medication the form just wrote becomes the chosen row, wherever it sorts in the active list. Choosing it
    /// does not tick, because the success haptic plays instead.
    private func medicationSaved(_ id: Medication.ID) {
        selectedID = id
        saveTicks += 1
    }
}
