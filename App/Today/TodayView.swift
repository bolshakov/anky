// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyMedicationModel
import SwiftUI
import UIKit

private extension View {
    func bareRow() -> some View {
        listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}

struct TodayView: View {
    let model: EntryLogModel
    let medications: MedicationsModel
    @Binding var reminderCheckIn: Dose?
    @State private var isShowingNewEntry = false
    @State private var isShowingLogDose = false
    @State private var editing: Entry?
    @State private var editingDose: Dose?
    @State private var loggedID: UUID?
    @State private var isShowingSaveFailure = false
    @State private var logTicks = 0
    @State private var undoTicks = 0
    @State private var saveTicks = 0
    @State private var checkingIn: Dose?
    @State private var checkInNow = Date.now
    @State private var pendingDelete: Entry?
    @State private var pendingDoseDelete: Dose?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var pairLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 12))
            : AnyLayout(HStackLayout(spacing: 12))
    }

    private var todayItems: [LoggedItem] {
        TodayList.items(entries: model.entries, doses: medications.doses, on: .now, calendar: .current)
    }

    private var waitingDoses: [Dose] {
        CheckInDue.waiting(
            doses: medications.doses,
            medications: medications.medications,
            entries: model.entries,
            now: checkInNow
        )
    }

    private var nextCheckInDue: Date? {
        CheckInDue.nextDue(
            doses: medications.doses,
            medications: medications.medications,
            entries: model.entries,
            after: checkInNow
        )
    }

    private var recent: RecentEntry? {
        RecentEntries.distinct(from: model.entries, limit: 1).first
    }

    private var loggedEntry: Entry? {
        model.entries.first { $0.id == loggedID }
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
        // Captured here, so the alert's button deletes the item it was asked about even after the binding clears.
        let target = pendingDelete
        let doseTarget = pendingDoseDelete
        NavigationStack {
            List {
                Section {
                    dateLine
                    repeatBlock
                }
                checkInBlock
                entriesOrEmptyState
            }
            .listStyle(.insetGrouped)
            .entryDeleteConfirmation(isPresented: isConfirmingDelete) {
                guard let target else { return }
                try model.remove(id: target.id)
            }
            .entryDeleteConfirmation(isPresented: isConfirmingDoseDelete, words: .dose) {
                guard let doseTarget else { return }
                try medications.removeDose(id: doseTarget.id)
            }
            .checkInClock(now: $checkInNow, nextDue: nextCheckInDue)
            .onChange(of: reminderCheckIn, initial: true) { _, dose in
                guard let dose else { return }
                reminderCheckIn = nil
                showCheckIn(dose)
            }
            .onDisappear { loggedID = nil }
            .accessibilityIdentifier("today-screen")
            .navigationTitle("Today")
            .safeAreaInset(edge: .bottom) {
                pairLayout {
                    Button {
                        isShowingLogDose = true
                    } label: {
                        Text("Log medication")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.capsule)
                    .accessibilityIdentifier("log-medication")
                    Button {
                        isShowingNewEntry = true
                    } label: {
                        Text("Log how you feel")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .primaryButton()
                    .accessibilityIdentifier("log-entry")
                }
                .controlSize(.large)
                .fixedSize(horizontal: false, vertical: true)
                .padding()
            }
            .sheet(isPresented: $isShowingNewEntry) {
                NewEntryView(model: model, onSaved: { saveTicks += 1 })
            }
            .sheet(isPresented: $isShowingLogDose) {
                LogDoseView(medications: medications, model: model, onSaved: { saveTicks += 1 })
            }
            .sheet(item: $editing) { entry in
                NewEntryView(model: model, mode: .edit(entry), onSaved: { saveTicks += 1 })
            }
            .sheet(item: $editingDose) { dose in
                EditDoseView(dose: dose, medications: medications, model: model, onSaved: { saveTicks += 1 })
            }
            .sheet(item: $checkingIn) { dose in
                CheckInView(dose: dose, medications: medications, model: model, onSaved: { saveTicks += 1 })
            }
            .alert("This entry could not be saved.", isPresented: $isShowingSaveFailure) {
                Button("OK") {}
            }
            .sensoryFeedback(.success, trigger: logTicks)
            .sensoryFeedback(.selection, trigger: undoTicks)
            .sensoryFeedback(.success, trigger: saveTicks)
        }
    }

    private var dateLine: some View {
        Text(verbatim: DayDateText.text(
            for: .now,
            includesYear: false,
            calendar: .current,
            locale: .current
        ))
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .accessibilityIdentifier("today-date")
        .bareRow()
    }

    @ViewBuilder
    private var entriesOrEmptyState: some View {
        if todayItems.isEmpty {
            Section {
                EmptyTodayView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, recent == nil ? 48 : 64)
                    .padding(.bottom, 48)
                    .bareRow()
            }
        } else {
            TodayEntryList(
                items: todayItems,
                medications: medications.medications,
                entries: model.entries,
                onSelect: open,
                onSelectDose: { editingDose = $0 },
                onDelete: { pendingDelete = $0 },
                onDeleteDose: { pendingDoseDelete = $0 }
            )
        }
    }

    @ViewBuilder
    private var repeatBlock: some View {
        if let loggedEntry {
            RepeatLoggedCard(recent: RecentEntry(loggedEntry), onUndo: undoLogged)
                .padding(.top, 16)
                .bareRow()
        } else if let recent {
            RepeatChip(recent: recent) { logRecent(recent) }
                .padding(.top, 16)
                .bareRow()
        }
    }

    @ViewBuilder
    private var checkInBlock: some View {
        if !waitingDoses.isEmpty {
            CheckInSection(
                doses: waitingDoses,
                medications: medications.medications,
                entries: model.entries,
                now: checkInNow,
                onSelect: { checkingIn = $0 }
            )
        }
    }

    private func showCheckIn(_ dose: Dose) {
        isShowingNewEntry = false
        isShowingLogDose = false
        editing = nil
        editingDose = nil
        checkingIn = dose
    }

    private func open(_ entry: Entry) {
        if entry.id == loggedID {
            loggedID = nil
        }
        editing = entry
    }

    private func logRecent(_ recent: RecentEntry) {
        guard loggedEntry == nil else { return }
        let entry = Entry(draft: recent.draft(at: .now))
        do {
            try model.add(entry)
            loggedID = entry.id
            logTicks += 1
            UIAccessibility.post(notification: .announcement, argument: String(localized: "Logged"))
        } catch {
            isShowingSaveFailure = true
        }
    }

    private func undoLogged() {
        guard let loggedID else { return }
        do {
            try model.remove(id: loggedID)
            self.loggedID = nil
            undoTicks += 1
            UIAccessibility.post(notification: .announcement, argument: String(localized: "Entry removed"))
        } catch {
            isShowingSaveFailure = true
        }
    }
}
