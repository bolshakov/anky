// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Observation

@MainActor @Observable final class DailyReminderSettings {
    var isOn: Bool {
        didSet { store.isOn = isOn }
    }

    var time: DailyReminderTime {
        didSet { store.time = time }
    }

    @ObservationIgnored private var store: DailyReminderStore

    init(store: DailyReminderStore = DailyReminderStore(defaults: .standard)) {
        self.store = store
        isOn = store.isOn
        time = store.time
    }
}
