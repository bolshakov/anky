// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct NewEntryView: View {
    let model: EntryLogModel
    let mode: EntryMode
    let onSaved: () -> Void
    let onAdded: (Entry) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var draft: EntryDraft
    @State private var startDraft: EntryDraft
    @State private var entriesAtOpen: [Entry]
    @State private var lastChipsAtOpen: [PlaceID]
    @State private var hasRecordedChips = false
    @State private var recents: [RecentEntry]
    @State private var isShowingPlaces = false
    // Made once per opening, so a second tap on "Save entry" saves the same entry again.
    @State private var entryID = UUID()
    @State private var isShowingSaveFailure = false
    @State private var hasReportedSave = false

    init(
        model: EntryLogModel,
        mode: EntryMode = .new,
        onSaved: @escaping () -> Void = {},
        onAdded: @escaping (Entry) -> Void = { _ in }
    ) {
        self.model = model
        self.mode = mode
        self.onSaved = onSaved
        self.onAdded = onAdded
        let opening = switch mode {
        case .new: openingDraft(after: model.entries, now: .now)
        case let .edit(entry): EntryDraft(entry: entry)
        }
        _draft = State(initialValue: opening)
        // State, not a fresh call, so a view SwiftUI makes again still compares with the draft it opened with.
        _startDraft = State(initialValue: opening)
        _entriesAtOpen = State(initialValue: model.entries)
        _lastChipsAtOpen = State(initialValue: model.shortcuts.lastChips)
        let recents: [RecentEntry] = switch mode {
        case .new: RecentEntries.distinct(from: model.entries, limit: 3)
        case .edit: []
        }
        _recents = State(initialValue: recents)
    }

    var body: some View {
        NavigationStack {
            Form {
                recentChips
                Section {
                    KindSection(draft: $draft)
                }
                Section {
                    DateSection(date: $draft.date)
                }
                whereSection
                SeveritySection(
                    caption: "Severity",
                    spokenLabel: "Severity",
                    idPrefix: "severity",
                    severity: $draft.severity
                )
                Section {
                    NoteSection(draft: $draft)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }
                if case .edit = mode {
                    Section {
                        DeleteEntrySection(onDelete: removeEntry)
                    }
                }
            }
            .accessibilityIdentifier(screenID)
            .navigationDestination(isPresented: $isShowingPlaces) {
                PlacesListView(draft: $draft)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Group {
                        Button("Cancel") {
                            dismiss()
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                        .accessibilityIdentifier("cancel-entry")
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("cancel-item")
                }
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .accessibilityAddTraits(.isHeader)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    save()
                } label: {
                    Text(saveTitle)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .accessibilityIdentifier("save-entry")
                .padding()
            }
            .alert("This entry could not be saved.", isPresented: $isShowingSaveFailure) {
                Button("OK") {}
            }
            .shortcutFeedback(model.shortcuts)
            .onAppear(perform: recordChipsOnFirstAppear)
            .interactiveDismissDisabled(draft != startDraft)
        }
        .pinLimitAlert(model.shortcuts)
        .environment(model.shortcuts)
        .environment(model.tipProgress)
    }

    private var chips: [PlaceID] {
        PlaceChips.chips(
            from: entriesAtOpen,
            pinned: model.shortcuts.pinned,
            lastChips: lastChipsAtOpen
        )
    }

    private func recordChipsOnFirstAppear() {
        guard !hasRecordedChips else { return }
        hasRecordedChips = true
        model.shortcuts.recordLastChips(chips)
    }

    @ViewBuilder
    private var recentChips: some View {
        if !recents.isEmpty {
            Section {
                RecentChipsRow(recents: recents) { draft.apply($0) }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }
        }
    }

    @ViewBuilder
    private var whereSection: some View {
        if draft.kind.asksWhere {
            Section {
                WhereSection(draft: $draft, isShowingPlaces: $isShowingPlaces, chips: chips)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }
        }
    }

    private var title: LocalizedStringKey {
        switch mode {
        case .new: "New Entry"
        case .edit: "Edit Entry"
        }
    }

    private var saveTitle: LocalizedStringKey {
        switch mode {
        case .new: "Save entry"
        case .edit: "Save changes"
        }
    }

    private var screenID: String {
        switch mode {
        case .new: "new-entry-screen"
        case .edit: "edit-entry-screen"
        }
    }

    private func save() {
        do {
            let saved = try store()
            reportSave(saved)
            dismiss()
        } catch {
            isShowingSaveFailure = true
        }
    }

    private func reportSave(_ saved: Entry) {
        guard !hasReportedSave else { return }
        hasReportedSave = true
        onSaved()
        if case .new = mode {
            onAdded(saved)
        }
    }

    private func store() throws -> Entry {
        switch mode {
        case .new:
            let entry = Entry(id: entryID, draft: draft)
            try model.add(entry)
            return entry
        case let .edit(entry):
            let replaced = Entry(id: entry.id, draft: draft)
            try model.replace(replaced)
            return replaced
        }
    }

    private func removeEntry() throws {
        guard case let .edit(entry) = mode else { return }
        try model.remove(id: entry.id)
        dismiss()
    }
}
