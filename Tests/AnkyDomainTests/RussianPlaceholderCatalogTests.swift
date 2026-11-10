// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Testing

/// Every key whose English or Russian holds a `%@`, with what that placeholder holds. A new `%@` key fails until it is
/// added here with what it holds.
private let approvedPlaceholders = [
    "%@ of %lld": "a reading's level",
    "%@, %@ and %lld more": "place names",
    "After · checked in at %@": "a time",
    "Taken %@.": "a time"
]

private let textPlaceholder = "%(\\d+\\$)?@"

struct RussianPlaceholderCatalogTests {
    @Test func everyKeyWithATextPlaceholderIsOnTheApprovedList() throws {
        let unapproved = try CompiledCatalog.entries()
            .filter { approvedPlaceholders[$0.key] == nil && holdsATextPlaceholder($0.key, $0.value) }
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
