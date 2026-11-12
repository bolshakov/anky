// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct ReportMedicationTextTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin") ?? .gmt
        return calendar
    }()

    private let british = Locale(identifier: "en_GB")

    /// Wednesday 11 November 2026, 15:00. A month back starts on 11 October, so the period has 32 calendar days.
    private var now: Date {
        get throws { try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 11, hour: 15))) }
    }

    private struct Taken {
        var before: Int?
        var after: Int?
        var minutesLater: Double = 60
    }

    /// One synthetic medication with one dose per `Taken`, each a day apart, read back as the report's only row.
    private func row(
        _ name: String = "Zorblex", strength: String? = nil, takenAs: TakenAs = .asNeeded, doses: [Taken]
    ) throws -> ReportMedicationRow {
        let now = try now
        var medication = Medication(id: UUID(), name: name, takenAs: takenAs, createdAt: now.addingTimeInterval(-1e7))
        medication.strength = strength
        var entries: [Entry] = []
        let taken = try doses.enumerated().map { index, taken in
            let takenAt = now.addingTimeInterval(-Double(index + 1) * 86400)
            let before = try taken.before.map { try entry($0, at: takenAt.addingTimeInterval(-600)) }
            let after = try taken.after.map { try entry($0, at: takenAt.addingTimeInterval(taken.minutesLater * 60)) }
            entries += [before, after].compactMap(\.self)
            var dose = Dose(id: UUID(), medicationID: medication.id, takenAt: takenAt, beforeReadingID: before?.id)
            dose.afterReadingID = after?.id
            return dose
        }
        let report = ReportMedications(
            medications: [medication], doses: taken, entries: entries, period: .oneMonth, now: now, calendar: calendar
        )
        return try #require(report.rows.first)
    }

    private func entry(_ severity: Int, at date: Date) throws -> Entry {
        try Entry(id: UUID(), kind: .pain, severity: #require(Severity(severity)), date: date, note: nil, places: [])
    }

    private func text(_ row: ReportMedicationRow, in locale: Locale? = nil) throws -> ReportMedicationRowText {
        let locale = locale ?? british
        let language = locale.language.languageCode?.identifier ?? "en"
        return try CompiledCatalog.withBundle(language) { ReportMedicationRowText(row, locale: locale, bundle: $0) }
    }

    private var severalReadings: [Taken] {
        let paired = [(5, 2, 100.0), (6, 3, 110), (7, 4, 110), (8, 5, 120)].map {
            Taken(before: $0.0, after: $0.1, minutesLater: $0.2)
        }
        return paired + [Taken(before: 7)]
    }

    @Test func severalQualifyingDosesReadAsAverageAndRange() throws {
        let text = try text(row("Zorblex", strength: "50 mg", doses: severalReadings))
        #expect(text.name == "Zorblex 50 mg")
        #expect(text.kind == "As needed")
        #expect(text.doses == "5")
        #expect(text.perWeek == "1.1")
        #expect(text.withAfter == "4")
        #expect(text.before == "6.5 (5–8)")
        #expect(text.after == "3.5 (2–5)")
        #expect(text.time == "1 h 50 min")
    }

    @Test func oneQualifyingDoseShowsItsValueAlone() throws {
        let text = try text(row(doses: [Taken(before: 6, after: 3, minutesLater: 45), Taken(before: 4)]))
        #expect(text.doses == "2")
        #expect(text.perWeek == "0.4")
        #expect(text.withAfter == "1")
        #expect(text.before == "6")
        #expect(text.after == "3")
        #expect(text.time == "45 min")
    }

    @Test func noQualifyingDoseShowsADash() throws {
        let text = try text(row(takenAs: .scheduled, doses: [Taken(before: 6), Taken(after: 3), Taken()]))
        #expect(text.kind == "Scheduled")
        #expect(text.doses == "3")
        #expect(text.withAfter == "1")
        #expect(text.before == "–")
        #expect(text.after == "–")
        #expect(text.time == "–")
    }

    @Test func theTimeRoundsToAWholeMinuteBeforeItSplitsIntoHours() throws {
        let minutes = [0, 44.6, 59.5, 60, 109.5, 119.6, 180, 185]
        let expected = ["0 min", "45 min", "1 h", "1 h", "1 h 50 min", "2 h", "3 h", "3 h 5 min"]
        let rows = try minutes.map { try row(doses: [Taken(before: 5, after: 3, minutesLater: $0)]) }
        let times = try CompiledCatalog.withBundle("en") { bundle in
            rows.map { ReportMedicationRowText($0, locale: british, bundle: bundle).time }
        }
        #expect(times == expected)
    }

    @Test func numbersFollowTheRegionSoEnglishInGermanyReadsADecimalComma() throws {
        let text = try text(row(doses: severalReadings), in: Locale(identifier: "en_DE"))
        #expect(text.perWeek == "1,1")
        #expect(text.before == "6,5 (5–8)")
        #expect(text.after == "3,5 (2–5)")
        #expect(text.time == "1 h 50 min")
    }

    @Test func russianReadsWithADecimalCommaAndShortUnits() throws {
        let text = try text(row(doses: severalReadings), in: russian)
        #expect(text.kind == "По необходимости")
        #expect(text.perWeek == "1,1")
        #expect(text.before == "6,5 (5–8)")
        #expect(text.time == "1 ч 50 мин")
    }

    @Test func russianTimeHasAFormForMinutesAndForWholeHours() throws {
        let rows = try [45.0, 120].map { try row(doses: [Taken(before: 5, after: 3, minutesLater: $0)]) }
        let times = try CompiledCatalog.withBundle("ru") { bundle in
            rows.map { ReportMedicationRowText($0, locale: russian, bundle: bundle).time }
        }
        #expect(times == ["45 мин", "2 ч"])
    }
}

struct ReportMedicationNoteTests {
    private let first = "Averages use only doses that have both a before and an after reading (the fourth column). "
        + "Pain is 0 to 10."

    @Test func theNoteEndsAtThePainScaleWithoutAScheduledMedication() throws {
        let note = try CompiledCatalog.withBundle("en") {
            ReportMedicationNote.text(hasScheduled: false, locale: Locale(identifier: "en_GB"), bundle: $0)
        }
        #expect(note == first)
    }

    @Test func theNoteAddsTheLastSentenceOnlyWithAScheduledMedication() throws {
        let note = try CompiledCatalog.withBundle("en") {
            ReportMedicationNote.text(hasScheduled: true, locale: Locale(identifier: "en_GB"), bundle: $0)
        }
        #expect(note == first + " A scheduled medication often has no after-reading.")
    }

    @Test func russianHasBothNotes() throws {
        let notes = try CompiledCatalog.withBundle("ru") { bundle in
            [false, true].map { ReportMedicationNote.text(hasScheduled: $0, locale: russian, bundle: bundle) }
        }
        let russianFirst = "Средние значения учитывают только приёмы, у которых есть и запись до, и запись после "
            + "(четвёртый столбец). Боль — от 0 до 10."
        #expect(notes == [russianFirst, russianFirst + " У лекарства по расписанию записи после приёма часто нет."])
    }
}
