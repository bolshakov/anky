// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct NextDosePendingTests {
    private let berlin: Calendar

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Berlin"))
        berlin = calendar
    }

    private func june1(_ hour: Int, _ minute: Int = 0, _ second: Int = 0) throws -> Date {
        try #require(berlin.date(from: DateComponents(
            year: 2026, month: 6, day: 1, hour: hour, minute: minute, second: second
        )))
    }

    private func medication(_ name: String, at clock: [(Int, Int)]) throws -> Medication {
        var medication = try Medication(id: UUID(), name: name, takenAs: .scheduled, createdAt: june1(0))
        medication.schedule = try daily(at: clock)
        return medication
    }

    private func daily(at clock: [(Int, Int)]) throws -> MedicationSchedule {
        let times = try clock.map { try #require(DoseTime(hour: $0.0, minute: $0.1)) }
        let start = try #require(ScheduleDay(year: 2026, month: 6, day: 1))
        return try MedicationSchedule(repeat: .days(1), times: times, start: start, end: nil)
    }

    private func dose(of medication: Medication, at fireAt: Date) -> String {
        DoseNotification(medicationID: medication.id, medicationName: medication.name, fireAt: fireAt).identifier
    }

    private func reconcile(_ medications: [Medication], on center: FakeNotificationCenter, now: Date) async {
        await DoseNotificationReconciler(center: center).reconcile(medications: medications, now: now, calendar: berlin)
    }

    @Test func `after the first save of a schedule the next dose is pending`() async throws {
        let naproxen = try medication("Naproxen", at: [(9, 0)])
        let center = FakeNotificationCenter()

        try await reconcile([naproxen], on: center, now: june1(8))

        #expect(try await center.pendingIdentifiers.contains(dose(of: naproxen, at: june1(9))))
    }

    @Test func `no request reaches the center with a fire time at or before now`() async throws {
        let naproxen = try medication("Naproxen", at: [(9, 0), (21, 0)])
        let center = FakeNotificationCenter()
        let now = try june1(9)

        await reconcile([naproxen], on: center, now: now)

        let offered = await center.offered
        #expect(!offered.isEmpty)
        #expect(offered.allSatisfy { $0.fireAt > now })
        #expect(try await !center.addedIdentifiers.contains(dose(of: naproxen, at: june1(9))))
    }

    @Test func `a dose only seconds away is still pending`() async throws {
        let naproxen = try medication("Naproxen", at: [(9, 0)])
        let center = FakeNotificationCenter()

        try await reconcile([naproxen], on: center, now: june1(8, 59, 59))

        #expect(try await center.pendingIdentifiers.first == dose(of: naproxen, at: june1(9)))
    }

    @Test func `a refused request is not pending, the rest are, and the next rebuild adds it`() async throws {
        let naproxen = try medication("Naproxen", at: [(9, 0)])
        let nearest = try dose(of: naproxen, at: june1(9))
        let tomorrow = try dose(of: naproxen, at: june1(9).addingTimeInterval(24 * 3600))
        let center = FakeNotificationCenter(refusing: [nearest])
        let now = try june1(8)

        await reconcile([naproxen], on: center, now: now)

        let afterRefusal = await center.pendingIdentifiers
        #expect(!afterRefusal.contains(nearest))
        #expect(afterRefusal.first == tomorrow)
        #expect(afterRefusal.count == DoseNotificationPlan.budget(otherPending: 0) - 1)

        await center.setRefusing([])
        await reconcile([naproxen], on: center, now: now)

        #expect(await center.pendingIdentifiers.contains(nearest))
        #expect(await center.pendingIdentifiers.count == DoseNotificationPlan.budget(otherPending: 0))
    }

    @Test func `an edit of the time removes the old requests and the next dose at the new time is pending`(
    ) async throws {
        var naproxen = try medication("Naproxen", at: [(14, 19)])
        let center = FakeNotificationCenter()
        let now = try june1(14, 25)
        await reconcile([naproxen], on: center, now: now)
        let before = await center.pendingIdentifiers

        naproxen.schedule = try daily(at: [(14, 30)])
        await reconcile([naproxen], on: center, now: now)

        let after = await center.pendingIdentifiers
        #expect(Set(after).isDisjoint(with: before))
        #expect(try after.first == dose(of: naproxen, at: june1(14, 30)))
    }

    @Test func `with check-ins and the daily reminder pending the next dose is still pending`() async throws {
        let others = (0 ..< 5).map { _ in UUID().uuidString } + ["daily-reminder"]
        let naproxen = try medication("Naproxen", at: [(8, 30), (12, 0), (20, 0)])
        let ibuprofen = try medication("Ibuprofen", at: [(9, 15), (21, 45)])
        let center = FakeNotificationCenter(pending: others)

        try await reconcile([naproxen, ibuprofen], on: center, now: june1(8))

        let pending = await center.pendingIdentifiers
        #expect(try pending.contains(dose(of: naproxen, at: june1(8, 30))))
        #expect(others.allSatisfy(pending.contains))
        #expect(pending.count <= DoseNotificationPlan.limit)
        #expect(await center.droppedIdentifiers.isEmpty)
    }

    @Test func `a check-in and the daily reminder added after the window leave the next dose pending`() async throws {
        let naproxen = try medication("Naproxen", at: [(9, 0)])
        let center = FakeNotificationCenter()
        try await reconcile([naproxen], on: center, now: june1(8))

        await center.addOther(UUID().uuidString)
        await center.addOther("daily-reminder")

        #expect(try await center.pendingIdentifiers.contains(dose(of: naproxen, at: june1(9))))
        #expect(await center.droppedIdentifiers.isEmpty)
    }
}
