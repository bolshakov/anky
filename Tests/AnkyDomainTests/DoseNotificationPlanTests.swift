// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct DoseNotificationPlanTests {
    private let berlin: Calendar
    private let auckland: Calendar

    init() throws {
        berlin = try Self.gregorian(in: "Europe/Berlin")
        auckland = try Self.gregorian(in: "Pacific/Auckland")
    }

    private static func gregorian(in zone: String) throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: zone))
        return calendar
    }

    private func moment(_ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) throws -> Date {
        try moment(month, day, (hour, minute), in: berlin)
    }

    private func moment(_ month: Int, _ day: Int, _ time: (Int, Int), in calendar: Calendar) throws -> Date {
        let parts = DateComponents(year: 2026, month: month, day: day, hour: time.0, minute: time.1)
        return try #require(calendar.date(from: parts))
    }

    private func schedule(
        at clock: [(Int, Int)] = [(9, 0)],
        from start: (Int, Int) = (3, 10),
        to end: (Int, Int)? = nil
    ) throws -> MedicationSchedule {
        let times = try clock.map { try #require(DoseTime(hour: $0.0, minute: $0.1)) }
        let first = try #require(ScheduleDay(year: 2026, month: start.0, day: start.1))
        let last = try end.map { try #require(ScheduleDay(year: 2026, month: $0.0, day: $0.1)) }
        return try MedicationSchedule(repeat: .days(1), times: times, start: first, end: last)
    }

    private func medication(
        _ name: String = "Naproxen",
        id: UUID = UUID(),
        takenAs: TakenAs = .scheduled,
        schedule: MedicationSchedule?,
        archived: Bool = false
    ) throws -> Medication {
        var medication = try Medication(id: id, name: name, takenAs: takenAs, createdAt: moment(3, 1))
        medication.schedule = schedule
        medication.archivedAt = archived ? try moment(3, 2) : nil
        return medication
    }

    private func window(
        _ medications: [Medication],
        now: Date,
        budget: Int = 10,
        in calendar: Calendar? = nil
    ) -> [DoseNotification] {
        DoseNotificationPlan.window(medications: medications, now: now, budget: budget, calendar: calendar ?? berlin)
    }

    // MARK: End date

    @Test func aDailyScheduleStopsAfterItsEndDayAndKeepsTheEndDayItself() throws {
        let naproxen = try medication(schedule: schedule(from: (3, 10), to: (3, 14)))

        let planned = try window([naproxen], now: moment(3, 11, 12), budget: 10)

        #expect(try planned.map(\.fireAt) == [moment(3, 12, 9), moment(3, 13, 9), moment(3, 14, 9)])
    }

    @Test func aDoseOnTheEndDayAfterNowIsKeptAndTheNextDaysIsNot() throws {
        let naproxen = try medication(schedule: schedule(at: [(8, 0), (20, 0)], to: (3, 14)))

        let planned = try window([naproxen], now: moment(3, 14, 12), budget: 10)

        #expect(try planned.map(\.fireAt) == [moment(3, 14, 20)])
    }

    @Test func aScheduleWhoseEndDayHasPassedPlansNothing() throws {
        let naproxen = try medication(schedule: schedule(to: (3, 14)))

        #expect(try window([naproxen], now: moment(3, 15, 6)).isEmpty)
    }

    // MARK: Which medications count

    @Test func archivedAsNeededAndUnscheduledMedicationsGetNoNotification() throws {
        let daily = try schedule()
        let archived = try medication("Archived", schedule: daily, archived: true)
        let asNeeded = try medication("As needed", takenAs: .asNeeded, schedule: daily)
        let unscheduled = try medication("Unscheduled", schedule: nil)
        let active = try medication("Active", schedule: daily)

        let planned = try window([archived, asNeeded, unscheduled, active], now: moment(3, 12, 6), budget: 1)

        #expect(planned.map(\.medicationName) == ["Active"])
    }

    @Test func noActiveScheduledMedicationPlansNothing() throws {
        #expect(try window([], now: moment(3, 12)).isEmpty)
    }

    // MARK: Order and budget

    @Test func dosesOfSeveralMedicationsComeInTimeOrder() throws {
        let morning = try medication("Morning", schedule: schedule(at: [(8, 0)]))
        let evening = try medication("Evening", schedule: schedule(at: [(20, 0)]))

        let planned = try window([evening, morning], now: moment(3, 12, 6), budget: 4)

        let expected = try [(12, 8), (12, 20), (13, 8), (13, 20)].map { try moment(3, $0.0, $0.1) }
        #expect(planned.map(\.fireAt) == expected)
        #expect(planned.map(\.medicationName) == ["Morning", "Evening", "Morning", "Evening"])
    }

    @Test func theBudgetKeepsTheNearestDosesAcrossMedicationsNotAShareEach() throws {
        let busy = try medication("Busy", schedule: schedule(at: [(8, 0), (12, 0), (16, 0), (20, 0)]))
        let calm = try medication("Calm", schedule: schedule(at: [(9, 30)]))

        let planned = try window([busy, calm], now: moment(3, 12, 6), budget: 5)

        #expect(planned.map(\.medicationName) == ["Busy", "Calm", "Busy", "Busy", "Busy"])
    }

    @Test func aTieInTimeBreaksByTheMedicationIdString() throws {
        let low = try #require(UUID(uuidString: "00000000-0000-0000-0000-00000000000A"))
        let high = try #require(UUID(uuidString: "FFFFFFFF-0000-0000-0000-000000000000"))
        let first = try medication("Low", id: low, schedule: schedule())
        let second = try medication("High", id: high, schedule: schedule())

        let forward = try window([first, second], now: moment(3, 12), budget: 2)
        let backward = try window([second, first], now: moment(3, 12), budget: 2)

        #expect(forward.map(\.medicationID) == [low, high])
        #expect(backward == forward)
    }

    @Test func theBudgetIsAHardCap() throws {
        let naproxen = try medication(schedule: schedule(at: [(8, 0), (20, 0)]))

        let planned = try window([naproxen], now: moment(3, 12), budget: 3)

        #expect(planned.count == 3)
    }

    @Test func aBudgetOfZeroOrLessPlansNothing() throws {
        let naproxen = try medication(schedule: schedule())

        #expect(try window([naproxen], now: moment(3, 12), budget: 0).isEmpty)
        #expect(try window([naproxen], now: moment(3, 12), budget: -3).isEmpty)
    }

    @Test func theNameIsKeptExactlyAsTypedWithoutItsStrength() throws {
        var naproxen = try medication("  naproxen 50% ", schedule: schedule())
        naproxen.strength = "500 mg"

        let planned = try window([naproxen], now: moment(3, 12), budget: 1)

        #expect(planned.map(\.medicationName) == ["  naproxen 50% "])
    }

    // MARK: Time zone

    @Test func theSameScheduleKeepsEachDoseAtItsClockTimeInTheNewZone() throws {
        let naproxen = try medication(schedule: schedule(at: [(8, 0), (20, 30)]))

        let inBerlin = try window([naproxen], now: moment(3, 12, (6, 0), in: berlin), budget: 4, in: berlin)
        let inAuckland = try window([naproxen], now: moment(3, 12, (6, 0), in: auckland), budget: 4, in: auckland)

        let clock = [(8, 0), (20, 30)]
        let inBerlinExpected = try [12, 13].flatMap { day in try clock.map { try moment(3, day, $0, in: berlin) } }
        let inAucklandExpected = try [12, 13].flatMap { day in try clock.map { try moment(3, day, $0, in: auckland) } }
        #expect(inBerlin.map(\.fireAt) == inBerlinExpected)
        #expect(inAuckland.map(\.fireAt) == inAucklandExpected)
        #expect(inBerlin.map(\.fireAt) != inAuckland.map(\.fireAt))
    }

    // MARK: Identifier

    @Test func aDoseIdentifierHoldsTheMedicationIdAndTheUnixSeconds() throws {
        let id = try #require(UUID(uuidString: "0A1B2C3D-0000-4000-8000-0123456789AB"))
        let dose = DoseNotification(
            medicationID: id, medicationName: "Naproxen", fireAt: Date(timeIntervalSince1970: 1_900_000_000)
        )

        #expect(dose.identifier == "dose-due.0A1B2C3D-0000-4000-8000-0123456789AB.1900000000")
    }

    @Test func aDoseIdentifierIsNeverABareUUIDAndRoundTripsToItsMedication() throws {
        let naproxen = try medication(schedule: schedule())

        let planned = try window([naproxen], now: moment(3, 12), budget: 3)

        #expect(planned.count == 3)
        for dose in planned {
            #expect(UUID(uuidString: dose.identifier) == nil)
            #expect(DoseNotificationPlan.isDose(identifier: dose.identifier))
            #expect(DoseNotificationPlan.medicationID(fromIdentifier: dose.identifier) == naproxen.id)
        }
    }

    @Test func twoDosesOfOneMedicationHaveDifferentIdentifiers() throws {
        let naproxen = try medication(schedule: schedule(at: [(8, 0), (20, 0)]))

        let planned = try window([naproxen], now: moment(3, 12), budget: 4)

        #expect(Set(planned.map(\.identifier)).count == 4)
    }

    @Test func anIdentifierReadsBackInLowerCaseToo() {
        let id = UUID()
        let identifier = "dose-due.\(id.uuidString.lowercased()).1900000000"

        #expect(DoseNotificationPlan.medicationID(fromIdentifier: identifier) == id)
    }

    @Test(arguments: [
        "",
        "daily-reminder",
        "0A1B2C3D-0000-4000-8000-0123456789AB",
        "dose-due.",
        "dose-due.0A1B2C3D-0000-4000-8000-0123456789AB",
        "dose-due.0A1B2C3D-0000-4000-8000-0123456789AB.",
        "dose-due.0A1B2C3D-0000-4000-8000-0123456789AB.soon",
        "dose-due.0A1B2C3D-0000-4000-8000-0123456789AB.1900000000.1",
        "dose-due.not-a-uuid.1900000000",
        "dose-due..1900000000",
        "Dose-due.0A1B2C3D-0000-4000-8000-0123456789AB.1900000000",
        "check-in.0A1B2C3D-0000-4000-8000-0123456789AB.1900000000"
    ])
    func anythingElseIsNotADoseIdentifier(identifier: String) {
        #expect(DoseNotificationPlan.medicationID(fromIdentifier: identifier) == nil)
        #expect(!DoseNotificationPlan.isDose(identifier: identifier))
    }

    // MARK: Limit

    @Test func theLimitIsSixtyFour() {
        #expect(DoseNotificationPlan.limit == 64)
        #expect(DoseNotificationPlan.identifierPrefix == "dose-due.")
    }

    @Test(arguments: [(0, 64), (1, 63), (10, 54), (64, 0), (65, 0), (500, 0)])
    func theBudgetIsWhatTheOtherPendingRequestsLeave(otherPending: Int, budget: Int) {
        #expect(DoseNotificationPlan.budget(otherPending: otherPending) == budget)
    }
}
