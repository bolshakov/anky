// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct PolicyBlockTests {
    private func plain(_ blocks: [PolicyBlock]) -> [String] {
        blocks.map { block in
            switch block {
            case let .heading(level, text): "h\(level) \(String(text.characters))"
            case let .paragraph(text): "p \(String(text.characters))"
            case let .listItem(text): "li \(String(text.characters))"
            }
        }
    }

    private func words(in text: AttributedString, where matches: (AttributedString.Runs.Run) -> Bool) -> [String] {
        text.runs.filter(matches).map { String(text[$0.range].characters) }
    }

    @Test func headingsKeepTheirLevelAndFileOrder() {
        let blocks = PolicyBlock.blocks(from: "# Title\n\nText.\n\n## Section\n\n### Deeper\n")

        #expect(plain(blocks) == ["h1 Title", "p Text.", "h2 Section", "h3 Deeper"])
    }

    @Test func headingWithInlineMarkKeepsTheMarkAndTheHeadingLevel() throws {
        let blocks = PolicyBlock.blocks(from: "## Your **control**")

        guard case let .heading(level, text) = try #require(blocks.first), blocks.count == 1 else {
            Issue.record("expected one heading, got \(blocks)")
            return
        }
        #expect(level == 2)
        #expect(String(text.characters) == "Your control")
        let marked = text.runs.filter { $0.inlinePresentationIntent == .stronglyEmphasized }
        #expect(marked.map { String(text[$0.range].characters) } == ["control"])
    }

    @Test func textKeepsNoBlockIntent() {
        let blocks = PolicyBlock.blocks(from: "# Title\n\nText.\n\n- item")

        let texts = blocks.map { block in
            switch block {
            case let .heading(_, text), let .paragraph(text), let .listItem(text): text
            }
        }
        #expect(texts.count == 3)
        #expect(texts.allSatisfy { text in text.runs.allSatisfy { $0.presentationIntent == nil } })
    }

    @Test func softLineBreakJoinsIntoOneParagraph() {
        let blocks = PolicyBlock.blocks(from: "Anky keeps what you log on your iPhone.\nIt has no accounts.")

        #expect(plain(blocks) == ["p Anky keeps what you log on your iPhone. It has no accounts."])
    }

    @Test func blankLineStartsANewParagraph() {
        let blocks = PolicyBlock.blocks(from: "First line\nwraps here.\n\nSecond paragraph.")

        #expect(plain(blocks) == ["p First line wraps here.", "p Second paragraph."])
    }

    @Test(arguments: [
        "One.\n\n\n\nTwo.",
        "One.  \n\nTwo.",
        "One.   \n   \n   \nTwo.   \n\n",
        "\n\nOne.\n\n \n\nTwo."
    ]) func extraBlankLinesAndTrailingSpacesMakeNoEmptyBlock(_ markdown: String) {
        #expect(plain(PolicyBlock.blocks(from: markdown)) == ["p One.", "p Two."])
    }

    @Test func listItemsAreBlocksOfTheirOwn() {
        let blocks = PolicyBlock.blocks(from: "Intro.\n\n- first\n- second\n")

        #expect(plain(blocks) == ["p Intro.", "li first", "li second"])
    }

    @Test func paragraphAfterAListStartsANewBlock() {
        let blocks = PolicyBlock.blocks(from: "- first\n- second\n\nAfter the list.\n")

        #expect(plain(blocks) == ["li first", "li second", "p After the list."])
    }

    @Test func boldItalicAndLinkMarksSurviveInAParagraph() throws {
        let blocks = PolicyBlock.blocks(from: "Plain **bold** and *italic* and [a link](https://example.com).")

        guard case let .paragraph(text) = try #require(blocks.first), blocks.count == 1 else {
            Issue.record("expected one paragraph, got \(blocks)")
            return
        }
        #expect(String(text.characters) == "Plain bold and italic and a link.")
        #expect(words(in: text, where: { $0.inlinePresentationIntent == .stronglyEmphasized }) == ["bold"])
        #expect(words(in: text, where: { $0.inlinePresentationIntent == .emphasized }) == ["italic"])
        #expect(words(in: text, where: { $0.link == URL(string: "https://example.com") }) == ["a link"])
    }

    @Test func marksSurviveInAListItem() throws {
        let blocks = PolicyBlock.blocks(from: "- plain **bold** [link](https://example.com)")

        guard case let .listItem(text) = try #require(blocks.first), blocks.count == 1 else {
            Issue.record("expected one list item, got \(blocks)")
            return
        }
        #expect(words(in: text, where: { $0.inlinePresentationIntent == .stronglyEmphasized }) == ["bold"])
        #expect(words(in: text, where: { $0.link != nil }) == ["link"])
    }

    @Test func referenceDefinitionsBecomeLinksAndAnUndefinedBracketStaysText() throws {
        let blocks = PolicyBlock.blocks(from: """
        Tagged at [repository URL], or write to [contact email] and not [no definition].

        [repository URL]: https://github.com/bolshakov/anky
        [contact email]: mailto:anky@bolshakov.dev
        """)

        guard case let .paragraph(text) = try #require(blocks.first), blocks.count == 1 else {
            Issue.record("expected one paragraph, got \(blocks)")
            return
        }
        #expect(
            String(text.characters) == "Tagged at repository URL, or write to contact email and not [no definition]."
        )
        let repository = URL(string: "https://github.com/bolshakov/anky")
        let email = URL(string: "mailto:anky@bolshakov.dev")
        #expect(words(in: text, where: { $0.link == repository }) == ["repository URL"])
        #expect(words(in: text, where: { $0.link == email }) == ["contact email"])
        #expect(words(in: text, where: { $0.link != nil }).count == 2)
    }

    @Test func codeBlockBecomesAParagraphOfItsText() {
        let blocks = PolicyBlock.blocks(from: "Before.\n\n```\nlet x = 1\n```\n\nAfter.")

        #expect(plain(blocks) == ["p Before.", "p let x = 1\n", "p After."])
    }

    @Test func nestedListItemBecomesAParagraphOfItsText() {
        let blocks = PolicyBlock.blocks(from: "- outer\n  - inner\n")

        #expect(plain(blocks) == ["li outer", "p inner"])
    }

    @Test func tableIsNotDropped() {
        let blocks = PolicyBlock.blocks(from: "| A | B |\n|---|---|\n| one | two |\n")

        let words = plain(blocks).joined(separator: " ")
        #expect(!blocks.isEmpty)
        for word in ["A", "B", "one", "two"] {
            #expect(words.contains(word))
        }
        #expect(blocks.allSatisfy {
            if case .paragraph = $0 {
                true
            } else {
                false
            }
        })
    }

    @Test func emptyTextHasNoBlocks() {
        #expect(PolicyBlock.blocks(from: "").isEmpty)
        #expect(PolicyBlock.blocks(from: "\n  \n\n").isEmpty)
    }

    @Test func policyExcerptSplitsIntoHeadingsAndParagraphs() {
        let blocks = PolicyBlock.blocks(from: """
        # Anky Privacy Policy

        Last updated: 11 November 2026

        ## The short version

        Anky keeps what you log on your iPhone. It has no accounts, servers or analytics and does not send your log
        anywhere, so the developer has no access to it.

        ## Your control

        You can edit or delete any entry in History.
        """)

        #expect(plain(blocks).joined(separator: "\n") == """
        h1 Anky Privacy Policy
        p Last updated: 11 November 2026
        h2 The short version
        p Anky keeps what you log on your iPhone. It has no accounts, servers or analytics and does not send your log \
        anywhere, so the developer has no access to it.
        h2 Your control
        p You can edit or delete any entry in History.
        """)
    }
}
