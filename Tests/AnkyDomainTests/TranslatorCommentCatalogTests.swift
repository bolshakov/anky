// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import Testing

private let ambiguousKeys = [
    "Check In", "Check in", "Dose", "Log dose", "Log Dose", "Pin", "Pinned", "Unpinned",
    "Left", "Right", "Manage", "Archive", "More actions",
]

struct TranslatorCommentCatalogTests {
    @Test(arguments: ambiguousKeys)
    func everyAmbiguousKeyCarriesAComment(key: String) throws {
        let entry = try #require(try CompiledCatalog.entries()[key])
        let comment = try #require(entry.comment, "\(key) has no translator comment")
        #expect(!comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
