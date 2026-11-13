// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct DoseNotificationRenameTests {
    private let berlin: Calendar
    private let morning: Date

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Berlin"))
        berlin = calendar
        morning = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1, hour: 8)))
    }

    private func medication(_ name: String, at clock: [(Int, Int)]) throws -> Medication {
        var medication = try Medication(id: UUID(), name: name, takenAs: .scheduled, createdAt: morning)
        let times = try clock.map { try #require(DoseTime(hour: $0.0, minute: $0.1)) }
        let start = try #require(ScheduleDay(year: 2026, month: 6, day: 1))
        medication.schedule = try MedicationSchedule(repeat: .days(1), times: times, start: start, end: nil)
        return medication
    }

    private func pendingAsPlanned(_ medications: [Medication]) -> [PendingNotification] {
        DoseNotificationPlan.window(
            medications: medications,
            now: morning,
            budget: DoseNotificationPlan.budget(otherPending: 0),
            calendar: berlin
        ).map { PendingNotification(identifier: $0.identifier, title: DoseNotificationContent($0, body: "").title) }
    }

    private func reconcile(_ medications: [Medication], on center: FakeNotificationCenter) async {
        await DoseNotificationReconciler(center: center)
            .reconcile(medications: medications, now: morning, calendar: berlin)
    }

    private func pendingDoses(_ center: FakeNotificationCenter) async -> [String] {
        await center.pendingIdentifiers.filter(DoseNotificationPlan.isDose(identifier:))
    }

    private func otherRequests(count: Int) -> [String] {
        (0 ..< count).map { _ in UUID().uuidString } + ["daily-reminder"]
    }

    private func busyPerson() throws -> [Medication] {
        let naproxen = try medication("Naproxen", at: [(8, 30), (12, 0), (20, 0)])
        let ibuprofen = try medication("Ibuprofen", at: [(9, 15), (21, 45)])
        return [naproxen, ibuprofen]
    }

    private func renamed(_ medication: Medication, to name: String) -> Medication {
        var renamed = medication
        renamed.name = name
        return renamed
    }

    @Test func `a rename gives every pending dose of the medication the new title and none the old one`() async throws {
        let naproxen = try medication("Naproxen", at: [(9, 0), (21, 0)])
        let center = FakeNotificationCenter()
        await reconcile([naproxen], on: center)
        let countBefore = await center.pendingIdentifiers.count

        await reconcile([renamed(naproxen, to: "Naproxen 500")], on: center)

        let titles = await center.pendingTitles
        #expect(titles.count == countBefore)
        #expect(titles.allSatisfy { $0 == "Naproxen 500" })
    }

    @Test func `a rename keeps the fire times and the number of pending doses`() async throws {
        let naproxen = try medication("Naproxen", at: [(9, 0), (21, 0)])
        let center = FakeNotificationCenter()
        await reconcile([naproxen], on: center)
        let before = await center.pendingIdentifiers

        await reconcile([renamed(naproxen, to: "Naproxen 500")], on: center)

        let after = await center.pendingIdentifiers
        #expect(after.count == before.count)
        #expect(Set(after) == Set(before))
    }

    @Test func `a rename removes the stale doses and adds them again before anything else is added`() async throws {
        let naproxen = try medication("Naproxen", at: [(9, 0)])
        let center = FakeNotificationCenter()
        await reconcile([naproxen], on: center)
        let before = await center.pendingIdentifiers
        let callsAfterFirst = await center.calls.count

        await reconcile([renamed(naproxen, to: "Naproxen 500")], on: center)

        let calls = await center.calls.dropFirst(callsAfterFirst)
        #expect(calls.first == .remove(before))
        #expect(calls.dropFirst() == ArraySlice(before.map { .add($0) }))
        #expect(await center.peakPending == before.count)
    }

    @Test func `pending doses that match the plan on identifier and title are left alone`() async throws {
        let naproxen = try medication("Naproxen", at: [(9, 0), (21, 0)])
        let center = FakeNotificationCenter(pending: pendingAsPlanned([naproxen]))

        await reconcile([naproxen], on: center)

        #expect(await center.calls.isEmpty)
    }

    @Test func `a rename of one medication replaces only its doses`() async throws {
        let naproxen = try medication("Naproxen", at: [(9, 0)])
        let ibuprofen = try medication("Ibuprofen", at: [(10, 0)])
        let center = FakeNotificationCenter()
        await reconcile([naproxen, ibuprofen], on: center)
        let ibuprofenDoses = await pendingDoses(center).filter { $0.contains(ibuprofen.id.uuidString) }
        let naproxenDoses = await pendingDoses(center).filter { $0.contains(naproxen.id.uuidString) }

        await reconcile([renamed(naproxen, to: "Naproxen 500"), ibuprofen], on: center)

        #expect(await Set(center.removedIdentifiers) == Set(naproxenDoses))
        #expect(await Set(center.addedIdentifiers.suffix(naproxenDoses.count)) == Set(naproxenDoses))
        #expect(await Set(center.removedIdentifiers).isDisjoint(with: ibuprofenDoses))
    }

    @Test func `a rename with other requests pending keeps the count and never removes them`() async throws {
        let others = otherRequests(count: 5)
        let medications = try busyPerson()
        let center = FakeNotificationCenter(pending: others.map(PendingNotification.other))
        await reconcile(medications, on: center)
        let countBefore = await center.pendingIdentifiers.count

        await reconcile([renamed(medications[0], to: "Naproxen 500"), medications[1]], on: center)

        #expect(await center.pendingIdentifiers.count == countBefore)
        #expect(await Set(center.removedIdentifiers).isDisjoint(with: others))
        #expect(await Set(center.pendingIdentifiers).isSuperset(of: others))
    }

    @Test func `an empty pending title is replaced like any other mismatch`() async throws {
        let naproxen = try medication("Naproxen", at: [(9, 0)])
        let untitled = pendingAsPlanned([naproxen]).map { PendingNotification(identifier: $0.identifier, title: "") }
        let center = FakeNotificationCenter(pending: untitled)

        await reconcile([naproxen], on: center)

        #expect(await center.pendingTitles.allSatisfy { $0 == "Naproxen" })
        #expect(await Set(center.removedIdentifiers) == Set(untitled.map(\.identifier)))
    }

    @Test func `a stale title is removed and nothing is added while permission is denied`() async throws {
        let naproxen = try medication("Naproxen", at: [(9, 0)])
        let center = FakeNotificationCenter(pending: pendingAsPlanned([naproxen]), permission: .denied)

        await reconcile([renamed(naproxen, to: "Naproxen 500")], on: center)

        #expect(await center.pendingIdentifiers.isEmpty)
        #expect(await center.addedIdentifiers.isEmpty)
        #expect(await center.permissionRequests == 0)
    }
}
