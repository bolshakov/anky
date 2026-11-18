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
/// the same in both states. A screen with no prompt has no row that logs one, so its empty row reads None and pushes.
struct BeforeThisDoseSection<Destination: View>: View {
    let reading: Entry?
    let prompt: ReadingPrompt?
    var onLog: () -> Void = {}
    var footnote = Text("Your latest entry before this dose. Tap to choose another.")
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        CardSection(
            Text("Before this dose"),
            footnote: reading.map { _ in footnote },
            id: "before-reading"
        ) {
            row
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
        } else if let prompt {
            Button(action: onLog) {
                ReadingPromptText(prompt: prompt)
            }
            .accessibilityIdentifier("log-how-you-feel-row")
        } else {
            NavigationLink(destination: destination) {
                Text("None")
            }
            .accessibilityIdentifier("before-reading-row")
        }
    }
}
