// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

public enum PolicyBlock: Equatable, Sendable {
    case heading(level: Int, text: AttributedString)
    case paragraph(AttributedString)
    case listItem(AttributedString)
}

extension PolicyBlock {
    public static func blocks(from markdown: String) -> [PolicyBlock] {
        guard let parsed = try? AttributedString(
            markdown: markdown,
            options: .init(interpretedSyntax: .full)
        ) else { return [] }

        var blocks: [PolicyBlock] = []
        var currentIdentity: Int?
        var currentKind: Kind = .paragraph
        var currentText = AttributedString()

        func finishBlock() {
            if currentText.characters.contains(where: { !$0.isWhitespace }) {
                blocks.append(currentKind.block(currentText))
            }
            currentText = AttributedString()
        }

        for run in parsed.runs {
            let intent = run.presentationIntent
            let identity = intent?.components.first?.identity
            if identity != currentIdentity {
                finishBlock()
                currentIdentity = identity
                currentKind = Kind(intent)
            }
            var piece = AttributedString(parsed[run.range])
            piece.presentationIntent = nil
            currentText.append(piece)
        }
        finishBlock()
        return blocks
    }

    private enum Kind {
        case heading(Int)
        case paragraph
        case listItem

        init(_ intent: PresentationIntent?) {
            let components = intent?.components.map(\.kind) ?? []
            switch components.first {
            case let .header(level: level):
                self = .heading(level)
            case .paragraph where components.contains(where: \.isListItem):
                self = components.filter(\.isListItem).count == 1 ? .listItem : .paragraph
            default:
                self = .paragraph
            }
        }

        func block(_ text: AttributedString) -> PolicyBlock {
            switch self {
            case let .heading(level): .heading(level: level, text: text)
            case .paragraph: .paragraph(text)
            case .listItem: .listItem(text)
            }
        }
    }
}

private extension PresentationIntent.Kind {
    var isListItem: Bool {
        if case .listItem = self {
            true
        } else {
            false
        }
    }
}
