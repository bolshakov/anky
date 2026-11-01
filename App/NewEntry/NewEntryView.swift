// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct NewEntryView: View {
    let model: EntryLogModel
    let mode: EntryMode
    let onSaved: () -> Void
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

    init(model: EntryLogModel, mode: EntryMode = .new, onSaved: @escaping () -> Void = {}) {
        self.model = model
        self.mode = mode
        self.onSaved = onSaved
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
            ScrollView {
                VStack(spacing: 24) {
                    recentChips
                    KindSection(draft: $draft)
                    DateSection(draft: $draft)
                    whereSection
                    SeveritySection(draft: $draft)
                    NoteSection(draft: $draft)
                    if case .edit = mode {
                        DeleteEntrySection(onDelete: removeEntry)
                    }
                }
                .padding()
            }
            .background(Color("PageBackground"))
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
                Button(saveTitle) {
                    save()
                }
                .buttonStyle(PinnedButtonStyle())
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
            RecentChipsRow(recents: recents) { draft.apply($0) }
        }
    }

    @ViewBuilder
    private var whereSection: some View {
        if draft.kind.asksWhere {
            WhereSection(draft: $draft, isShowingPlaces: $isShowingPlaces, chips: chips)
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
            try store()
            if !hasReportedSave {
                hasReportedSave = true
                onSaved()
            }
            dismiss()
        } catch {
            isShowingSaveFailure = true
        }
    }

    private func store() throws {
        switch mode {
        case .new: try model.add(Entry(id: entryID, draft: draft))
        case let .edit(entry): try model.replace(Entry(id: entry.id, draft: draft))
        }
    }

    private func removeEntry() throws {
        guard case let .edit(entry) = mode else { return }
        try model.remove(id: entry.id)
        dismiss()
    }
}
