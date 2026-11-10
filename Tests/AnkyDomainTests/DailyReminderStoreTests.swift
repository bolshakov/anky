// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct DailyReminderStoreTests {
    private func withDefaults(_ body: (UserDefaults, String) throws -> Void) throws {
        let name = "DailyReminderStoreTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        try body(defaults, name)
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }

    private var now: Date {
        calendar.date(from: DateComponents(year: 2030, month: 3, day: 10, hour: 9)) ?? .distantPast
    }

    @Test func turnedOffThereIsNoPendingDate() {
        let date = DailyReminder.pendingFireDate(
            isOn: false, entries: [], doses: [], time: .standard, now: now, calendar: calendar
        )
        #expect(date == nil)
    }

    @Test func turnedOnThePendingDateIsTheFireDate() {
        let date = DailyReminder.pendingFireDate(
            isOn: true, entries: [], doses: [], time: .standard, now: now, calendar: calendar
        )
        let expected = DailyReminder.fireDate(entries: [], doses: [], time: .standard, now: now, calendar: calendar)
        #expect(date != nil)
        #expect(date == expected)
    }

    @Test func aFreshStoreIsOffAtTheStandardTime() throws {
        try withDefaults { defaults, _ in
            let store = DailyReminderStore(defaults: defaults)
            #expect(store.isOn == false)
            #expect(store.time == .standard)
        }
    }

    @Test func theFlagPersistsAcrossStores() throws {
        try withDefaults { defaults, _ in
            var store = DailyReminderStore(defaults: defaults)
            store.isOn = true
            #expect(DailyReminderStore(defaults: defaults).isOn)
            store.isOn = false
            #expect(DailyReminderStore(defaults: defaults).isOn == false)
        }
    }

    @Test func theHourAndMinutePersistAcrossStores() throws {
        try withDefaults { defaults, _ in
            var store = DailyReminderStore(defaults: defaults)
            store.time = DailyReminderTime(hour: 7, minute: 45)
            #expect(DailyReminderStore(defaults: defaults).time == DailyReminderTime(hour: 7, minute: 45))
        }
    }

    @Test func midnightIsAChosenTimeAndNotTheDefault() throws {
        try withDefaults { defaults, _ in
            var store = DailyReminderStore(defaults: defaults)
            store.time = DailyReminderTime(hour: 0, minute: 0)
            #expect(DailyReminderStore(defaults: defaults).time == DailyReminderTime(hour: 0, minute: 0))
        }
    }

    @Test func nothingElseIsStored() throws {
        try withDefaults { defaults, name in
            var store = DailyReminderStore(defaults: defaults)
            store.isOn = true
            store.time = DailyReminderTime(hour: 6, minute: 30)
            let stored = Set(defaults.persistentDomain(forName: name)?.keys.map(\.self) ?? [])
            #expect(stored == ["dailyReminder.isOn", "dailyReminder.hour", "dailyReminder.minute"])
        }
    }
}
