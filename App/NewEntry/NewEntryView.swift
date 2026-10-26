import AnkyDomain
import SwiftUI

struct NewEntryView: View {
    let model: EntryLogModel
    @Environment(\.dismiss) private var dismiss
    @State private var draft: EntryDraft
    // Made once per opening, so a second tap on "Save entry" saves the same entry again.
    @State private var entryID = UUID()
    @State private var isShowingSaveFailure = false

    init(model: EntryLogModel) {
        self.model = model
        _draft = State(initialValue: openingDraft(after: model.entries, now: .now))
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
            .background(Color("PageBackground"))
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
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

    private func save() {
        do {
            try model.add(Entry(id: entryID, draft: draft))
            dismiss()
        } catch {
            isShowingSaveFailure = true
        }
    }
}
