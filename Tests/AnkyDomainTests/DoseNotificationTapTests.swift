// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct DoseNotificationTapTests {
    private let calendar: Calendar
    private let naproxen: Medication
    private let sulfasalazine: Medication

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Berlin"))
        self.calendar = calendar
        naproxen = try Self.scheduled(
            "Naproxen", id: "ABCDEF01-2345-4678-9ABC-DEF012345678", at: [(8, 0), (20, 0)], in: calendar
        )
        sulfasalazine = try Self.scheduled(
            "Sulfasalazine", id: "FEDCBA98-7654-4321-8FED-CBA987654321", at: [(9, 30)], in: calendar
        )
    }

    private static func scheduled(
        _ name: String,
        id: String,
        at clock: [(Int, Int)],
        in calendar: Calendar
    ) throws -> Medication {
        let createdAt = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 1)))
        var medication = try Medication(
            id: #require(UUID(uuidString: id)), name: name, takenAs: .scheduled, createdAt: createdAt
        )
        let times = try clock.map { try #require(DoseTime(hour: $0.0, minute: $0.1)) }
        let start = try #require(ScheduleDay(year: 2026, month: 3, day: 10))
        medication.schedule = try MedicationSchedule(repeat: .days(1), times: times, start: start, end: nil)
        return medication
    }

    private func window(_ medications: [Medication], budget: Int) throws -> [DoseNotification] {
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 12, hour: 7)))
        return DoseNotificationPlan.window(medications: medications, now: now, budget: budget, calendar: calendar)
    }

    @Test func everyScheduledDoseOfTwoMedicationsTapsThroughToItsOwnMedication() throws {
        let medications = [naproxen, sulfasalazine]
        let medicationByName = Dictionary(uniqueKeysWithValues: medications.map { ($0.name, $0) })

        let planned = try window(medications, budget: 9)

        #expect(planned.count == 9)
        #expect(Set(planned.map(\.medicationName)) == ["Naproxen", "Sulfasalazine"])
        for dose in planned {
            let medication = try #require(medicationByName[dose.medicationName])
            #expect(ReminderTapKind.of(identifier: dose.identifier) == .doseDue(medication.id))
        }
    }

    @Test func theUpperCaseUUIDTheSchedulerWritesTapsThroughToItsMedication() throws {
        let dose = try #require(window([naproxen], budget: 1).first)

        #expect(dose.identifier.contains("ABCDEF01-2345-4678-9ABC-DEF012345678"))
        #expect(ReminderTapKind.of(identifier: dose.identifier) == .doseDue(naproxen.id))
    }

    @Test func aDoseTimeWithAFractionalSecondTapsThroughToItsMedication() throws {
        let planned = try #require(window([naproxen], budget: 1).first)
        let dose = DoseNotification(
            medicationID: planned.medicationID,
            medicationName: planned.medicationName,
            fireAt: planned.fireAt.addingTimeInterval(0.75)
        )

        #expect(ReminderTapKind.of(identifier: dose.identifier) == .doseDue(naproxen.id))
    }
}
