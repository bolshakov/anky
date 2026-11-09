// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

/// An entry drawn as the shared row: its kind, then its time and places, with its level at the trailing edge. The
/// caller's wrapper gives the row its tap target, its identifier and its accessibility label.
struct EntryIconRow: View {
    let entry: Entry

    var body: some View {
        IconRow(
            symbol: RowSymbol.name(for: entry.kind),
            title: Text(entry.kind.displayName),
            time: Self.time(of: entry),
            detail: entry.kind.asksWhere ? entry.placeSummary.text : nil
        ) {
            Text(entry.severity.value, format: .number)
                .font(.body)
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
    }

    static func time(of entry: Entry) -> String {
        ClockText.text(for: entry.date, calendar: .current, locale: .current)
    }

    /// Fatigue has no places, so it names none.
    static func spokenPlaces(of entry: Entry) -> String? {
        entry.kind.asksWhere ? RecentEntry(entry).spokenPlaces : nil
    }

    static func spokenLevel(of entry: Entry) -> String {
        String(localized: entry.severity.spokenValue)
    }

    static func spokenKind(of entry: Entry) -> String {
        String(localized: entry.kind.displayName)
    }

    static func readingLabel(for entry: Entry) -> String {
        EntryRowText.readingLabel(
            time: time(of: entry),
            kind: spokenKind(of: entry),
            places: spokenPlaces(of: entry),
            severity: spokenLevel(of: entry)
        )
    }

    static func readingOptionValue(for entry: Entry) -> String {
        EntryRowText.readingOptionValue(
            time: time(of: entry),
            places: spokenPlaces(of: entry),
            severity: spokenLevel(of: entry)
        )
    }
}

extension EntryIconRow {
    /// One element that speaks the reading, for a control that opens the reading.
    func spokenAsReading() -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Self.readingLabel(for: entry))
    }
}
