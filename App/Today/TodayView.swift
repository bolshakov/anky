// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import AnkyMedicationModel
import SwiftUI
import UIKit

struct TodayView: View {
    let model: EntryLogModel
    let medications: MedicationsModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isShowingNewEntry = false
    @State private var isShowingLogDose = false
    @State private var editing: Entry?
    @State private var loggedID: UUID?
    @State private var isShowingSaveFailure = false
    @State private var logTicks = 0
    @State private var undoTicks = 0
    @State private var saveTicks = 0

    private var todayItems: [LoggedItem] {
        TodayList.items(entries: model.entries, doses: medications.doses, on: .now, calendar: .current)
    }

    private var recent: RecentEntry? {
        RecentEntries.distinct(from: model.entries, limit: 1).first
    }

    private var loggedEntry: Entry? {
        model.entries.first { $0.id == loggedID }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: DayDateText.text(
                        for: .now,
                        includesYear: false,
                        calendar: .current,
                        locale: .current
                    ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("today-date")

                    repeatBlock

                    if todayItems.isEmpty {
                        EmptyTodayView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, recent == nil ? 48 : 64)
                            .padding(.bottom, 48)
                    } else {
                        TodayEntryList(items: todayItems, medications: medications.medications, onSelect: open)
                            .padding(.top, 16)
                    }

                    if dynamicTypeSize.isAccessibilitySize {
                        logMedicationButton
                    }
                }
                .padding(.horizontal)
            }
            .onDisappear { loggedID = nil }
            .background(Color("PageBackground"))
            .accessibilityIdentifier("today-screen")
            .navigationTitle("Today")
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    if !dynamicTypeSize.isAccessibilitySize {
                        logMedicationButton
                            .padding(.horizontal)
                    }
                    Button {
                        isShowingNewEntry = true
                    } label: {
                        Text("Log how you feel")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .accessibilityIdentifier("log-entry")
                    .padding()
                }
            }
            .sheet(isPresented: $isShowingNewEntry) {
                NewEntryView(model: model, onSaved: { saveTicks += 1 })
            }
            .sheet(isPresented: $isShowingLogDose) {
                LogDoseView(medications: medications, onSaved: { saveTicks += 1 })
            }
            .sheet(item: $editing) { entry in
                NewEntryView(model: model, mode: .edit(entry), onSaved: { saveTicks += 1 })
            }
            .alert("This entry could not be saved.", isPresented: $isShowingSaveFailure) {
                Button("OK") {}
            }
            .sensoryFeedback(.success, trigger: logTicks)
            .sensoryFeedback(.selection, trigger: undoTicks)
            .sensoryFeedback(.success, trigger: saveTicks)
        }
    }

    private var logMedicationButton: some View {
        Button("Log medication") {
            isShowingLogDose = true
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .accessibilityIdentifier("log-medication")
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var repeatBlock: some View {
        if let loggedEntry {
            RepeatLoggedCard(recent: RecentEntry(loggedEntry), onUndo: undoLogged)
                .padding(.top, 16)
        } else if let recent {
            RepeatChip(recent: recent) { logRecent(recent) }
                .padding(.top, 16)
        }
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
