// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

/// One reading as a dose shows it. The caller puts it in the control that opens the choice, and that control gives
/// the row its tap target and its identifier.
struct ReadingRow: View {
    let caption: String?
    let entry: Entry

    private var time: String {
        ClockText.text(for: entry.date, calendar: .current, locale: .current)
    }

    private var kind: String {
        String(localized: entry.kind.displayName)
    }

    private var level: String {
        String(localized: entry.severity.spokenValue)
    }

    /// Fatigue has no places, so its row names none.
    private var places: String? {
        guard entry.kind.asksWhere else { return nil }
        return RecentEntry(entry).spokenPlaces
    }

    private var spokenText: String {
        [caption, time, kind, places, level].compactMap(\.self).joined(separator: ", ")
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                if let caption {
                    Text(caption)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Text(kind)
                    .font(.body)
                Text([places, level].compactMap(\.self).joined(separator: " · "))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(time)
                .font(.footnote)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .fixedSize()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenText)
    }
}
