// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyMedicationModel
import SwiftUI
import UIKit

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
    @State private var deleteTicks = 0
    @State private var checkingIn: Dose?
    @State private var checkInNow = Date.now
    @State private var pendingDelete: Entry?
    @State private var pendingDoseDelete: Dose?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var pairLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: Spacing.pairGap))
            : AnyLayout(HStackLayout(spacing: Spacing.pairGap))
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

    private var nextCheckInChange: Date? {
        CheckInDue.nextChange(
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
                    cornerGuard
                    VStack(alignment: .leading, spacing: Spacing.firstBlockTop) {
                        dateLine
                        repeatBlock
                    }
                    .nonCardBlock()
                    cornerGuard
                }
                entriesOrEmptyState
            }
            .listStyle(.insetGrouped)
            .environment(\.defaultMinListRowHeight, 0)
            .blockGapBetweenSections()
            .todayTopMargin()
            .entryDeleteConfirmation(isPresented: isConfirmingDelete) {
                guard let target else { return }
                try model.remove(id: target.id)
                deleteTicks += 1
            }
            .entryDeleteConfirmation(isPresented: isConfirmingDoseDelete, words: .dose) {
                guard let doseTarget else { return }
                try medications.removeDose(id: doseTarget.id)
                deleteTicks += 1
            }
            .checkInClock(now: $checkInNow, nextChange: nextCheckInChange)
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
                        Text("Log dose")
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
                    .onDeleted { deleteTicks += 1 }
            }
            .sheet(item: $editingDose) { dose in
                EditDoseView(dose: dose, medications: medications, model: model, onSaved: { saveTicks += 1 })
                    .onDeleted { deleteTicks += 1 }
            }
            .sheet(item: $checkingIn) { dose in
                CheckInView(dose: dose, medications: medications, model: model, onSaved: { saveTicks += 1 })
            }
            .alert("Couldn't save this entry. Try again.", isPresented: $isShowingSaveFailure) {
                Button("OK") {}
            }
            .sensoryFeedback(.success, trigger: logTicks)
            .sensoryFeedback(.selection, trigger: undoTicks)
            .sensoryFeedback(.success, trigger: saveTicks)
            .sensoryFeedback(.warning, trigger: deleteTicks)
        }
    }

    /// The grouped list rounds and clips the outer corners of its first and last row, which would cut the date and
    /// the chip. A zero-height row takes each of those corners.
    private var cornerGuard: some View {
        Color.clear
            .frame(height: 0)
            .accessibilityHidden(true)
            .nonCardBlock()
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
    }

    @ViewBuilder
    private var entriesOrEmptyState: some View {
        if todayItems.isEmpty {
            Section {
                EmptyTodayView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, recent == nil ? Spacing.emptyTodayTop : Spacing.emptyTodayTopBelowChip)
                    .padding(.bottom, Spacing.emptyTodayBottom)
                    .nonCardBlock()
            }
        } else {
            TodayEntryList(
                items: todayItems,
                medications: medications.medications,
                entries: model.entries,
                waiting: Set(waitingDoses.map(\.id)),
                onSelect: open,
                onSelectDose: openDose,
                onDelete: { pendingDelete = $0 },
                onDeleteDose: { pendingDoseDelete = $0 }
            )
        }
    }

    @ViewBuilder
    private var repeatBlock: some View {
        if let loggedEntry {
            RepeatLoggedCard(recent: RecentEntry(loggedEntry), onUndo: undoLogged)
        } else if let recent {
            RepeatChip(recent: recent) { logRecent(recent) }
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

    private func openDose(_ dose: Dose) {
        if waitingDoses.contains(where: { $0.id == dose.id }) {
            checkingIn = dose
        } else {
            editingDose = dose
        }
    }

    private func logRecent(_ recent: RecentEntry) {
        guard loggedEntry == nil else { return }
        let entry = Entry(draft: recent.draft(at: .now))
        do {
            try model.add(entry)
            loggedID = entry.id
            logTicks += 1
            AccessibilityNotification.Announcement(RepeatLoggedCard.spokenText(for: RecentEntry(entry))).post()
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
            UIAccessibility.post(notification: .announcement, argument: String(localized: "Entry deleted"))
        } catch {
            isShowingSaveFailure = true
        }
    }
}
