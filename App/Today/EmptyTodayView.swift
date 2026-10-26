import SwiftUI

struct EmptyTodayView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "circle.dotted")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("Nothing logged today")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("Log how you feel, or a medication you took. Everything stays on this iPhone.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }
}
