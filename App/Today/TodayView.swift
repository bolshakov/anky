import AnkyDomain
import SwiftUI

struct TodayView: View {
    let model: EntryLogModel
    @State private var isShowingNewEntry = false

    private var todayEntries: [Entry] {
        TodayList.entries(model.entries, on: .now, calendar: .current)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("today-date")

                    if todayEntries.isEmpty {
                        EmptyTodayView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 48)
                    } else {
                        TodayEntryList(entries: todayEntries)
                            .padding(.top, 40)
                    }
                }
                .padding(.horizontal)
            }
            .background(Color("PageBackground"))
            .navigationTitle("Today")
            .safeAreaInset(edge: .bottom) {
                Button("Log how you feel") {
                    isShowingNewEntry = true
                }
                .buttonStyle(PinnedButtonStyle())
                .accessibilityIdentifier("log-entry")
                .padding()
            }
            .sheet(isPresented: $isShowingNewEntry) {
                NewEntryView(model: model)
            }
        }
    }
}
