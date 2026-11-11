// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

/// The six BASDAI questions, with every word a screen, a report or an export shows for them. Design checks these
/// strings against Garrett et al. 1994, so they live in this one file.
public struct BasdaiQuestion: Sendable {
    public struct Segment: Equatable, Sendable {
        public let text: String
        public let isBold: Bool
    }

    private enum Reading {
        case outOfTen
        case duration
    }

    public let number: Int
    public let wording: [Segment]
    public let shortName: String
    public let lowLabel, highLabel: String
    public let midLabel: String?
    private let reading: Reading

    public var text: String {
        wording.map(\.text).joined()
    }

    public static let all = questions(bundle: .main, locale: .current)

    public static func questions(bundle: Bundle, locale: Locale) -> [BasdaiQuestion] {
        severityQuestions(bundle: bundle, locale: locale) + [stiffnessDuration(bundle: bundle, locale: locale)]
    }

    public func valueText(_ answer: BasdaiAnswer, locale: Locale, bundle: Bundle = .main) -> String {
        guard let value = answer.value else {
            return String(localized: "Not answered", bundle: bundle, locale: locale)
        }
        return text(of: value, locale: locale, bundle: bundle)
    }

    public func spokenText(_ answer: BasdaiAnswer, locale: Locale, bundle: Bundle = .main) -> String {
        guard let value = answer.value else {
            return String(localized: "not answered", bundle: bundle, locale: locale)
        }
        return text(of: value, locale: locale, bundle: bundle)
    }

    private func text(of value: Int, locale: Locale, bundle: Bundle) -> String {
        switch reading {
        case .outOfTen: String(localized: "\(value) of \(10)", bundle: bundle, locale: locale)
        case .duration: Self.durationText(minutes: value * 12, locale: locale, bundle: bundle)
        }
    }

    private static func durationText(minutes: Int, locale: Locale, bundle: Bundle) -> String {
        switch minutes {
        case ..<60: String(localized: "\(minutes) min", bundle: bundle, locale: locale)
        case 60: String(localized: "1 hr", bundle: bundle, locale: locale)
        case ..<120: String(localized: "1 hr \(minutes - 60) min", bundle: bundle, locale: locale)
        default: String(localized: "2 hrs or more", bundle: bundle, locale: locale)
        }
    }
}

extension BasdaiQuestion {
    private typealias Words = (wording: String.LocalizationValue, shortName: String.LocalizationValue)

    private static func severityQuestions(bundle: Bundle, locale: Locale) -> [BasdaiQuestion] {
        let none = String(localized: "None", bundle: bundle, locale: locale)
        let verySevere = String(localized: "Very severe", bundle: bundle, locale: locale)
        return severityWords.enumerated().map { index, words in
            BasdaiQuestion(
                number: index + 1,
                wording: segments(String(localized: words.wording, bundle: bundle, locale: locale)),
                shortName: String(localized: words.shortName, bundle: bundle, locale: locale),
                lowLabel: none, highLabel: verySevere, midLabel: nil, reading: .outOfTen
            )
        }
    }

    private static var severityWords: [Words] {
        [("How would you describe the overall level of fatigue/tiredness you have experienced?", "Fatigue"),
         ("How would you describe the overall level of AS **neck, back or hip** pain you have had?", "Spinal pain"),
         ("""
         How would you describe the overall level of pain/swelling in joints **other than** neck, back or hips \
         you have had?
         """, "Joint pain"),
         ("""
         How would you describe the overall level of discomfort you have had from any areas tender to touch or \
         pressure?
         """, "Tenderness"),
         ("""
         How would you describe the overall level of morning stiffness you have had from the time you wake up?
         """, "Stiffness severity")]
    }

    private static func stiffnessDuration(bundle: Bundle, locale: Locale) -> BasdaiQuestion {
        BasdaiQuestion(
            number: 6,
            wording: segments(String(
                localized: "How long does your morning stiffness last from the time you wake up?",
                bundle: bundle, locale: locale
            )),
            shortName: String(localized: "Stiffness duration", bundle: bundle, locale: locale),
            lowLabel: String(localized: "0 hrs", bundle: bundle, locale: locale),
            highLabel: String(localized: "2 or more hrs", bundle: bundle, locale: locale),
            midLabel: String(localized: "1 hr", bundle: bundle, locale: locale),
            reading: .duration
        )
    }

    /// A question is one catalog string, so a translation keeps its own word order, and `**` marks the bold words.
    private static func segments(_ marked: String) -> [Segment] {
        marked.components(separatedBy: "**").enumerated()
            .filter { !$0.element.isEmpty }
            .map { Segment(text: $0.element, isBold: !$0.offset.isMultiple(of: 2)) }
    }
}
