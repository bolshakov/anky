// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct ReportChartSentenceTests {
    private func figures(_ kind: EntryKind, weeks: Int, logged: Int) throws -> KindWeeklyFigures {
        let severity = try #require(Severity(4))
        let weeks = (0 ..< weeks).map { index in
            WeekFigures(
                weekStart: Date(timeIntervalSince1970: Double(index) * 7 * 86400),
                count: index < logged ? 1 : 0,
                mark: index < logged ? .single(severity) : .none
            )
        }
        return KindWeeklyFigures(kind: kind, weeks: weeks)
    }

    private func sentence(
        _ kind: EntryKind = .pain,
        weeks: Int,
        logged: Int,
        language: String = "en"
    ) throws -> String {
        let figures = try figures(kind, weeks: weeks, logged: logged)
        return try CompiledCatalog.withBundle(language) {
            ReportChartSentence.text(for: figures, bundle: $0, locale: Locale(identifier: language))
        }
    }

    @Test func thirteenWeeksWithElevenLoggedReadAsCounts() throws {
        #expect(try sentence(weeks: 13, logged: 11) == "Pain by week: 13 weeks, entries logged in 11 of them")
    }

    @Test func oneWeekIsSingular() throws {
        #expect(try sentence(weeks: 1, logged: 1) == "Pain by week: 1 week, entries logged in 1 of them")
    }

    @Test func noLoggedWeekReadsZero() throws {
        #expect(try sentence(weeks: 13, logged: 0) == "Pain by week: 13 weeks, entries logged in 0 of them")
    }

    @Test func theSentenceIsTheSameWhateverTheSeverities() throws {
        let none = try #require(Severity(0))
        let nine = try #require(Severity(9))
        let ten = try #require(Severity(10))
        let marks: [WeekMark] = [.single(none), .range(average: 9.5, lowest: nine, highest: ten)]
        let sentences = try CompiledCatalog.withBundle("en") { en in
            marks.map { mark in
                let week = WeekFigures(weekStart: Date(timeIntervalSince1970: 0), count: 2, mark: mark)
                let figures = KindWeeklyFigures(kind: .pain, weeks: [week])
                return ReportChartSentence.text(for: figures, bundle: en, locale: Locale(identifier: "en"))
            }
        }
        #expect(sentences[0] == sentences[1])
    }

    @Test(arguments: [(EntryKind.stiffness, "Stiffness"), (.fatigue, "Fatigue")])
    func theSentenceNamesItsKind(kind: EntryKind, name: String) throws {
        #expect(try sentence(kind, weeks: 4, logged: 2) == "\(name) by week: 4 weeks, entries logged in 2 of them")
    }

    @Test func theKindTakesTheNameTheAppAlreadyUses() throws {
        #expect(try sentence(.stiffness, weeks: 1, logged: 1, language: "ru").hasPrefix("Скованность"))
    }

    @Test(arguments: [(1, "1 неделя"), (3, "3 недели"), (5, "5 недель"), (21, "21 неделя")])
    func russianWeeksTakeTheirPluralForms(weeks: Int, phrase: String) throws {
        #expect(try sentence(weeks: weeks, logged: 1, language: "ru").contains(": \(phrase), "))
    }
}
