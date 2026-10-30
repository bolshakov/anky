import AnkyDomain
import SwiftUI

struct HistoryView: View {
    let model: EntryLogModel
    @State private var now = Date.now
    @State private var editing: Entry?

    private var sections: [DaySection] {
        HistoryList.sections(model.entries, now: now, calendar: .current)
    }

    var body: some View {
        NavigationStack {
            Group {
                if sections.isEmpty {
                    EmptyHistoryView()
                } else {
                    List {
                        ForEach(sections) { section in
                            DaySectionView(section: section, onSelect: { editing = $0 })
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .headerProminence(.increased)
                }
            }
            .background(Color("PageBackground"))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("history-screen")
            .navigationTitle("History")
            .onAppear {
                now = .now
            }
            .sheet(item: $editing) { entry in
                NewEntryView(model: model, mode: .edit(entry))
            }
        }
    }
}
