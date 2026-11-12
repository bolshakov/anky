// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct ReportBasdaiTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    private func moment(_ month: Int, _ day: Int, hour: Int = 10, minute: Int = 0) throws -> Date {
        try #require(calendar.date(from: DateComponents(
            year: 2026, month: month, day: day, hour: hour, minute: minute
        )))
    }

    private var now: Date {
        get throws { try moment(11, 11, hour: 15) }
    }

    private func report(_ results: [BasdaiResult], period: ReportPeriod = .threeMonths) throws -> ReportBasdai {
        try ReportBasdai(results: results, period: period, now: now, calendar: calendar)
    }

    @Test func aResultOnThePeriodsFirstMomentCounts() throws {
        let first = try madeUpBasdai(date: moment(8, 11, hour: 0))
        #expect(try report([first]).inPeriod == [first])
    }

    @Test func aResultOnNowCounts() throws {
        let last = try madeUpBasdai(date: now)
        #expect(try report([last]).inPeriod == [last])
    }

    @Test func aResultJustBeforeThePeriodOrAfterNowIsLeftOut() throws {
        let before = try madeUpBasdai(date: moment(8, 10, hour: 23, minute: 59))
        let after = try madeUpBasdai(date: moment(11, 11, hour: 15, minute: 1))
        #expect(try report([before, after]).inPeriod.isEmpty)
    }

    @Test func theShorterPeriodsKeepOnlyTheirOwnDays() throws {
        let inMonth = try madeUpBasdai(date: moment(10, 11))
        let inThreeMonths = try madeUpBasdai(date: moment(9, 1))
        let inSixMonths = try madeUpBasdai(date: moment(6, 1))
        let all = [inMonth, inThreeMonths, inSixMonths]
        #expect(try report(all, period: .oneMonth).inPeriod == [inMonth])
        #expect(try report(all, period: .threeMonths).inPeriod == [inMonth, inThreeMonths])
        #expect(try report(all, period: .sixMonths).inPeriod == all)
    }

    @Test func resultsComeNewestFirst() throws {
        let oldest = try madeUpBasdai(date: moment(9, 1))
        let middle = try madeUpBasdai(date: moment(10, 1))
        let newest = try madeUpBasdai(date: moment(11, 1))
        #expect(try report([middle, newest, oldest]).inPeriod == [newest, middle, oldest])
    }

    @Test func twoResultsOnOneDayFollowTheLaterTimeThenTheLaterCreation() throws {
        let morning = try madeUpBasdai(date: moment(10, 5, hour: 8))
        let evening = try madeUpBasdai(date: moment(10, 5, hour: 20))
        let earlyEntered = try madeUpBasdai(date: moment(10, 6), createdAt: moment(10, 7, hour: 9))
        let lateEntered = try madeUpBasdai(date: moment(10, 6), createdAt: moment(10, 7, hour: 18))
        let ordered = try report([morning, earlyEntered, evening, lateEntered]).inPeriod
        #expect(ordered == [lateEntered, earlyEntered, evening, morning])
    }

    @MainActor @Test func theOrderIsTheOneTheBasdaiListShows() throws {
        let first = try madeUpBasdai(date: moment(10, 5, hour: 8), createdAt: moment(10, 5, hour: 9))
        let second = try madeUpBasdai(date: moment(10, 5, hour: 20), createdAt: moment(10, 5, hour: 21))
        let third = try madeUpBasdai(date: moment(10, 5, hour: 20), createdAt: moment(10, 6, hour: 7))
        let fourth = try madeUpBasdai(date: moment(9, 2), createdAt: moment(9, 2))
        let results = [first, second, third, fourth]
        let list = BasdaiLog(store: FakeBasdaiStore(results)).results
        #expect(try report(results).inPeriod == list)
    }

    @Test func includedTrueGivesEveryResultOfThePeriod() throws {
        let kept = try madeUpBasdai(date: moment(10, 1))
        let left = try madeUpBasdai(date: moment(1, 1))
        #expect(try report([kept, left]).included(true) == [kept])
    }

    @Test func includedFalseGivesNothingWhateverThePeriodHolds() throws {
        let report = try report([madeUpBasdai(date: moment(10, 1)), madeUpBasdai(date: moment(11, 1))])
        #expect(!report.inPeriod.isEmpty)
        #expect(report.included(false).isEmpty)
    }

    @Test func noResultsGiveNothingEitherWay() throws {
        let report = try report([])
        #expect(report.included(true).isEmpty)
        #expect(report.included(false).isEmpty)
    }
}
