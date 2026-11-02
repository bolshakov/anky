// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct CheckInClock: ViewModifier {
    @Binding var now: Date
    let nextDue: Date?
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .onAppear { now = .now }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    now = .now
                }
            }
            .task(id: nextDue) {
                guard let nextDue else { return }
                try? await Task.sleep(for: .seconds(max(0, nextDue.timeIntervalSinceNow)))
                guard !Task.isCancelled else { return }
                now = max(Date.now, nextDue)
            }
    }
}

extension View {
    func checkInClock(now: Binding<Date>, nextDue: Date?) -> some View {
        modifier(CheckInClock(now: now, nextDue: nextDue))
    }
}
