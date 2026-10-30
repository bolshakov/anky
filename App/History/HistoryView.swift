import AnkyDomain
import SwiftUI

struct HistoryView: View {
    let model: EntryLogModel
    @State private var now = Date.now
    @State private var editing: Entry?
    @State private var pendingDelete: Entry?
    @State private var saveTicks = 0

    private var sections: [DaySection] {
        HistoryList.sections(model.entries, now: now, calendar: .current)
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

    var body: some View {
        // Captured here, so the alert's button deletes the entry it was asked about even after the binding clears.
        let target = pendingDelete
        NavigationStack {
            Group {
                if sections.isEmpty {
                    EmptyHistoryView()
                } else {
                    List {
                        ForEach(sections) { section in
                            DaySectionView(
                                section: section,
                                onSelect: { editing = $0 },
                                onDelete: { pendingDelete = $0 }
                            )
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .headerProminence(.increased)
                }
            }
            .entryDeleteConfirmation(isPresented: isConfirmingDelete) {
                guard let target else { return }
                try model.remove(id: target.id)
            }
            .background(Color("PageBackground"))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("history-screen")
            .navigationTitle("History")
            .onAppear {
                now = .now
            }
            .sheet(item: $editing) { entry in
                NewEntryView(model: model, mode: .edit(entry), onSaved: { saveTicks += 1 })
            }
            .sensoryFeedback(.success, trigger: saveTicks)
        }
    }
}
