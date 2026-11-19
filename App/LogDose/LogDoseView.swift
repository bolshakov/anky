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
    @State private var draft: LogDoseDraft
    @State private var selectionTicks = 0
    @State private var saveTicks = 0
    @State private var newEntry: DoseEntryRequest?
    /// Made once per opening, so a second tap on Save logs the same dose again.
    @State private var doseID = UUID()
    @State private var doseSave = DoseSave()
    @State private var isShowingSaveFailure = false
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
        _draft = State(initialValue: .untouched(preselected: preselected, active: medications.active))
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                TimelineView(.everyMinute) { context in
                    Form {
                        CardSection(Text("Medication"), id: "medication") {
                            MedicationChoiceRows(
                                medications: medications,
                                choices: active,
                                selectedID: checkedID,
                                onSelect: select,
                                onAdded: medicationSaved
                            )
                        }
                        BeforeThisDoseSection(
                            reading: reading(at: takenAtNow),
                            isNone: draft.noReading,
                            prompt: .forDose(at: takenAtNow, now: minuteClock),
                            onLog: { newEntry = DoseEntryRequest(doseAt: takenAtNow) },
                            onRemove: removal,
                            destination: readingChoice
                        )
                        if checkedMedication != nil {
                            DoseCheckInSection(checkIn: $draft.checkIn)
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
                        .accessibilityLabel("Manage medications, spoken label")
                        .accessibilityIdentifier("log-dose-manage")
                    }
                    ToolbarSpacer(.fixed, placement: .primaryAction)
                }
                ToolbarItem(placement: .principal) {
                    Text("Log Dose")
                        .font(.headline)
                        .dynamicTypeSize(...DynamicTypeSize.large)
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
                draft.selectedID = MedicationSelection.kept(draft.selectedID, in: active)
            }
            .onChange(of: checkedID) {
                draft = draft.changingMedication(to: draft.selectedID, in: formContext)
            }
            .onChange(of: checkedID, initial: true) {
                guard checkedID != checkInBuiltFor else { return }
                checkInBuiltFor = checkedID
                draft.checkIn = DoseCheckIn(savedDelay: checkedMedication?.checkInAfter)
            }
            .onChange(of: checkedMedication?.checkInAfter) { old, new in
                draft.checkIn = draft.checkIn.following(savedDelay: new, from: old)
            }
            .doseEntrySheet($newEntry, model: model, onSaved: { saveTicks += 1 }, onAdded: readingAdded)
            .sensoryFeedback(.selection, trigger: selectionTicks)
            .sensoryFeedback(.success, trigger: saveTicks)
            .onAppear { medications.reload() }
        }
    }

    private var removal: (() -> Void)? {
        guard reading(at: takenAtNow) != nil else { return nil }
        return { pickNone() }
    }

    private var active: [Medication] {
        medications.active
    }

    private var hasChanges: Bool {
        draft.hasChanges(in: formContext)
    }

    private var formContext: LogDoseContext {
        LogDoseContext(preselected: preselected, active: active, entries: model.entries, now: minuteClock)
    }

    private var checkedID: UUID? {
        MedicationSelection.kept(draft.selectedID, in: active)
    }

    private var checkedMedication: Medication? {
        active.first { $0.id == checkedID }
    }

    /// The dose time as the clock has it now while the person has not set one.
    private var takenAtNow: Date {
        draft.takenAt ?? .now
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
            set: { draft = draft.movingTime(to: $0, in: formContext) }
        )
    }

    private func reading(at time: Date) -> Entry? {
        ReadingLink.resolve(
            linked: draft.linkedReadingID,
            manual: draft.manualReadingID,
            noReading: draft.noReading,
            in: model.entries,
            at: time
        )
    }

    private func readingChoice() -> some View {
        ReadingChoiceView(
            entries: model.entries,
            model: model,
            chosenID: reading(at: takenAtNow)?.id,
            doseAt: takenAtNow,
            isNoneChosen: draft.noReading,
            onPickNone: pickNone,
            onPick: readingPicked,
            onAdded: readingAdded,
            onSaved: { saveTicks += 1 }
        )
    }

    private func readingPicked(_ picked: Entry) {
        draft = draft.picking(picked.id)
    }

    private func readingAdded(_ saved: Entry) {
        draft.linkedReadingID = saved.id
        draft.manualReadingID = nil
        draft.noReading = false
        draft.readingTouched = true
    }

    private func pickNone() {
        draft.noReading = true
        draft.readingTouched = true
    }

    private func saveDose() {
        guard let medication = checkedMedication else { return }
        var dose = Dose.logged(
            id: doseID,
            medication: medication,
            takenAt: takenAtNow,
            entries: model.entries,
            manualReadingID: draft.manualReadingID,
            linkedReadingID: draft.linkedReadingID,
            noReading: draft.noReading,
            loggedAt: .now
        )
        dose.checkInAfter = draft.checkIn.checkInAfter
        let memory = ReadingMemory.toRemember(noReading: draft.noReading, resolved: reading(at: takenAtNow))
        do {
            let logged = try doseSave.save(dose) { try medications.logDose($0, remembering: memory) }
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
        draft.selectedID = medication.id
        selectionTicks += 1
    }

    /// The medication the form just wrote becomes the chosen row, wherever it sorts in the active list. Choosing it
    /// does not tick, because the success haptic plays instead.
    private func medicationSaved(_ id: Medication.ID) {
        draft.selectedID = id
        saveTicks += 1
    }
}
