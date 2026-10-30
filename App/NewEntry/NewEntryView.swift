import AnkyDomain
import SwiftUI

struct NewEntryView: View {
    let model: EntryLogModel
    let mode: EntryMode
    @Environment(\.dismiss) private var dismiss
    @State private var draft: EntryDraft
    @State private var startDraft: EntryDraft
    // Made once per opening, so a second tap on "Save entry" saves the same entry again.
    @State private var entryID = UUID()
    @State private var isShowingSaveFailure = false

    init(model: EntryLogModel, mode: EntryMode = .new) {
        self.model = model
        self.mode = mode
        let opening = switch mode {
        case .new: openingDraft(after: model.entries, now: .now)
        case let .edit(entry): EntryDraft(entry: entry)
        }
        _draft = State(initialValue: opening)
        // State, not a fresh call, so a view SwiftUI makes again still compares with the draft it opened with.
        _startDraft = State(initialValue: opening)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    KindSection(draft: $draft)
                    DateSection(draft: $draft)
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
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("cancel-entry")
                }
                .withoutGlassPill()
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .accessibilityAddTraits(.isHeader)
                }
                .withoutGlassPill()
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
            .interactiveDismissDisabled(draft != startDraft)
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

private extension ToolbarContent {
    /// iOS 26 puts a toolbar item on a glass pill, which the design does not have.
    @ToolbarContentBuilder
    func withoutGlassPill() -> some ToolbarContent {
        if #available(iOS 26, *) {
            sharedBackgroundVisibility(.hidden)
        } else {
            self
        }
    }
}
