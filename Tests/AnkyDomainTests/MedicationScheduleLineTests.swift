// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

private let british = Locale(identifier: "en_GB")

struct MedicationScheduleLineTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        calendar.firstWeekday = 2
        return calendar
    }

    private func everyTwoWeeks() throws -> MedicationSchedule {
        try MedicationSchedule(
            repeat: .weeks(2, on: [.friday]),
            times: [#require(DoseTime(hour: 9, minute: 0))],
            start: #require(ScheduleDay(year: 2026, month: 11, day: 13)),
            end: nil
        )
    }

    private func line(_ takenAs: TakenAs, _ schedule: MedicationSchedule?, in locale: Locale) throws -> String {
        let language = locale.language.languageCode?.identifier ?? "en"
        return try CompiledCatalog.withBundle(language) {
            MedicationScheduleLine.text(
                takenAs: takenAs, schedule: schedule, locale: locale, calendar: calendar, bundle: $0
            )
        }
    }

    @Test func asNeededReadsAsNeeded() throws {
        #expect(try line(.asNeeded, nil, in: british) == "As needed")
        #expect(try line(.asNeeded, nil, in: russian) == "По необходимости")
    }

    @Test func asNeededIgnoresASchedule() throws {
        #expect(try line(.asNeeded, everyTwoWeeks(), in: british) == "As needed")
    }

    @Test func scheduledWithAScheduleReadsItsWords() throws {
        let schedule = try everyTwoWeeks()
        let english = try line(.scheduled, schedule, in: british)
        #expect(english == "Every 2 weeks on Friday at 09:00")
        let words = try CompiledCatalog.withBundle("ru") {
            schedule.words(locale: russian, calendar: calendar, bundle: $0)
        }
        #expect(try line(.scheduled, schedule, in: russian) == words)
        #expect(words == "Каждые 2 недели: пятница, в 09:00")
    }

    @Test func scheduledWithNoScheduleReadsNotSet() throws {
        #expect(try line(.scheduled, nil, in: british) == "Not set")
        #expect(try line(.scheduled, nil, in: russian) == "Не задано")
    }

    @Test(arguments: [british, russian])
    func theListLineOfASavedMedicationEqualsTheLineTheFormRowShows(locale: Locale) throws {
        var draft = MedicationDraft()
        draft.name = "Zorblex"
        draft.takenAs = .scheduled
        draft.schedule = try everyTwoWeeks()
        let saved = draft.medication(id: UUID(), at: Date(timeIntervalSince1970: 1_800_000_000))

        let formLine = try line(draft.takenAs, draft.schedule, in: locale)
        let listLine = try line(saved.takenAs, saved.schedule, in: locale)
        #expect(listLine == formLine)
        #expect(formLine != (try line(.scheduled, nil, in: locale)))
    }
}
