// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct CheckInClock: ViewModifier {
    @Binding var now: Date
    let nextChange: Date?
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .onAppear { now = .now }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    now = .now
                }
            }
            .task(id: nextChange) {
                guard let nextChange else { return }
                try? await Task.sleep(for: .seconds(max(0, nextChange.timeIntervalSinceNow)))
                guard !Task.isCancelled else { return }
                now = max(Date.now, nextChange)
            }
    }
}

extension View {
    func checkInClock(now: Binding<Date>, nextChange: Date?) -> some View {
        modifier(CheckInClock(now: now, nextChange: nextChange))
    }
}
