import SwiftUI

struct EmptyHistoryView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Image(systemName: "clock")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                Text("No entries yet")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("empty-history")

                Text("Entries you add appear here, newest first.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            .frame(maxWidth: .infinity)
            .padding(.top, 96)
        }
    }
}
