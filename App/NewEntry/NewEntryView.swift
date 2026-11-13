// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct NewEntryView: View {
    private static let dateBlockID = "date-block"

    let model: EntryLogModel
    let mode: EntryMode
    let onSaved: () -> Void
    private(set) var deletedAction: () -> Void = {}
    let onAdded: (Entry) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var draft: EntryDraft
    @State private var startDraft: EntryDraft
    @State private var entriesAtOpen: [Entry]
    @State private var lastChipsAtOpen: [PlaceID]
    @State private var hasRecordedChips = false
    @State private var recents: [EntryKind: [RecentEntry]]
    @State private var isShowingPlaces = false
    // Made once per opening, so a second tap on Save saves the same entry again.
    @State private var entryID = UUID()
    @State private var isShowingSaveFailure = false
    @State private var isConfirmingDelete = false
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
        let recents: [EntryKind: [RecentEntry]] = switch mode {
        case .new: Dictionary(uniqueKeysWithValues: EntryKind.allCases.map {
                ($0, RecentEntries.distinct(from: model.entries, kind: $0, limit: 3))
            })
        case .edit: [:]
        }
        _recents = State(initialValue: recents)
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
                    recentChips
                    Section {
                        KindSection(draft: $draft)
                            .nonCardBlock()
                    }
                    SystemSeveritySection(
                        caption: "Severity",
                        spokenLabel: "Severity",
                        idPrefix: "severity",
                        severity: $draft.severity
                    )
                    whereSection
                    CardSection(id: "date") {
                        DateSection(date: $draft.date, onOpen: { scrollToDate(proxy) })
                            .id(Self.dateBlockID)
                    }
                    NoteSection(draft: $draft)
                }
                .screenSpacing()
                .accessibilityIdentifier(screenID)
            }
            .navigationDestination(isPresented: $isShowingPlaces) {
                PlacesListView(draft: $draft)
            }
            .discardConfirmation(
                hasChanges: draft.hasChanges(since: startDraft),
                cancelID: "cancel-entry",
                close: { dismiss() }
            )
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if case .edit = mode {
                    ToolbarItem(placement: .primaryAction) {
                        EntryMoreMenu { isConfirmingDelete = true }
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .accessibilityAddTraits(.isHeader)
                }
            }
            .safeAreaInset(edge: .bottom) { saveButton }
            .alert("Couldn't save this entry. Try again.", isPresented: $isShowingSaveFailure) {
                Button("OK") {}
            }
            .entryDeleteConfirmation(isPresented: $isConfirmingDelete, onDelete: removeEntry)
            .shortcutFeedback(model.shortcuts)
            .onAppear(perform: recordChipsOnFirstAppear)
        }
        .pinLimitAlert(model.shortcuts)
        .environment(model.shortcuts)
        .environment(model.tipProgress)
    }

    private func scrollToDate(_ proxy: ScrollViewProxy) {
        Task { @MainActor in
            await Task.yield()
            withAnimation { proxy.scrollTo(Self.dateBlockID, anchor: .bottom) }
        }
    }

    private var saveButton: some View {
        Button(action: save) {
            Text("Save").frame(maxWidth: .infinity, minHeight: Spacing.primaryButtonLabelHeight)
        }
        .primaryButton()
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .padding(.horizontal, Spacing.screenMargin)
        .padding(.bottom, Spacing.bottomClearance)
        .accessibilityIdentifier("save-entry")
        .background { saveBacking }
    }

    /// Hides the form where it passes under the button, and reaches no higher than the button's top edge.
    private var saveBacking: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.clear, .surface], startPoint: .top, endPoint: .bottom)
                .frame(height: Spacing.bottomClearance)
            Color.surface
        }
        .ignoresSafeArea(edges: .bottom)
        .allowsHitTesting(false)
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
        if let recents = recents[draft.kind], !recents.isEmpty {
            Section {
                RecentChipsRow(recents: recents) { draft.apply($0) }
                    .nonCardBlock()
            }
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
        deletedAction()
        dismiss()
    }
}
