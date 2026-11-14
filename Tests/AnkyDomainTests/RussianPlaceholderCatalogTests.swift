// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Testing

/// Every key whose English or Russian holds a `%@`, with what that placeholder holds. A new `%@` key fails until it is
/// added here with what it holds.
private let approvedPlaceholders = table("""
%@ of %lld => a reading's level
%@. => the schedule in words
Score %@ out of 10 => a BASDAI score with one decimal
%@. Next: %@. => the schedule in words and the day of the next dose
%@. Each answer is 0 to 10; score = (Q1 + Q2 + Q3 + Q4 + (Q5 + Q6) / 2) / 5. \
Bath Ankylosing Spondylitis Disease Activity Index (Garrett et al., J Rheumatol 1994). \
=> the six question labels with their short names
%@, %@ and %lld more => place names
%@ and %@, %@ to %@. => the entry and dose counts, then two days
%@ by week: %@, %@ => a symptom name, then the week counts
%@ (%lld–%lld) => the average pain with one decimal
%@ to %@ => two days
After · checked in at %@ => a time
Every %lld days at %@ => clock times
Every %lld months on day %lld at %@ => clock times
Every %lld weeks on %@ at %@ => weekday names and clock times
Every day at %@ => clock times
Every month on day %lld at %@ => clock times
Every week on %@ at %@ => weekday names and clock times
First entry %@ => a day
Nothing logged from %@ to %@. Pick a longer period. => two days
Q%lld %@ => a question's short name
Taken %@. => a time
Version %@ (%@) => the version and the build
created %@ => a day
""").map(\.key)

private let textPlaceholder = "%(\\d+\\$)?@"

struct RussianPlaceholderCatalogTests {
    @Test func everyKeyWithATextPlaceholderIsOnTheApprovedList() throws {
        let unapproved = try CompiledCatalog.entries()
            .filter { !approvedPlaceholders.contains($0.key) && holdsATextPlaceholder($0.key, $0.value) }
            .keys.sorted()
        #expect(
            unapproved.isEmpty,
            """
            Keys with a %@ that are not on the approved list: \(unapproved). A medication name goes as a title or \
            label beside the sentence, never inside it.
            """
        )
    }

    private func holdsATextPlaceholder(_ key: String, _ entry: CompiledCatalog.Entry) -> Bool {
        let values = (entry.localizations ?? [:]).values.flatMap(\.stringUnits).map(\.value)
        return ([key] + values).contains { $0.range(of: textPlaceholder, options: .regularExpression) != nil }
    }
}
