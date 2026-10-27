import AnkyDomain
import SwiftUI

struct NewEntryView: View {
    let model: EntryLogModel
    @Environment(\.dismiss) private var dismiss
    @State private var draft: EntryDraft
    @State private var startDraft: EntryDraft
    // Made once per opening, so a second tap on "Save entry" saves the same entry again.
    @State private var entryID = UUID()
    @State private var isShowingSaveFailure = false
    @State private var isAskingToDiscard = false

    init(model: EntryLogModel) {
        self.model = model
        let opening = openingDraft(after: model.entries, now: .now)
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
                }
                .padding()
            }
            .alert("Discard this entry?", isPresented: $isAskingToDiscard) {
                Button("Discard", role: .destructive) {
                    dismiss()
                }
                Button("Keep editing", role: .cancel) {}
            }
            .background(Color("PageBackground"))
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        cancel()
                    }
                }
                .withoutGlassPill()
            }
            .safeAreaInset(edge: .bottom) {
                Button("Save entry") {
                    save()
                }
                .buttonStyle(PinnedButtonStyle())
                .padding()
            }
            .alert("This entry could not be saved.", isPresented: $isShowingSaveFailure) {
                Button("OK") {}
            }
        }
    }

    private func cancel() {
        if draft == startDraft {
            dismiss()
        } else {
            isAskingToDiscard = true
        }
    }

    private func save() {
        do {
            try model.add(Entry(id: entryID, draft: draft))
            dismiss()
        } catch {
            isShowingSaveFailure = true
        }
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
