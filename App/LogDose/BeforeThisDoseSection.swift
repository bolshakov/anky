// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

/// The reading before a dose, or the row that logs one when there is none. The title is the same in both states.
struct BeforeThisDoseSection: View {
    let reading: () -> Entry?
    let onChoose: () -> Void
    let onLog: () -> Void

    var body: some View {
        let entry = reading()
        CardSection(
            Text("Before this dose"),
            footnote: entry.map { _ in Text("Your latest entry before this dose. Tap to choose another.") },
            id: "before-reading"
        ) {
            row(entry)
        }
    }

    @ViewBuilder
    private func row(_ entry: Entry?) -> some View {
        if let entry {
            Button(action: onChoose) {
                HStack(spacing: Spacing.rowContentGap) {
                    EntryIconRow(entry: entry)
                        .spokenAsReading()
                    chevron
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("before-reading-row")
        } else {
            Button(action: onLog) {
                HStack(spacing: Spacing.rowContentGap) {
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
