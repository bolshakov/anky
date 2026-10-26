import SwiftUI

struct TodayView: View {
    @State private var isShowingNewEntry = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("today-date")

                    EmptyTodayView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 48)
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
                .padding()
            }
            .sheet(isPresented: $isShowingNewEntry) {
                NewEntryPlaceholder()
            }
        }
    }
}
