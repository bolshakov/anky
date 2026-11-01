// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyMedicationModel
import SwiftUI

struct RootView: View {
    let model: EntryLogModel
    let medications: MedicationsModel
    @State private var selection = Tab.today

    var body: some View {
        TabView(selection: $selection) {
            TodayView(model: model, medications: medications)
                .tabItem {
                    Label("Today", systemImage: "calendar")
                        .fontWeight(selection == .today ? .bold : .regular)
                }
                .tag(Tab.today)

            HistoryView(model: model)
                .tabItem {
                    Label("History", systemImage: "clock")
                        .fontWeight(selection == .history ? .bold : .regular)
                }
                .tag(Tab.history)
        }
    }

    private enum Tab {
        case today, history
    }
}
