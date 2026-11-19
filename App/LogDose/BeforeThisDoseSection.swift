// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

/// The words of the "Log how you feel" action, which say whether the dose is being logged as it happens or after.
struct ReadingPromptText: View {
    let prompt: ReadingPrompt

    var body: some View {
        switch prompt {
        case .now: Text("Log how you feel now")
        case .earlier: Text("Log how you felt")
        }
    }
}

/// The reading before a dose, which pushes Choose an Entry, or the row that logs one when there is none. The title is
/// the same in every state. A screen with no prompt has no row that logs one, so its empty row reads None and pushes.
/// With an `onRemove`, a linked row can be swiped to None.
struct BeforeThisDoseSection<Destination: View>: View {
    let reading: Entry?
    var isNone = false
    let prompt: ReadingPrompt?
    var onLog: () -> Void = {}
    var onRemove: (() -> Void)?
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        CardSection(
            Text("Before this dose"),
            footnote: footnoteText,
            id: "before-reading"
        ) {
            row
        }
    }

    private var showsNone: Bool {
        isNone || prompt == nil
    }

    private var footnoteText: Text? {
        if reading != nil {
            Text("The entry used for this dose. Tap to choose another, or swipe left to remove.")
        } else if showsNone {
            Text("Not linked to an entry.")
        } else {
            nil
        }
    }

    @ViewBuilder
    private var row: some View {
        if let reading {
            NavigationLink(destination: destination) {
                EntryIconRow(entry: reading)
                    .spokenAsReading()
            }
            .accessibilityIdentifier("before-reading-row")
            .removeSwipe(id: "before-reading-remove", onRemove)
        } else if showsNone {
            NavigationLink(destination: destination) {
                Text("None")
                    .foregroundStyle(Color.ink2)
                    .rowHeight()
            }
            .fillsCardRow()
            .accessibilityIdentifier("before-reading-row")
        } else if let prompt {
            Button(action: onLog) {
                ReadingPromptText(prompt: prompt)
            }
            .accessibilityIdentifier("log-how-you-feel-row")
        }
    }
}

extension View {
    /// The quiet, reversible swipe that unlinks a reading. It is not `deleteSwipe`, which is a destructive red trash.
    @ViewBuilder
    func removeSwipe(id: String, _ onRemove: (() -> Void)?) -> some View {
        if let onRemove {
            swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button("Remove", systemImage: "xmark", action: onRemove)
                    .tint(Color.ink2)
                    .accessibilityIdentifier(id)
            }
        } else {
            self
        }
    }
}
