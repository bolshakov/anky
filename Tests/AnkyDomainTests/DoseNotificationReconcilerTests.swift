// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct DoseNotificationReconcilerTests {
    private let berlin: Calendar
    private let morning: Date

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Berlin"))
        berlin = calendar
        morning = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1, hour: 8)))
    }

    private func medication(
        _ name: String,
        at clock: [(Int, Int)] = [(9, 0)],
        archived: Bool = false
    ) throws -> Medication {
        var medication = try Medication(id: UUID(), name: name, takenAs: .scheduled, createdAt: morning)
        medication.schedule = try daily(at: clock)
        medication.archivedAt = archived ? morning : nil
        return medication
    }

    private func daily(at clock: [(Int, Int)]) throws -> MedicationSchedule {
        let times = try clock.map { try #require(DoseTime(hour: $0.0, minute: $0.1)) }
        let start = try #require(ScheduleDay(year: 2026, month: 6, day: 1))
        return try MedicationSchedule(repeat: .days(1), times: times, start: start, end: nil)
    }

    private func expected(_ medications: [Medication], now: Date? = nil, otherPending: Int = 0) -> [String] {
        DoseNotificationPlan.window(
            medications: medications,
            now: now ?? morning,
            budget: DoseNotificationPlan.budget(otherPending: otherPending),
            calendar: berlin
        ).map(\.identifier)
    }

    private func reconcile(
        _ medications: [Medication],
        on center: FakeNotificationCenter,
        now: Date? = nil
    ) async {
        await DoseNotificationReconciler(center: center)
            .reconcile(medications: medications, now: now ?? morning, calendar: berlin)
    }

    private func pendingDoses(_ center: FakeNotificationCenter) async -> [String] {
        await center.pendingIdentifiers.filter(DoseNotificationPlan.isDose(identifier:))
    }

    private func busyPerson() throws -> [Medication] {
        let naproxen = try medication("Naproxen", at: [(8, 30), (12, 0), (20, 0)])
        let ibuprofen = try medication("Ibuprofen", at: [(9, 15), (21, 45)])
        return [naproxen, ibuprofen]
    }

    private func otherRequests(count: Int) -> [String] {
        (0 ..< count).map { _ in UUID().uuidString } + ["daily-reminder"]
    }

    // MARK: Triggers

    @Test func `first save of a schedule adds its window, nearest first`() async throws {
        let naproxen = try medication("Naproxen", at: [(9, 0), (21, 0)])
        let center = FakeNotificationCenter()

        await reconcile([naproxen], on: center)

        #expect(await center.addedIdentifiers == expected([naproxen]))
        #expect(await center.removedIdentifiers.isEmpty)
        #expect(await center.pendingIdentifiers.count == DoseNotificationPlan.limit)
    }

    @Test func `a rebuild with nothing changed adds and removes nothing`() async throws {
        let naproxen = try medication("Naproxen")
        let center = FakeNotificationCenter()
        await reconcile([naproxen], on: center)
        let callsAfterFirst = await center.calls

        await reconcile([naproxen], on: center)

        #expect(await center.calls == callsAfterFirst)
    }

    @Test func `an edit of the times replaces exactly the old notifications and adds nothing twice`() async throws {
        var naproxen = try medication("Naproxen", at: [(9, 0)])
        let center = FakeNotificationCenter()
        await reconcile([naproxen], on: center)
        let before = await center.pendingIdentifiers

        naproxen.schedule = try daily(at: [(21, 0)])
        await reconcile([naproxen], on: center)

        let after = await center.pendingIdentifiers
        #expect(Set(after) == Set(expected([naproxen])))
        #expect(Set(after).count == after.count)
        #expect(await Set(center.removedIdentifiers) == Set(before))
        #expect(await Set(center.addedIdentifiers).count == before.count + after.count)
    }

    @Test func `an edit that keeps a time leaves those notifications alone`() async throws {
        var naproxen = try medication("Naproxen", at: [(9, 0)])
        let center = FakeNotificationCenter()
        await reconcile([naproxen], on: center)
        let before = await Set(center.pendingIdentifiers)

        naproxen.schedule = try daily(at: [(9, 0), (21, 0)])
        await reconcile([naproxen], on: center)

        let wanted = Set(expected([naproxen]))
        #expect(await Set(center.pendingIdentifiers) == wanted)
        #expect(await Set(center.removedIdentifiers).isDisjoint(with: wanted))
        #expect(await Set(center.addedIdentifiers.suffix(wanted.subtracting(before).count)).isDisjoint(with: before))
    }

    @Test func `archive clears only that medication and restore brings it back`() async throws {
        let naproxen = try medication("Naproxen", at: [(9, 0)])
        var ibuprofen = try medication("Ibuprofen", at: [(10, 0)])
        let center = FakeNotificationCenter()
        await reconcile([naproxen, ibuprofen], on: center)

        ibuprofen.archivedAt = morning
        await reconcile([naproxen, ibuprofen], on: center)
        #expect(await Set(pendingDoses(center)) == Set(expected([naproxen])))

        ibuprofen.archivedAt = nil
        await reconcile([naproxen, ibuprofen], on: center)
        #expect(await Set(pendingDoses(center)) == Set(expected([naproxen, ibuprofen])))
    }

    @Test func `erase clears every dose notification and leaves other requests`() async throws {
        let naproxen = try medication("Naproxen")
        let center = FakeNotificationCenter(pending: ["daily-reminder"])
        await reconcile([naproxen], on: center)

        await reconcile([], on: center)

        #expect(await center.pendingIdentifiers == ["daily-reminder"])
    }

    @Test func `launch over pending requests that match changes nothing`() async throws {
        let naproxen = try medication("Naproxen", at: [(9, 0), (21, 0)])
        let center = FakeNotificationCenter(
            pending: expected([naproxen], otherPending: 1) + ["daily-reminder"],
            permission: .denied
        )

        await reconcile([naproxen], on: center)

        #expect(await center.calls.isEmpty)
        #expect(await center.permissionRequests == 0)
    }

    @Test func `a later rebuild drops the past doses and refills the window`() async throws {
        let naproxen = try medication("Naproxen", at: [(9, 0), (21, 0)])
        let center = FakeNotificationCenter()
        await reconcile([naproxen], on: center)
        let later = morning.addingTimeInterval(3 * 24 * 3600)

        await reconcile([naproxen], on: center, now: later)

        #expect(await Set(pendingDoses(center)) == Set(expected([naproxen], now: later)))
    }

    // MARK: The limit of 64

    @Test func `other pending requests count against the budget and are never removed`() async throws {
        let others = otherRequests(count: 5)
        let medications = try busyPerson()
        let center = FakeNotificationCenter(pending: others)

        await reconcile(medications, on: center)

        let pending = await center.pendingIdentifiers
        #expect(pending.count == DoseNotificationPlan.limit)
        #expect(others.allSatisfy(pending.contains))
        #expect(await pendingDoses(center) == expected(medications, otherPending: others.count))
    }

    @Test func `the kept doses are the nearest in time across medications`() async throws {
        let medications = try busyPerson()
        let center = FakeNotificationCenter(pending: otherRequests(count: 3))
        let everyDose = DoseNotificationPlan.window(
            medications: medications,
            now: morning,
            budget: 500,
            calendar: berlin
        )

        await reconcile(medications, on: center)

        let kept = await pendingDoses(center)
        #expect(Set(kept) == Set(everyDose.prefix(kept.count).map(\.identifier)))
        #expect(kept.count == DoseNotificationPlan.limit - 4)
    }

    @Test func `a rebuild removes before it adds, so the count never passes the limit`() async throws {
        let naproxen = try medication("Naproxen", at: [(9, 0)])
        let center = FakeNotificationCenter()
        await reconcile([naproxen], on: center)
        var edited = naproxen
        edited.schedule = try daily(at: [(21, 0)])

        await reconcile([edited], on: center)

        #expect(await center.peakPending == DoseNotificationPlan.limit)
    }

    @Test func `no budget left adds nothing and still removes the old doses`() async throws {
        let naproxen = try medication("Naproxen")
        let stale = "\(DoseNotificationPlan.identifierPrefix)\(UUID().uuidString).1"
        let center = FakeNotificationCenter(pending: otherRequests(count: DoseNotificationPlan.limit) + [stale])

        await reconcile([naproxen], on: center)

        #expect(await center.addedIdentifiers.isEmpty)
        #expect(await center.removedIdentifiers == [stale])
    }

    // MARK: Permission

    @Test func `a refusal schedules nothing and nothing asks again`() async throws {
        let naproxen = try medication("Naproxen")
        let center = FakeNotificationCenter(permission: .notDetermined, answer: false)

        await reconcile([naproxen], on: center)
        await reconcile([naproxen], on: center)
        await reconcile([naproxen], on: center)

        #expect(await center.permissionRequests == 1)
        #expect(await center.calls.isEmpty)
    }

    @Test func `a person who already refused is never asked`() async throws {
        let center = FakeNotificationCenter(permission: .denied)

        try await reconcile([medication("Naproxen")], on: center)

        #expect(await center.permissionRequests == 0)
        #expect(await center.calls.isEmpty)
    }

    @Test func `an answer of yes is asked once and schedules the window`() async throws {
        let naproxen = try medication("Naproxen")
        let center = FakeNotificationCenter(permission: .notDetermined, answer: true)

        await reconcile([naproxen], on: center)
        await reconcile([naproxen], on: center)

        #expect(await center.permissionRequests == 1)
        #expect(await center.addedIdentifiers == expected([naproxen]))
    }

    @Test func `permission is not asked when no scheduled medication exists`() async throws {
        var asNeeded = try medication("Naproxen")
        asNeeded.takenAs = .asNeeded
        let archived = try medication("Ibuprofen", archived: true)
        let center = FakeNotificationCenter(permission: .notDetermined)

        await reconcile([asNeeded, archived], on: center)
        await reconcile([], on: center)

        #expect(await center.permissionRequests == 0)
    }

    @Test func `permission is not asked when everything is already pending`() async throws {
        let naproxen = try medication("Naproxen")
        let center = FakeNotificationCenter(pending: expected([naproxen]), permission: .notDetermined)

        await reconcile([naproxen], on: center)

        #expect(await center.permissionRequests == 0)
    }

    @Test func `old doses are removed even when permission is denied`() async throws {
        let naproxen = try medication("Naproxen")
        let center = FakeNotificationCenter(pending: expected([naproxen]), permission: .denied)

        await reconcile([], on: center)

        #expect(await center.pendingIdentifiers.isEmpty)
        #expect(await center.permissionRequests == 0)
    }
}
