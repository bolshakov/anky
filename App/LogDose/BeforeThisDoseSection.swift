// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

/// The reading before a dose, or the row that logs one when there is none. The title is the same in both states.
struct BeforeThisDoseSection: View {
    let reading: () -> Entry?
    let onChoose: () -> Void
    let onLog: () -> Void

    var body: some View {
        Section {
            TimelineView(.everyMinute) { _ in
                row(reading())
            }
        } header: {
            Text("Before this dose")
                .cardCaption()
        } footer: {
            if reading() != nil {
                Text("Your latest entry before this dose. Tap to choose another.")
                    .accessibilityIdentifier("before-reading-footer")
            }
        }
    }

    @ViewBuilder
    private func row(_ entry: Entry?) -> some View {
        if let entry {
            Button(action: onChoose) {
                HStack(spacing: 12) {
                    ReadingRow(caption: nil, entry: entry)
                    chevron
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("before-reading-row")
        } else {
            Button(action: onLog) {
                HStack(spacing: 12) {
                    Text("Log how you feel now")
                        .foregroundStyle(.tint)
                    Spacer()
                    chevron
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("log-how-you-feel-row")
        }
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.tertiary)
            .accessibilityHidden(true)
    }
}
