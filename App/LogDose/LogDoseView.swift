// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyMedicationModel
import SwiftUI

struct LogDoseView: View {
    private static let dateBlockID = "date-block"
    let medications: MedicationsModel
    let model: EntryLogModel
    let onSaved: () -> Void
    private let preselected: UUID?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedID: UUID?
    @State private var selectionTicks = 0
    @State private var saveTicks = 0
    @State private var isShowingNewMedication = false
    @State private var newEntry: DoseEntryRequest?
    /// The reading the person picked in Choose an Entry. Nil means the newest in the window.
    @State private var manualReadingID: UUID?
    /// The entry logged for this dose. It stays the reading while it is not after the dose, whatever the window.
    @State private var linkedReadingID: UUID?
    /// Made once per opening, so a second tap on Save logs the same dose again.
    @State private var doseID = UUID()
    /// The time the person set by hand. Nil while unedited, so the dose follows the clock until it is saved.
    @State private var chosenTakenAt: Date?
    @State private var doseSave = DoseSave()
    @State private var isShowingSaveFailure = false
    @State private var checkIn = DoseCheckIn(savedDelay: nil)
    @State private var checkInBuiltFor: UUID?
    /// The clock as of the last minute tick, so the change rule sees the time move while the person has set one.
    @State private var minuteClock = Date.now

    init(
        medications: MedicationsModel,
        model: EntryLogModel,
        preselected: UUID? = nil,
        onSaved: @escaping () -> Void
    ) {
        self.medications = medications
        self.model = model
        self.onSaved = onSaved
        self.preselected = preselected
        _selectedID = State(initialValue: preselected)
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                TimelineView(.everyMinute) { context in
                    Form {
                        CardSection(Text("Medication"), id: "medication") {
                            medicationRow
                        }
                        BeforeThisDoseSection(
                            reading: reading(at: takenAtNow),
                            prompt: .forDose(at: takenAtNow, now: minuteClock),
                            onLog: { newEntry = DoseEntryRequest(doseAt: takenAtNow) },
                            destination: readingChoice
                        )
                        if checkedMedication != nil {
                            DoseCheckInSection(checkIn: $checkIn)
                        }
                        dateSection(scrolling: proxy)
                    }
                    .screenSpacing()
                    .lastBlockClearance()
                    .accessibilityIdentifier("log-dose-screen")
                    .onChange(of: context.date) { minuteClock = context.date }
                }
            }
            .navigationTitle("Log Dose")
            .navigationBarTitleDisplayMode(.inline)
            .discardConfirmation(hasChanges: hasChanges, cancelID: "log-dose-cancel", close: { dismiss() })
            .toolbar {
                if !medications.medications.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        NavigationLink {
                            MedicationsView(medications: medications)
                        } label: {
                            Label("Manage", systemImage: "pills")
                        }
                        .minimumTapTarget()
                        .accessibilityIdentifier("log-dose-manage")
                    }
                    ToolbarSpacer(.fixed, placement: .primaryAction)
                }
                ToolbarItem(placement: .principal) {
                    Text("Log Dose")
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .accessibilityAddTraits(.isHeader)
                }
            }
            .saveToolbarItem(id: "save-dose", isEnabled: checkedID != nil, action: saveDose)
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
            .doseEntrySheet($newEntry, model: model, onSaved: { saveTicks += 1 }, onAdded: readingAdded)
            .sensoryFeedback(.selection, trigger: selectionTicks)
            .sensoryFeedback(.success, trigger: saveTicks)
            .onAppear { medications.reload() }
        }
    }

    private var active: [Medication] {
        medications.active
    }

    private var hasChanges: Bool {
        LogDoseDraft(
            selectedID: selectedID,
            takenAt: chosenTakenAt,
            manualReadingID: manualReadingID,
            linkedReadingID: linkedReadingID,
            checkIn: checkIn
        )
        .hasChanges(in: LogDoseContext(
            preselected: preselected, active: active, entries: model.entries, now: minuteClock
        ))
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
            DateSection(date: dateBinding, showsChevron: false, onOpen: { scrollToDate(proxy) })
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
        ReadingLink.resolve(linked: linkedReadingID, manual: manualReadingID, in: model.entries, at: time)
    }

    private func readingChoice() -> some View {
        ReadingChoiceView(
            entries: model.entries,
            model: model,
            chosenID: reading(at: takenAtNow)?.id,
            doseAt: takenAtNow,
            onPick: readingPicked,
            onAdded: readingAdded,
            onSaved: { saveTicks += 1 }
        )
    }

    private func readingPicked(_ picked: Entry) {
        manualReadingID = picked.id
        linkedReadingID = nil
    }

    private func readingAdded(_ saved: Entry) {
        linkedReadingID = saved.id
        manualReadingID = nil
    }

    @ViewBuilder private var medicationRow: some View {
        if let checkedMedication {
            NavigationLink {
                SelectMedicationView(
                    medications: medications,
                    choices: active,
                    selectedID: checkedID,
                    onSelect: select,
                    onAdded: medicationSaved
                )
            } label: {
                ValueRow(Text("Medication"), value: Text(verbatim: checkedMedication.listTitle))
            }
            .fillsCardRow()
            .accessibilityIdentifier("dose-medication-field")
        } else {
            Text("No medications yet")
                .accessibilityIdentifier("dose-no-medications")
            Button("Add medication") {
                isShowingNewMedication = true
            }
            .accessibilityIdentifier("dose-add-medication")
        }
    }

    private func saveDose() {
        guard let medication = checkedMedication else { return }
        var dose = Dose.logged(
            id: doseID,
            medication: medication,
            takenAt: takenAtNow,
            entries: model.entries,
            manualReadingID: manualReadingID,
            linkedReadingID: linkedReadingID,
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
