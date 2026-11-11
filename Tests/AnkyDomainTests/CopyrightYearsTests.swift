// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Testing

struct CopyrightYearsTests {
    @Test func matchingYearsGiveOneYear() {
        #expect(CopyrightYears.text(first: 2026, latest: 2026) == "2026")
    }

    @Test func aLaterLatestYearGivesARangeWithAnAsciiHyphen() {
        #expect(CopyrightYears.text(first: 2026, latest: 2027) == "2026-2027")
    }

    @Test func aLatestYearBeforeTheFirstGivesTheFirstYearAlone() {
        #expect(CopyrightYears.text(first: 2026, latest: 2025) == "2026")
    }

    @Test func theDefaultCallGivesTheReleaseYears() {
        #expect(CopyrightYears.text() == "2026")
    }
}
